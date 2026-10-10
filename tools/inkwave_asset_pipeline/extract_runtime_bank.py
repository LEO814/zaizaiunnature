"""Extract the native-editor TRS bank from the actual final Blender-exported GLB."""
from pathlib import Path
import json,struct,hashlib,math
ROOT=Path(__file__).resolve().parents[2]/'gameplay/packages/monsters/monster_inkwave'
raw=(ROOT/'model/main.glb').read_bytes();jlen,_=struct.unpack_from('<II',raw,12);g=json.loads(raw[20:20+jlen]);binstart=28+jlen;binary=raw[binstart:]
def accessor(idx):
 a=g['accessors'][idx];v=g['bufferViews'][a['bufferView']];types={5126:('f',4),5125:('I',4),5123:('H',2),5121:('B',1),5122:('h',2),5120:('b',1)};kind,size=types[a['componentType']];dims={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']];off=v.get('byteOffset',0)+a.get('byteOffset',0);stride=v.get('byteStride',dims*size);values=[]
 for row in range(a['count']):values.extend(struct.unpack_from('<'+kind*dims,binary,off+row*stride))
 assert all(math.isfinite(x) for x in values)
 return [round(x,6) if isinstance(x,float) else x for x in values]
required={ch['target']['node'] for a in g['animations'] for ch in a['channels']}
required.update(joint for skin in g.get('skins',[]) for joint in skin['joints'])
nodes=[]
for i,n in enumerate(g['nodes']):
 assert 'matrix' not in n,'Unexpected matrix-only node needs decomposition'
 nodes.append({'name':n['name'],'position':n.get('translation',[0,0,0]),'rotation':n.get('rotation',[0,0,0,1]),'scale':n.get('scale',[1,1,1]),'required':i in required})
clips=[]
for anim in g['animations']:
 tracks=[]
 for channel in anim['channels']:
  sampler=anim['samplers'][channel['sampler']];path=channel['target']['path'];assert path in ('translation','rotation','scale');interpolation=sampler.get('interpolation','LINEAR');assert interpolation in ('LINEAR','STEP')
  tracks.append({'node':channel['target']['node']+1,'path':path,'dimensions':4 if path=='rotation' else 3,'times':accessor(sampler['input']),'values':accessor(sampler['output']),'interpolation':interpolation})
 clips.append({'name':anim['name'],'duration':max(max(t['times']) for t in tracks),'tracks':tracks})
assert [c['name'] for c in clips]==['idle','patrol','chase','attack','hit','death'], 'Run normalize_clip_times.py before bank extraction'
bank={'version':1,'fps':30,'rootMotion':'in_place','nodes':nodes,'clips':clips}
(ROOT/'animations/runtime_bank.json').write_text(json.dumps(bank,separators=(',',':'))+'\n')
def lua(value):
 if isinstance(value,str):return json.dumps(value,ensure_ascii=False)
 if value is None:return 'nil'
 if isinstance(value,bool):return 'true' if value else 'false'
 if isinstance(value,(int,float)):return str(value)
 if isinstance(value,list):return '{'+','.join(lua(x) for x in value)+'}'
 return '{'+','.join('['+lua(k)+']='+lua(v) for k,v in value.items())+'}'
(ROOT/'animations/runtime_bank.lua').write_text('-- Generated from the FINAL Blender-exported GLB. MIT Jayden Davis. Do not hand edit.\nreturn '+lua(bank)+'\n')
clipmeta=[{'name':c['name'],'duration':c['duration'],'tracks':len(c['tracks']),'loop':c['name'] in ('idle','patrol','chase'),'fps':30} for c in clips]
(ROOT/'animations/clips.json').write_text(json.dumps({'fps':30,'rootMotion':False,'clips':clipmeta,'events':{'attack':[{'time':.55,'event':'muzzle_shot'}],'hit':[{'time':0,'event':'hurt'}],'death':[{'time':0,'event':'death'}]}},indent=2)+'\n')
audit=json.loads((ROOT/'model/asset_audit.json').read_text());simplify=json.loads((ROOT/'model/blender_audit.json').read_text())
triangles=sum(g['accessors'][p.get('indices',p['attributes']['POSITION'])]['count']//3 for m in g['meshes'] for p in m['primitives'])
audit.update({'glbBytes':len(raw),'trianglesBefore':simplify['trianglesBefore'],'triangles':triangles,'trianglesReductionPercent':round(100*(1-triangles/simplify['trianglesBefore']),2),'blenderSimplification':True,'rigBones':len(g['skins'][0]['joints']),'gltfSkinCount':len(g['skins']),'meshesAfter':len(g['meshes']),'animations':clipmeta,'defaultClip':'idle','animationOrder':[c['name'] for c in clips],'editorUploadLimitBytes':10*1024*1024,'editorUploadBudgetPass':len(raw)<9.5*1024*1024})
(ROOT/'model/asset_audit.json').write_text(json.dumps(audit,indent=2,ensure_ascii=False)+'\n');simplify['trianglesAfterGLB']=triangles;(ROOT/'model/blender_audit.json').write_text(json.dumps(simplify,indent=2)+'\n')
print(json.dumps({'bytes':len(raw),'triangles':triangles,'nodes':len(nodes),'skins':len(g['skins']),'clips':[(c['name'],c['duration']) for c in clips]}))
