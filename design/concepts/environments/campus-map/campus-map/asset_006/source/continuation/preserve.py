import bpy,json,hashlib,array
from pathlib import Path
from mathutils import Vector
from bpy_extras.object_utils import world_to_camera_view
root=Path.cwd();base=root/'design/concepts/environments/campus-map/campus-map/asset_002';out=base.parent/'asset_004';tmp=base.parent/'tmp_007'
bpy.context.preferences.filepaths.save_version=0
report={}
def snapshot():
 meshes={};objects={}
 for o in bpy.context.scene.objects:
  if o.type=='CAMERA':continue
  shape=None
  if o.type=='MESH':
   key=o.data.name
   if key not in meshes:
    a=array.array('f',[0])* (len(o.data.vertices)*3);o.data.vertices.foreach_get('co',a)
    b=array.array('i',[0])*len(o.data.loops);o.data.loops.foreach_get('vertex_index',b)
    meshes[key]=hashlib.sha256(a.tobytes()+b.tobytes()).hexdigest()
   shape=meshes[key]
  objects[o.name]={'matrix':[list(r) for r in o.matrix_world],'mesh':shape}
 return objects
probes=[Vector(v) for v in [(-500,-500,0),(0,0,0),(500,600,15)]]
for state in ['day','night','anomaly']:
 bpy.ops.wm.open_mainfile(filepath=str(base/(state+'.blend')));old=snapshot();scene=bpy.context.scene
 uv=[world_to_camera_view(scene,scene.camera,p) for p in probes]
 before=[[v.x*1800,v.y*1500] for v in uv]
 bpy.ops.wm.open_mainfile(filepath=str(tmp/(state+'.blend')));now=snapshot();scene=bpy.context.scene
 assert all(now.get(n)==v for n,v in old.items()),state
 uv=[world_to_camera_view(scene,scene.camera,p) for p in probes]
 after=[[v.x*3200-700,v.y*1500] for v in uv]
 error=max(abs(a-b) for xs,ys in zip(before,after) for a,b in zip(xs,ys));assert error<.001,(state,error)
 scene.render.filepath='//web/'+state+'.png';scene.cycles.samples=48;scene.cycles.device='GPU'
 bpy.ops.wm.save_as_mainfile(filepath=str(out/(state+'.blend')))
 report[state]={'preserved_objects':len(old),'added_objects':len(now)-len(old),'core_projection_error_pixels':error,'source_sha256':hashlib.sha256((base/(state+'.blend')).read_bytes()).hexdigest()}
(out/'source/continuation/preservation.json').write_text(json.dumps(report,indent=2))
print('WIDE_PRESERVATION_PASS',json.dumps(report),flush=True)
