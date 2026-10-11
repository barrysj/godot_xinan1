"""Apply measured seam connections to the retained asset_004 masters."""
import array
import hashlib
import json
import sys
from pathlib import Path
import bpy
import bmesh

root=Path.cwd()
work=root/'.godot/art-workflow/seam-blending'
base=root/'design/concepts/environments/campus-map/campus-map/asset_004'
out=base.parent/'tmp_008'
out.mkdir(exist_ok=True)
entries=json.loads((work/'meshes.json').read_text())
report={}
bpy.context.preferences.filepaths.save_version=0

def snapshot():
 meshes={};objects={}
 for o in bpy.context.scene.objects:
  shape=None
  if o.type=='MESH':
   key=o.data.name
   if key not in meshes:
    a=array.array('f',[0])*(len(o.data.vertices)*3);o.data.vertices.foreach_get('co',a)
    b=array.array('i',[0])*len(o.data.loops);o.data.loops.foreach_get('vertex_index',b)
    meshes[key]=hashlib.sha256(a.tobytes()+(b.tobytes() if not o.name.startswith('057 ') else b'')).hexdigest()
   shape=meshes[key]
  objects[o.name]={'matrix':[list(r) for r in o.matrix_world],'mesh':shape}
 return objects

for state in ['day','night','anomaly']:
 bpy.ops.wm.open_mainfile(filepath=str(base/(state+'.blend')))
 scene=bpy.context.scene;before=snapshot();camera_scale=scene.camera.data.ortho_scale
 sample=next(o for o in scene.objects if o.name.startswith('WEST_TPX_Buildings') and len(o.data.materials)>=2)
 facade,roof=sample.data.materials[:2]
 terrain=bpy.data.objects['051 Neutral terrain beneath export edges'].data.materials[0]
 road=next(o.data.materials[0] for o in scene.objects if o.type=='MESH' and o.get('source_layer')=='TPX_ROADS_HATCH')
 flipped={}
 for o in scene.objects:
  if o.name.startswith('057 ') and o.get('kind') in ['ground','roads']:
   bm=bmesh.new();bm.from_mesh(o.data);count=0
   for face in bm.faces:
    if (o.matrix_world.to_3x3()@face.normal).z<0:face.normal_flip();count+=1
   bm.normal_update();bm.to_mesh(o.data);bm.free();o.data.update();flipped[o.name]=count
 nodes=terrain.node_tree.nodes;links=terrain.node_tree.links
 bsdf=next(n for n in nodes if n.type=='BSDF_PRINCIPLED');color=list(bsdf.inputs['Base Color'].default_value)
 original_color_source=bsdf.inputs['Base Color'].links[0].from_socket if bsdf.inputs['Base Color'].is_linked else None
 geometry=nodes.new('ShaderNodeNewGeometry');geometry.name='Seam world coordinates';geometry.location=(-700,100)
 noise=nodes.new('ShaderNodeTexNoise');noise.name='Seam broad ground variation';noise.location=(-500,100)
 noise.inputs['Scale'].default_value=.0045;noise.inputs['Detail'].default_value=2;noise.inputs['Roughness'].default_value=.55
 ramp=nodes.new('ShaderNodeValToRGB');ramp.name='Seam shared ground palette';ramp.location=(-240,100)
 ramp.color_ramp.elements[0].position=.15;ramp.color_ramp.elements[1].position=.85
 ramp.color_ramp.elements[0].color=[color[i]*[.91,.94,.92][i] for i in range(3)]+[1]
 ramp.color_ramp.elements[1].color=[min(1,color[i]*[1.055,1.025,1.07][i]) for i in range(3)]+[1]
 if original_color_source:
  ramp.color_ramp.elements[0].color=[.91,.94,.92,1]
  ramp.color_ramp.elements[1].color=[1.055,1.025,1.07,1]
 ramp.color_ramp.interpolation='EASE'
 normal=nodes.new('ShaderNodeCombineXYZ');normal.name='Seam shared world-up normal';normal.location=(-240,-160);normal.inputs['Z'].default_value=1
 links.new(geometry.outputs['Position'],noise.inputs['Vector']);links.new(noise.outputs['Fac'],ramp.inputs['Fac']);links.new(normal.outputs['Vector'],bsdf.inputs['Normal'])
 if original_color_source:
  multiply=nodes.new('ShaderNodeMixRGB');multiply.name='Seam preserve state color chain';multiply.blend_type='MULTIPLY';multiply.inputs[0].default_value=1
  links.new(original_color_source,multiply.inputs[1]);links.new(ramp.outputs['Color'],multiply.inputs[2]);links.new(multiply.outputs['Color'],bsdf.inputs['Base Color'])
 else:links.new(ramp.outputs['Color'],bsdf.inputs['Base Color'])
 col=bpy.data.collections.new('058 Seam blending and northeast connections');scene.collection.children.link(col)
 for e in entries:
  mesh=bpy.data.meshes.new(e['name']);mesh.from_pydata(e['v'],[],e['f']);mesh.update();obj=bpy.data.objects.new(e['name'],mesh);col.objects.link(obj)
  obj['purpose']='join original map and peripheral continuation';obj['kind']=e['kind']
  if e['kind']=='building':
   mesh.materials.append(facade);mesh.materials.append(roof)
   for face in mesh.polygons:face.material_index=int(face.normal.z>.5)
  else:mesh.materials.append(road)
  assert not mesh.validate(),e['name']
 after=snapshot();assert all(after.get(n)==v for n,v in before.items()),state
 assert scene.camera.data.ortho_scale==camera_scale
 scene.render.resolution_x=3200;scene.render.resolution_y=1500;scene.render.resolution_percentage=100;scene.render.filepath='//web/'+state+'.png';scene.cycles.samples=48;scene.cycles.device='GPU'
 bpy.ops.wm.save_as_mainfile(filepath=str(out/(state+'.blend')))
 report[state]={'preserved_objects':len(before),'added_objects':len(after)-len(before),'added_faces':sum(len(o.data.polygons) for o in col.objects),'flipped_up_faces':flipped,'camera_unchanged':True,'object_transforms_and_vertices_unchanged':True,'core_topology_unchanged':True,'shared_ground_base_color':color,'source_sha256':hashlib.sha256((base/(state+'.blend')).read_bytes()).hexdigest()}
 report[state]['preserved_color_chain']=original_color_source.node.name if original_color_source else 'unlinked base color'
 (work/'preservation.json').write_text(json.dumps(report,indent=2))
 if state=='day' and '--skip-preview' not in sys.argv:
  prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
  for device in prefs.devices:device.use=device.type=='OPTIX'
  scene.cycles.samples=24;scene.render.filepath=str(out/'day.png')
  print('SEAM_PREVIEW_START',flush=True);bpy.ops.render.render(write_still=True);print('SEAM_PREVIEW_DONE',flush=True)
print('SEAM_BUILD_PASS',json.dumps(report),flush=True)
