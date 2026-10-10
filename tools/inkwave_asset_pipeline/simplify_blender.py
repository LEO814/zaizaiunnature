"""Real Blender mesh simplification and GLB export for the editor's 10 MiB upload ceiling."""
import bpy,json,os,math,struct
from pathlib import Path
from mathutils import Vector
HERE=Path(__file__).resolve().parent
PROJECT=HERE.parents[1]
OUT=PROJECT/'gameplay/packages/monsters/monster_inkwave'
BUILD=HERE/'build';BUILD.mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene=bpy.context.scene;scene.render.fps=30
bpy.ops.import_scene.gltf(filepath=str(OUT/'model/high_detail.glb'),merge_vertices=True)
raw=(OUT/'model/high_detail.glb').read_bytes();jlen,_=struct.unpack_from('<II',raw,12);sourceGltf=json.loads(raw[20:20+jlen]);sourceNames={n.get('name') for n in sourceGltf['nodes']}
runtime=[o for o in scene.objects if o.name in sourceNames]
for o in list(scene.objects):
 if o.name not in sourceNames:bpy.data.objects.remove(o,do_unlink=True)
meshes=[o for o in runtime if o.type=='MESH'];arms=[o for o in runtime if o.type=='ARMATURE']
original={o.name:len(o.data.polygons) for o in meshes}
reference=bpy.data.collections.new('HIGH_DETAIL_REFERENCE');scene.collection.children.link(reference);reference.hide_render=True;reference.hide_viewport=True
for o in meshes:
 ref=o.copy();ref.data=o.data.copy();ref.name=o.name+'_HIGH';reference.objects.link(ref);ref.hide_render=True
for o in meshes:
 ratio=1.0 if o.name in ['iw_skin','iw_eyes'] else .58 if o.name=='iw_cloth' else .65 if o.name=='iw_hair' else .72 if original[o.name]>1000 else .85
 if ratio<1:
  m=o.modifiers.new('Editor_budget_Decimate','DECIMATE');m.decimate_type='COLLAPSE';m.ratio=ratio;m.use_collapse_triangulate=True;m.delimit=set()
texAudit=[]
baseImages=set()
for mat in bpy.data.materials:
 if mat.use_nodes:
  for n in mat.node_tree.nodes:
   if n.type=='TEX_IMAGE' and n.image:
    if any(link.to_socket.name=='Base Color' for link in n.outputs['Color'].links):baseImages.add(n.image.name)
for image in bpy.data.images:
 if image.name=='Render Result':continue
 try:image.pixels[0]
 except (IndexError,RuntimeError):continue
 before=list(image.size);base=image.name in baseImages;
 if image.packed_file:image.unpack(method='REMOVE')
 limit=1024 if base else 512 if max(before)>1024 else 256
 if max(before)>limit:
  scale=limit/max(before);image.scale(max(1,round(before[0]*scale)),max(1,round(before[1]*scale)))
 target=BUILD/(image.name.replace('/','_')+'.png');image.filepath_raw=str(target);image.file_format='PNG';image.save();image.pack()
 texAudit.append({'name':image.name,'before':before,'after':list(image.size)})
# Export only the runtime character. Original references and preview setup never enter main.glb.
bpy.ops.object.select_all(action='DESELECT')
for o in runtime:o.select_set(True)
scene.frame_set(0)
bpy.ops.export_scene.gltf(filepath=str(OUT/'model/main.glb'),export_format='GLB',use_selection=True,export_apply=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_nla_strips=True,export_frame_range=False,export_frame_step=1,export_optimize_animation_size=True,export_materials='EXPORT',export_image_format='AUTO',export_yup=True)
depsgraph=bpy.context.evaluated_depsgraph_get()
counts={o.name:sum(max(1,len(p.vertices)-2) for p in o.evaluated_get(depsgraph).data.polygons) for o in meshes}
# Make the blend immediately useful for inspection: one idle track active, 87-bone rig, unapplied simplification modifiers.
for o in runtime:
 if o.animation_data:
  for t in o.animation_data.nla_tracks:t.mute=t.name!='idle'
scene.frame_set(1)
for arm in arms:arm.show_in_front=True
scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.use_denoising=True
scene.render.resolution_x=1000;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Studio');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.06,.08,.12,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.5
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.03));floor=bpy.context.object;floor.name='Preview_floor';mat=bpy.data.materials.new('Preview_floor_material');mat.diffuse_color=(.06,.07,.1,1);floor.data.materials.append(mat)
def area(name,loc,energy,size):
 bpy.ops.object.light_add(type='AREA',location=loc);o=bpy.context.object;o.name=name;o.data.energy=energy;o.data.shape='DISK';o.data.size=size;o.rotation_euler=(Vector((0,0,.8))-o.location).to_track_quat('-Z','Y').to_euler()
area('Key',(3,-4,5),550,4);area('Fill',(-3,-2,2.7),270,3);area('Rim',(1,3,3.5),700,3)
bpy.ops.object.camera_add(location=(2.6,-4.8,2.1));cam=bpy.context.object;cam.name='Preview_camera';cam.rotation_euler=(Vector((0,0,.72))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.type='ORTHO';cam.data.ortho_scale=2.0;scene.camera=cam
scene.view_settings.view_transform='AgX';scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'model/preview.png')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'model/source.blend'));bpy.ops.render.render(write_still=True)
scene.render.resolution_x=scene.render.resolution_y=720
for clip,time in [('patrol',.4),('chase',.3),('attack',.65),('hit',.12),('death',1.1)]:
 for o in runtime:
  if o.animation_data:
   for t in o.animation_data.nla_tracks:t.mute=t.name!=clip
 scene.frame_set(round(time*30));scene.render.filepath=str(OUT/'animations'/f'{clip}_preview.png');bpy.ops.render.render(write_still=True)
report={'blender':bpy.app.version_string,'workflow':'Blender import with merged vertices, unapplied Decimate modifiers, skin/eye silhouette retained, actual evaluated-mesh GLB export','trianglesBefore':sum(sourceGltf['accessors'][p.get('indices',p['attributes']['POSITION'])]['count']//3 for m in sourceGltf['meshes'] for p in m['primitives']),'trianglesAfter':sum(counts.values()),'meshTrianglesBefore':original,'meshTrianglesAfter':counts,'rigBones':[(o.name,len(o.data.bones)) for o in arms],'clips':[(a.name,list(a.frame_range)) for a in bpy.data.actions],'textureResize':texAudit,'glbBytes':(OUT/'model/main.glb').stat().st_size,'highDetailBytes':(OUT/'model/high_detail.glb').stat().st_size,'budgetBytes':int(9.5*1024*1024)}
(OUT/'model/blender_audit.json').write_text(json.dumps(report,indent=2)+'\n')
print('SIMPLIFICATION',json.dumps({k:report[k] for k in ['trianglesBefore','trianglesAfter','glbBytes','highDetailBytes','rigBones']},indent=2))
assert report['glbBytes']<report['budgetBytes'], 'GLB still exceeds editor budget'
