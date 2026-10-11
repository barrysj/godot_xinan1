import json,sys
from pathlib import Path
sys.path.insert(0,str(Path('.godot/art-workflow/seam-blending/deps').resolve()))
from shapely.geometry import Polygon,MultiPoint
from shapely.ops import unary_union
base=Path('design/concepts/environments/campus-map/campus-map/asset_005/source')
seams=json.loads((base/'seams/meshes.json').read_text())
road=next(o for o in seams if o['kind']=='roads')
roads=unary_union([Polygon([road['v'][i][:2] for i in f]) for f in road['f']])
old=json.loads((base/'continuation/base-geometry.json').read_text())['mesh']
old=[o for o in old if any('facade' in m.lower() or 'roof' in m.lower() for m in o['mats'])]
for path in ['infill-meshes.json','continuation/meshes.json']:
 old.extend(o for o in json.loads((base/path).read_text()) if o['kind'] in ['building','buildings'])
overlap=[]
for o in old:
 footprint=MultiPoint([v[:2] for v in o['v']]).convex_hull
 area=roads.intersection(footprint).area
 if area>1:overlap.append([o['name'],round(area,3)])
print('NEW_ROADS_EXISTING_BUILDING_OVERLAP',overlap)
assert not overlap,overlap
new=[o for o in seams if o['kind']=='building']
for o in new:
 footprint=MultiPoint([v[:2] for v in o['v']]).convex_hull
 assert roads.intersection(footprint).area<.001,o['name']
print('SEAM_BUILDINGS_CLEAR_OF_NEW_ROADS',len(new))
