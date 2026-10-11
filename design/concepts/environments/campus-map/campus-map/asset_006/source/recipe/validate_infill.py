import bpy,json,hashlib,struct,collections
import numpy as np
from pathlib import Path
root=Path.cwd(); folder=root/'design/concepts/environments/campus-map/campus-map'; report={}; new_hashes=[]
def snapshot():
 cache={}; rows={}
 for o in bpy.context.scene.objects:
  h=hashlib.sha256();h.update(o.type.encode());h.update(str(tuple(tuple(r) for r in o.matrix_world)).encode())
  if o.type=='MESH':
   if o.data.name not in cache:
    m=o.data; hh=hashlib.sha256()
    for seq,attr,n,dtype in [(m.vertices,'co',3,'f4'),(m.loops,'vertex_index',1,'i4'),(m.polygons,'material_index',1,'i4')]:
     a=np.empty(len(seq)*n,dtype=dtype);seq.foreach_get(attr,a);hh.update(a.tobytes())
    cache[m.name]=hh.digest()
   h.update(cache[o.data.name]);h.update(str([m.name if m else None for m in o.data.materials]).encode())
  rows[o.name]=h.hexdigest()
 cam=bpy.context.scene.camera
 return rows,([list(v) for v in cam.matrix_world],cam.data.type,cam.data.ortho_scale,bpy.context.scene.render.resolution_x,bpy.context.scene.render.resolution_y)
for state in ['day','night','anomaly']:
 bpy.ops.wm.open_mainfile(filepath=str(folder/'asset_001'/(state+'.blend')));before,cam=snapshot()
 bpy.ops.wm.open_mainfile(filepath=str(folder/'tmp_005'/(state+'.blend')));after,cam2=snapshot()
 assert cam==cam2
 assert all(after.get(k)==v for k,v in before.items()),state
 added=[o for o in bpy.context.scene.objects if o.name not in before]; assert len(added)==187
 hashes={}
 for o in added:
  assert o.type=='MESH' and len(o.data.polygons)>0
  a=np.empty(len(o.data.vertices)*3,dtype='f4');o.data.vertices.foreach_get('co',a)
  assert np.isfinite(a).all()
  hashes[o.name]=hashlib.sha256(a.tobytes()).hexdigest()
 new_hashes.append(hashes)
 png=(folder/'tmp_005'/(state+'.png')).read_bytes();assert struct.unpack('>II',png[16:24])==(1800,1500)
 report[state]={'original_objects_unchanged':len(before),'camera_unchanged':True,'added':dict(collections.Counter(o['source_kind'] for o in added)),'faces':sum(len(o.data.polygons) for o in added),'render':[1800,1500]}
assert new_hashes[0]==new_hashes[1]==new_hashes[2]
(root/'.godot/art-workflow/northwest-southwest/reopen-validation.json').write_text(json.dumps(report,indent=2))
print('REOPEN_VALIDATION_PASS',json.dumps(report),flush=True)
