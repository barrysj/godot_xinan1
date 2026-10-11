import bpy,json,collections
from pathlib import Path
p=Path.cwd(); bpy.ops.wm.open_mainfile(filepath=str(p/'design/concepts/environments/campus-map/campus-map/asset_001/day.blend'))
r={ 'camera':{'matrix':[list(v) for v in bpy.context.scene.camera.matrix_world],'ortho':bpy.context.scene.camera.data.ortho_scale},'mesh':[] }
for o in bpy.data.objects:
 if o.type!='MESH': continue
 mats=[m.name for m in o.data.materials if m]
 if not any(any(w in m.lower() for w in ['facade','roof','paving','water','terrain']) for m in mats): continue
 vs=[list(o.matrix_world@v.co) for v in o.data.vertices]
 r['mesh'].append({'name':o.name,'props':dict(o.items()),'mats':mats,'v':vs,'f':[list(f.vertices) for f in o.data.polygons]})
(p/'.godot/art-workflow/northwest-southwest/geometry.json').write_text(json.dumps(r,default=str))
print('GEOMETRY',len(r['mesh']),r['camera'],flush=True)
