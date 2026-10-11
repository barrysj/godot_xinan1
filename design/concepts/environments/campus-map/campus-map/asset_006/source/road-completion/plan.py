import sys,json
from pathlib import Path
sys.path.insert(0,str(Path('.godot/art-workflow/road-two-points/deps').resolve()))
import numpy as np
from shapely.geometry import Polygon,LineString,Point
from shapely.ops import unary_union
from shapely import wkt
b=Path('design/concepts/environments/campus-map/campus-map/asset_005');w=Path('.godot/art-workflow/road-two-points');caps=json.loads((b/'source/seams/caps.json').read_text())
roads=wkt.loads((b/'source/seams/roads.wkt').read_text())
for path in ['source/continuation/meshes.json','source/seams/meshes.json']:
 for o in json.loads((b/path).read_text()):
  if o['kind']=='roads': roads=unary_union([roads]+[Polygon([o['v'][i][:2] for i in f]) for f in o['f']])
(w/'all-roads.wkt').write_text(roads.wkt)
for i in [89,77,83,86]:
 c=caps[i];a=np.array(c['mid']);d=np.array(c['direction']);ray=LineString([a+d*10,a+d*500]);hits=ray.intersection(roads); print(i,hits.wkt[:1600])
