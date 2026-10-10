"""Independently re-import the shipped GLB; never overwrite its editable source blend."""
import bpy,json,struct,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]/'gameplay/packages/monsters/monster_inkwave'
raw=(ROOT/'model/main.glb').read_bytes();jlen,_=struct.unpack_from('<II',raw,12);g=json.loads(raw[20:20+jlen]);names={n.get('name') for n in g['nodes']}
bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.scene.render.fps=30
bpy.ops.import_scene.gltf(filepath=str(ROOT/'model/main.glb'),merge_vertices=True)
objects=[o for o in bpy.data.objects if o.name in names]
arm=[o for o in objects if o.type=='ARMATURE'];mesh=[o for o in objects if o.type=='MESH']
clips={a.name for a in bpy.data.actions}
assert len(arm)==1 and len(arm[0].data.bones)==87
assert len(mesh)==12
assert sum(any(m.type=='ARMATURE' for m in o.modifiers) for o in mesh)==4
assert clips=={'idle','patrol','chase','attack','hit','death'}
assert [a['name'] for a in g['animations']]==['idle','patrol','chase','attack','hit','death']
assert any(o.name=='muzzle' for o in objects)
assert not any('Preview' in n or n=='Icosphere' for n in names)
report={'blender':bpy.app.version_string,'glbSHA256':hashlib.sha256(raw).hexdigest(),'glbBytes':len(raw),'importSuccess':True,'rigBones':87,'runtimeMeshObjects':len(mesh),'skinnedMeshObjects':4,'clipNames':sorted(clips),'animationOrder':[a['name'] for a in g['animations']],'defaultClip':'idle','muzzlePresent':True,'noPreviewObjectsInGLB':True,'actions':[{'name':a.name,'frameRange':list(a.frame_range)} for a in bpy.data.actions]}
(ROOT/'model/final_import_audit.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
