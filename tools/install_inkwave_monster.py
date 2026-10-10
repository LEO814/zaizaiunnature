#!/usr/bin/env python3
"""Incrementally attach the imported INKWAVE GLB to the saved native Demo.

This tool never imports/uploads a GLB and never rebuilds the seed scene. Import
the GLB in the editor and save first. --apply requires --editor-closed as the
operator's explicit assertion that this project is closed. Default: dry-run.
"""
from __future__ import annotations

import argparse
import copy
from datetime import datetime
import hashlib
import io
import json
import math
import os
from pathlib import Path
import re
import shutil
import sys
import tempfile
import time
from urllib.parse import unquote, urlsplit
import zipfile
from zoneinfo import ZoneInfo

import install_editor_demo as demo

REPORT_PATH='docs/inkwave_editor_install.json'
MONSTER_NODE_NAME='monster_inkwave_actor'

def sha(data):return hashlib.sha256(data).hexdigest()

def unique(nodes,name):
    result=[n for n in nodes if n.get('nodeName')==name]
    if len(result)!=1:raise ValueError(f'requires one {name} node; found {len(result)}')
    return result[0]

def is_candidate(node):
    asset=node.get('assetData')or{}
    model=node.get('aigcModelData')or{}
    text=unquote(str(node.get('nodeName',''))+' '+str(asset.get('uri',''))+' '+str(model.get('uri','')))
    return ('墨潮巡猎者' in text or 'monster_inkwave' in text.lower()) and bool(model)

def validate_resource(node):
    asset=node.get('assetData')or{};model=node.get('aigcModelData')or{}
    uri=asset.get('uri');asset_id=asset.get('assetID')
    if not isinstance(uri,str)or not uri or uri!=model.get('uri'):
        raise ValueError('imported GLB requires nonempty identical assetData.uri and aigcModelData.uri')
    decoded=unquote(uri);parsed=urlsplit(decoded)
    if not parsed.path.lower().endswith('.glb'):
        raise ValueError('imported asset URI must identify a GLB')
    if not (uri.startswith('hamlet-ugc/')or parsed.scheme=='https'):
        raise ValueError('GLB URI must come from the real editor upload, not a local file or invented prefab')
    if not re.fullmatch(r'[1-9]\d*',str(asset_id or''))or int(asset_id)<1000:
        raise ValueError('imported GLB requires a real positive editor assetID; primitive IDs are rejected')
    return uri,str(asset_id)

def verified_canonical_profile(root,wrapper):
    """Recover only Inspector data from the last byte-verified applied scene.

    The native saved scene remains authoritative for node IDs and uploaded assets.
    This fallback is needed when an editor asset replacement drops Lua bindings.
    """
    content=(root/'scene.data').read_bytes()
    previous=json.loads((root/REPORT_PATH).read_text())
    if (previous.get('ok')is not True or previous.get('mode')!='applied'
        or previous.get('projectName')!=demo.PROJECT_NAME
        or previous.get('monsterNodeName')!=MONSTER_NODE_NAME
        or previous.get('sourceNativeFilesIdentical')is not True
        or previous.get('sceneSha256')!=sha(content)):
        raise ValueError('canonical profile fallback requires the last applied byte-verified scene/report')
    with zipfile.ZipFile(io.BytesIO(content))as archive:
        if archive.namelist().count(demo.NATIVE_JSON)!=1:raise ValueError('canonical fallback ZIP has an ambiguous scene')
        canonical=json.loads(archive.read(demo.NATIVE_JSON))
    actor=unique(canonical['nodeTransformDatas'],MONSTER_NODE_NAME)
    canonical_root=unique(canonical['nodeTransformDatas'],'demo_root')
    if actor['id']!=previous.get('importedNodeId')or actor.get('parentId')!=canonical_root['id']:
        raise ValueError('canonical profile actor identity differs from the verified install report')
    uri,asset_id=validate_resource(actor)
    if uri!=previous.get('resourceUri')or asset_id!=previous.get('assetID'):
        raise ValueError('canonical profile actor resource differs from the verified install report')
    attribute_id=demo.SCRIPTS['monster_attributes']
    bindings=[b for b in actor.get('runtimeScriptBindings')or[] if b.get('scriptId')==attribute_id]
    if len(bindings)!=1 or bindings[0].get('scriptType')!=1:
        raise ValueError('canonical fallback requires one existing monster_attributes binding')
    binding=bindings[0]
    if binding not in (previous.get('migratedAttributeBindings')or[]):
        raise ValueError('canonical profile binding differs from the verified install report')
    script=canonical.get('runtimeScripts',{}).get(attribute_id,{})
    if not isinstance(script,dict)or not re.search(r'^---@id\s+'+re.escape(attribute_id)+r'\s*$',script.get('content',''),re.M):
        raise ValueError('canonical profile script UUID is not verified')
    fields={}
    for block in re.finditer(r'^---@var\s+(\w+):number=[^\n]+\n(.*?)(?=^---@var|^---@end)',wrapper,re.M|re.S):
        limits=re.search(r'^---@range\s+([^,\n]+),([^,\n]+),[^\n]+$',block.group(2),re.M)
        if not limits:raise ValueError('current monster_attributes field lacks a numeric range')
        fields[block.group(1)]=(float(limits.group(1)),float(limits.group(2)))
    parameters=json.loads(binding.get('paramsJson',''))
    if len(fields)!=21 or not isinstance(parameters,dict)or set(parameters)!=set(fields):
        raise ValueError('canonical profile must contain exactly the current 21 Inspector parameters')
    for name,(minimum,maximum)in fields.items():
        value=parameters[name]
        if isinstance(value,bool)or not isinstance(value,(int,float))or not math.isfinite(value)or not minimum<=value<=maximum:
            raise ValueError('canonical profile has an invalid Inspector value: '+name)
    return copy.deepcopy(binding),{'attributeBindingSource':'verified_canonical_actor',
        'canonicalProfileSceneSha256':sha(content),'canonicalProfileNodeId':actor['id'],
        'canonicalProfileParameterCount':len(parameters)}

def prepare_scene(original,wrappers,canonical_root=None):
    scene=copy.deepcopy(original);nodes=scene['nodeTransformDatas']
    if not isinstance(nodes,list)or not isinstance(scene.get('runtimeScripts'),dict):
        raise ValueError('unsupported saved scene schema')
    candidates=[node for node in nodes if is_candidate(node)]
    if len(candidates)!=1:
        raise ValueError('requires exactly one saved imported 墨潮巡猎者/monster_inkwave GLB; found '+str(len(candidates)))
    glb=candidates[0];imported_original_name=glb.get('nodeName');uri,asset_id=validate_resource(glb)
    root=unique(nodes,'demo_root');cube=unique(nodes,'monster_cube')
    if glb['id'] in (root['id'],cube['id']):raise ValueError('imported node is not distinct from native Demo nodes')
    if any(n.get('nodeName')==MONSTER_NODE_NAME and n['id']!=glb['id']for n in nodes):
        raise ValueError('another authoring node already uses '+MONSTER_NODE_NAME)
    attribute_id=demo.SCRIPTS['monster_attributes']
    bindings=copy.deepcopy(cube.get('runtimeScriptBindings')or[])
    binding_source={'attributeBindingSource':'native_cube'}
    if not any(b.get('scriptId')==attribute_id for b in bindings):
        # Re-running the installer after an initial migration keeps the migrated Inspector values.
        bindings=[copy.deepcopy(b)for b in glb.get('runtimeScriptBindings')or[] if b.get('scriptId')==attribute_id]
        binding_source={'attributeBindingSource':'native_actor'}
    if not any(b.get('scriptId')==attribute_id for b in bindings):
        if canonical_root is None:raise ValueError('source monster has no verified monster_attributes binding')
        binding,binding_source=verified_canonical_profile(canonical_root,wrappers['monster_attributes'])
        bindings=[binding]
    retained=[copy.deepcopy(b)for b in glb.get('runtimeScriptBindings')or[] if b.get('scriptId')not in {b.get('scriptId')for b in bindings}]
    # Keep the authoring/Inspector root distinct from the GLB's internal source root.
    glb.update(nodeName=MONSTER_NODE_NAME,parentId=root['id'],pos={'x':8,'y':.05,'z':8},
               rot={'x':0,'y':0,'z':0,'w':1},scale={'x':1,'y':1,'z':1},isActive=True,isStatic=False,
               runtimeScriptBindings=retained+bindings)
    cube['isActive']=False;cube['runtimeScriptBindings']=[]
    if validate_resource(glb)!=(uri,asset_id):raise ValueError('native imported GLB resource changed during profile migration')
    scripts=scene['runtimeScripts']
    for name,script_id in demo.SCRIPTS.items():
        if script_id not in scripts or not isinstance(scripts[script_id],dict)or'content'not in scripts[script_id]:
            raise ValueError('saved scene lacks expected runtime script schema: '+script_id)
        scripts[script_id]['content']=wrappers[name]
    # All structural changes are limited to these two nodes and the four existing script contents.
    changed_ids={glb['id'],cube['id']}
    for before,after in zip(original['nodeTransformDatas'],nodes):
        if before['id']!=after['id']:raise ValueError('node ordering/identity changed')
        if before['id']not in changed_ids and before!=after:raise ValueError('unrelated node modified')
    if len(nodes)!=len(original['nodeTransformDatas']):raise ValueError('node count changed')
    for key,value in original.items():
        if key not in ('nodeTransformDatas','runtimeScripts')and scene[key]!=value:
            raise ValueError('unrelated top-level scene field changed: '+key)
    for script_id,before in original['runtimeScripts'].items():
        after=scripts[script_id]
        expected=copy.deepcopy(before)
        if script_id in demo.SCRIPTS.values():expected['content']=after['content']
        if expected!=after:raise ValueError('runtime script schema/official script changed: '+script_id)
    return scene,{'importedNodeId':glb['id'],'importedOriginalName':imported_original_name,
                  'assetID':asset_id,'resourceUri':uri,'monsterNodeName':MONSTER_NODE_NAME,'disabledCubeNodeId':cube['id'],
                  'monsterPosition':glb['pos'],'migratedAttributeBindings':bindings,'retainedGlbBindings':retained,
                  **binding_source,'nativeImportedAssetPreserved':True}

def repack(original_bytes,scene):
    output=io.BytesIO()
    with zipfile.ZipFile(io.BytesIO(original_bytes))as source,zipfile.ZipFile(output,'w')as target:
        if source.namelist().count(demo.NATIVE_JSON)!=1:raise ValueError('saved ZIP requires one SerializePcgData.json')
        target.comment=source.comment
        for info in source.infolist():
            data=json.dumps(scene,ensure_ascii=False,separators=(',',':')).encode()if info.filename==demo.NATIVE_JSON else source.read(info.filename)
            target.writestr(copy.copy(info),data)
    content=output.getvalue()
    with zipfile.ZipFile(io.BytesIO(original_bytes))as source,zipfile.ZipFile(io.BytesIO(content))as check:
        if source.namelist()!=check.namelist()or source.comment!=check.comment:raise ValueError('ZIP metadata/member list changed')
        for name in source.namelist():
            if name!=demo.NATIVE_JSON and source.read(name)!=check.read(name):raise ValueError('unrelated ZIP asset changed: '+name)
        if json.loads(check.read(demo.NATIVE_JSON))!=scene:raise ValueError('scene ZIP readback mismatch')
    return content

def atomic_write(path,data):
    path.parent.mkdir(parents=True,exist_ok=True)
    fd,temp=tempfile.mkstemp(prefix='.'+path.name+'.',dir=path.parent)
    try:
        with os.fdopen(fd,'wb')as f:f.write(data)
        os.replace(temp,path)
    finally:
        if os.path.exists(temp):os.unlink(temp)

def sync_apply(root,target,scene_bytes,report,files,directories,native_before):
    managed=tuple(demo.MANAGED)+tuple(n for n in ('.gitattributes',)if (root/n).is_file())
    extra_files={name:(root/name).read_bytes()for name in managed if name not in demo.MANAGED}
    files={**files,**extra_files}
    original_inventory={path:sha(data)for path,data in files.items()}
    report.update(mode='applied',backup=str(target/'.demo_install_backups'/('inkwave-'+datetime.now(ZoneInfo('Asia/Shanghai')).strftime('%Y%m%d-%H%M%S')+'-'+str(time.time_ns()))),
                  sourceNativeFilesIdentical=True,sourceNativeDirectoriesIdentical=True,protectedConfigurationUnchanged=True)
    report['canonicalFileCount']=len(files)+(0 if REPORT_PATH in files else 1)
    report_bytes=(json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode()
    files[REPORT_PATH]=report_bytes
    protected={name:(target/name).read_bytes()for name in ('project.json','world-config.json')}
    canonical_before={name:(root/name).read_bytes()if (root/name).exists()else None for name in ('scene.data',REPORT_PATH)}
    backup=Path(report['backup']);replaced=[];canonical_written=False
    with tempfile.TemporaryDirectory(prefix='.inkwave_stage_',dir=target)as stage_name:
        stage=Path(stage_name)
        for directory in directories:(stage/directory).mkdir(parents=True,exist_ok=True)
        for name,data in files.items():
            p=stage/name;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(data)
        (stage/'scene.data').write_bytes(scene_bytes)
        current_files,current_dirs=demo.source_inventory(root)
        current_files.update({name:(root/name).read_bytes()for name in extra_files})
        if {name:sha(data)for name,data in current_files.items()}!=original_inventory or current_dirs!=directories:
            raise ValueError('canonical source changed during staging; rebuild and retry')
        if (target/'scene.data').read_bytes()!=native_before:raise ValueError('native saved scene changed during staging; close project and retry')
        if report.get('attributeBindingSource')=='verified_canonical_actor'and sha((root/'scene.data').read_bytes())!=report['canonicalProfileSceneSha256']:
            raise ValueError('verified canonical profile scene changed during staging; retry')
        backup.mkdir(parents=True)
        try:
            for name in (*managed,'scene.data'):
                dest=target/name;saved=backup/name;existed=dest.exists()
                if existed:os.replace(dest,saved)
                replaced.append((dest,saved,existed));os.replace(stage/name,dest)
            canonical_written=True
            atomic_write(root/'scene.data',scene_bytes);atomic_write(root/REPORT_PATH,report_bytes)
            source_files,source_dirs=demo.source_inventory(root);native_files,native_dirs=demo.source_inventory(target)
            if source_dirs!=native_dirs or {n:sha(b)for n,b in source_files.items()}!={n:sha(b)for n,b in native_files.items()}:
                raise ValueError('canonical and native managed directories/files differ after sync')
            for name in extra_files:
                if (root/name).read_bytes()!=(target/name).read_bytes():raise ValueError('root Git metadata sync mismatch: '+name)
            if (root/'scene.data').read_bytes()!=(target/'scene.data').read_bytes():raise ValueError('canonical/native scene bytes differ')
            for name,data in protected.items():
                if (target/name).read_bytes()!=data:raise ValueError('native protected configuration changed: '+name)
        except BaseException:
            if canonical_written:
                for name,data in canonical_before.items():
                    if data is None:(root/name).unlink(missing_ok=True)
                    else:atomic_write(root/name,data)
            for dest,saved,existed in reversed(replaced):
                if dest.is_dir():shutil.rmtree(dest)
                elif dest.exists():dest.unlink()
                if existed and saved.exists():os.replace(saved,dest)
            raise
    return report

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--native-project',type=Path,default=demo.DEFAULT_EDITOR_PROJECT)
    modes=parser.add_mutually_exclusive_group();modes.add_argument('--dry-run',action='store_true');modes.add_argument('--apply',action='store_true')
    parser.add_argument('--editor-closed',action='store_true',help='explicitly assert target project is closed before --apply')
    args=parser.parse_args();root=Path(__file__).resolve().parents[1];target=args.native_project.resolve()
    try:
        if args.apply and not args.editor_closed:raise ValueError('--apply requires --editor-closed; close the target project first')
        if root==target or root in target.parents or target in root.parents:raise ValueError('canonical/native project roots must be separate')
        if json.loads((target/'project.json').read_text()).get('name')!=demo.PROJECT_NAME:raise ValueError('wrong native project')
        native_bytes=(target/'scene.data').read_bytes()
        with zipfile.ZipFile(io.BytesIO(native_bytes))as archive:original=json.loads(archive.read(demo.NATIVE_JSON))
        wrappers=demo.wrapper_sources(root)
        scene,details=prepare_scene(original,wrappers,root)
        content=repack(native_bytes,scene);files,directories=demo.source_inventory(root)
        report={'ok':True,'mode':'dry-run','generatedAt':datetime.now(ZoneInfo('Asia/Shanghai')).isoformat(),
                'projectName':demo.PROJECT_NAME,'sourceRoot':str(root),'nativeProject':str(target),**details,
                'nativeBeforeSha256':sha(native_bytes),'sceneSha256':sha(content),'nativeNodeCount':len(scene['nodeTransformDatas']),
                'resourceRefsPreserved':True,'unrelatedNodesPreserved':True,'officialRuntimeScriptsPreserved':True,
                'updatedRuntimeScriptIds':list(demo.SCRIPTS.values()),'sceneRebuiltFromSeed':False,
                'editorClosedOperatorAssertion':bool(args.editor_closed),'canonicalFileCount':len(files),
                'nativeProjectWritten':bool(args.apply),'previewAcceptance':'not performed by filesystem installer'}
        if args.apply:report=sync_apply(root,target,content,report,files,directories,native_bytes)
        print(json.dumps(report,ensure_ascii=False,indent=2));return 0
    except (OSError,ValueError,KeyError,IndexError,TypeError,zipfile.BadZipFile)as exc:
        print(json.dumps({'ok':False,'mode':'apply'if args.apply else'dry-run','error':str(exc)},ensure_ascii=False),file=sys.stderr);return 1

if __name__=='__main__':raise SystemExit(main())
