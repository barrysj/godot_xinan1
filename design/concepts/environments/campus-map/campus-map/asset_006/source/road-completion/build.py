import bpy,json,array,hashlib,shutil
from pathlib import Path
root=Path.cwd();base=root/'design/concepts/environments/campus-map/campus-map/asset_005';out=base.parent/'tmp_009';w=root/'.godot/art-workflow/road-two-points'
if not out.exists():shutil.copytree(base,out)
source=out/'source/road-completion';source.mkdir(exist_ok=True)
for name in ['prepare.py','plan.py','meshes.json','recipe.json'] :shutil.copy2(w/name,source/name)
entries=json.loads((w/'meshes.json').read_text());bpy.context.preferences.filepaths.save_version=0;report={}
def fingerprint():
 result={}
 for o in bpy.context.scene.objects:
  h=hashlib.sha256(str([list(r) for r in o.matrix_world]).encode())
  if o.type=='MESH':
   a=array.array('f',[0])*(len(o.data.vertices)*3);o.data.vertices.foreach_get('co',a);h.update(a.tobytes())
   a=array.array('i',[0])*len(o.data.loops);o.data.loops.foreach_get('vertex_index',a);h.update(a.tobytes())
  result[o.name]=h.hexdigest()
 return result
for state in ['day','night','anomaly']:
 bpy.ops.wm.open_mainfile(filepath=str(base/(state+'.blend')));s=bpy.context.scene;before=fingerprint();camera=list(s.camera.matrix_world);scale=s.camera.data.ortho_scale
 road=next(o.data.materials[0] for o in s.objects if o.type=='MESH' and o.get('source_layer')=='TPX_ROADS_HATCH')
 col=bpy.data.collections.new('059 Requested road completions');s.collection.children.link(col)
 for e in entries:
  mesh=bpy.data.meshes.new(e['name']);mesh.from_pydata(e['v'],[],e['f']);mesh.materials.append(road);mesh.update();assert not mesh.validate()
  obj=bpy.data.objects.new(e['name'],mesh);obj['kind']='roads';obj['editor_targets']='95,914;989,54';col.objects.link(obj)
 after=fingerprint();assert all(after[n]==v for n,v in before.items());assert list(s.camera.matrix_world)==camera and s.camera.data.ortho_scale==scale
 bpy.ops.wm.save_as_mainfile(filepath=str(out/(state+'.blend')))
 report[state]={'preserved_objects':len(before),'added_objects':len(after)-len(before),'added_faces':len(entries[0]['f']),'camera_unchanged':True}
(source/'preservation.json').write_text(json.dumps(report,indent=2));shutil.copy2(__file__,source/'build.py')
print('ROAD_COMPLETION_BUILD_PASS',report,flush=True)
