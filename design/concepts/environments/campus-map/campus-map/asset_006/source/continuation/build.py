import bpy,json,hashlib
from pathlib import Path
root=Path.cwd();w=root/'.godot/art-workflow/road-continuation';base=root/'design/concepts/environments/campus-map/campus-map/asset_002';out=base.parent/'tmp_007';entries=json.loads((w/'meshes.json').read_text());report={}
bpy.context.preferences.filepaths.save_version=0
for state in ['day','night','anomaly']:
 bpy.ops.wm.open_mainfile(filepath=str(base/(state+'.blend')));scene=bpy.context.scene;old=len(scene.objects);camera=[list(r) for r in scene.camera.matrix_world]
 sample=next(o for o in scene.objects if o.name.startswith('WEST_TPX_Buildings') and len(o.data.materials)>=2);facade,roof=sample.data.materials[:2]
 terrain=bpy.data.objects['051 Neutral terrain beneath export edges'].data.materials[0]
 road=next(o.data.materials[0] for o in scene.objects if o.type=='MESH' and o.get('source_layer')=='TPX_ROADS_HATCH')
 col=bpy.data.collections.new('057 Source road continuations and roadside blocks');scene.collection.children.link(col)
 for e in entries:
  mesh=bpy.data.meshes.new(e['name']);mesh.from_pydata(e['v'],[],e['f']);mesh.update();obj=bpy.data.objects.new(e['name'],mesh);col.objects.link(obj);obj['purpose']='continuation of measured road endcaps; decorative outside source coverage';obj['kind']=e['kind']
  if e['kind']=='building':
   mesh.materials.append(facade);mesh.materials.append(roof)
   for f in mesh.polygons:f.material_index=int(f.normal.z>.5)
  else:mesh.materials.append(terrain if e['kind']=='ground' else road)
  mesh.validate(clean_customdata=True);mesh.update();assert not mesh.validate(),e['name']
 scene.camera.data.ortho_scale=2200*3200/1800;scene.render.resolution_x=3200;scene.render.resolution_y=1500;scene.render.resolution_percentage=100;scene.render.filepath='//'+state+'.png';scene.cycles.samples=24
 assert [list(r) for r in scene.camera.matrix_world]==camera
 scene['wide_logical_origin']=[-700,0];scene['wide_logical_size']=[3200,1500];scene['original_logical_size']=[1800,1500]
 bpy.ops.wm.save_as_mainfile(filepath=str(out/(state+'.blend')))
 report[state]={'original_objects':old,'added':len(scene.objects)-old,'faces':sum(len(o.data.polygons) for o in col.objects),'source_sha256':hashlib.sha256((base/(state+'.blend')).read_bytes()).hexdigest()};(w/'build-evidence.json').write_text(json.dumps(report,indent=2))
 prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
 for d in prefs.devices:d.use=d.type=='OPTIX'
 scene.cycles.device='GPU';scene.render.filepath=str(out/(state+'.png'))
 print('CONTINUATION_RENDER_START',state,flush=True);bpy.ops.render.render(write_still=True);print('CONTINUATION_RENDER_DONE',state,flush=True)
