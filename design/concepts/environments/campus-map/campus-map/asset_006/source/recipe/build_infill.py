import bpy,json,hashlib,sys
from pathlib import Path
p=Path.cwd(); work=p/'.godot/art-workflow/northwest-southwest'; base=p/'design/concepts/environments/campus-map/campus-map/asset_001'; out=base.parent/'tmp_005'
out.mkdir(exist_ok=True); meshes=json.loads((work/'infill-meshes.json').read_text()); report={}
for state in ['day','night','anomaly']:
 bpy.ops.wm.open_mainfile(filepath=str(base/(state+'.blend')))
 scene=bpy.context.scene; camera=[list(v) for v in scene.camera.matrix_world]; old_count=len(scene.objects)
 # Reuse each state's original material roles, including its night/anomaly colours.
 sample=next(o for o in scene.objects if o.name.startswith('WEST_TPX_Buildings') and len(o.data.materials)>=2)
 facade,roof=sample.data.materials[:2]
 terrain=bpy.data.objects['051 Neutral terrain beneath export edges'].data.materials[0]
 road=next(o.data.materials[0] for o in scene.objects if o.type=='MESH' and o.get('source_layer')=='TPX_ROADS_HATCH')
 water=next(o.data.materials[0] for o in scene.objects if o.type=='MESH' and o.get('source_layer')=='TPX_WATERWAYS_HATCH')
 cols={}
 for region in ['northwest','southwest']:
  c=bpy.data.collections.new('055 '+region+' / major background infill');scene.collection.children.link(c);cols[region]=c
 for entry in meshes:
  mesh=bpy.data.meshes.new(entry['name']);mesh.from_pydata(entry['v'],[],entry['f']);mesh.update()
  obj=bpy.data.objects.new(entry['name'],mesh);cols[entry['region']].objects.link(obj)
  obj['tile']=entry['source'];obj['source_kind']=entry['kind'];obj['purpose']='peripheral background infill';obj['building_min_footprint_m2']=500
  if entry['kind']=='buildings':
   mesh.materials.append(facade);mesh.materials.append(roof)
   for face in mesh.polygons:face.material_index=1 if face.normal.z>.5 else 0
  else:mesh.materials.append({'roads':road,'waterways':water,'ground':terrain}[entry['kind']])
  mesh.validate(clean_customdata=True); mesh.update(); assert not mesh.validate(),entry['name']
 assert [list(v) for v in scene.camera.matrix_world]==camera
 assert len(scene.objects)==old_count+len(meshes)
 scene.render.filepath=str(out/(state+'.png'))
 bpy.ops.wm.save_as_mainfile(filepath=str(out/(state+'.blend')))
 report[state]={'objects_before':old_count,'objects_after':len(scene.objects),'added':len(meshes),'camera_unchanged':True,'materials': [m.name for m in [facade,roof,terrain,road,water]],'source_sha256':hashlib.sha256((base/(state+'.blend')).read_bytes()).hexdigest()}
 scene.render.resolution_percentage=100;scene.render.resolution_x=1800;scene.render.resolution_y=1500
 if scene.render.engine=='CYCLES':
  scene.cycles.samples=32
  prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
  for device in prefs.devices:device.use=device.type=='OPTIX'
  scene.cycles.device='GPU'
 print('RENDER_START',state,scene.render.engine,flush=True)
 bpy.ops.render.render(write_still=True)
(work/'build-validation.json').write_text(json.dumps(report,indent=2))
print('INFILL_BUILD_PASS',json.dumps(report),flush=True)
