import sys,json,math
from pathlib import Path
sys.path.insert(0,str(Path('.godot/art-workflow/seam-blending/deps').resolve()))
import numpy as np
from shapely.geometry import Polygon,Point,LineString,box
from shapely.ops import unary_union
from shapely import make_valid
work=Path('.godot/art-workflow/seam-blending')
data=json.loads(Path('design/concepts/environments/campus-map/campus-map/asset_004/source/continuation/base-geometry.json').read_text())['mesh']
patch=json.loads(Path('design/concepts/environments/campus-map/campus-map/asset_004/source/infill-meshes.json').read_text())
def footprint(o):
 v=o['v']; ps=[]
 for f in o['f']:
  p=Polygon([v[i][:2] for i in f])
  if p.area>.0001:ps.append(make_valid(p))
 return unary_union(ps)
grounds=[o for o in data if any('terrain' in m.lower() for m in o['mats']) and not o['name'].startswith('051')]
grounds += [o for o in patch if o['kind']=='ground']
roads=[o for o in data if any('paving' in m.lower() for m in o['mats'])]+[o for o in patch if o['kind']=='roads']
coverage=unary_union([footprint(o) for o in grounds]).buffer(.25).buffer(-.25)
road=unary_union([footprint(o) for o in roads]).buffer(.015).buffer(-.015)
parts=list(road.geoms) if hasattr(road,'geoms') else [road]
caps=[]
def tangent(coords,index,step):
 a=coords[index];last=a
 for i in range(1,len(coords)):
  last=coords[(index+i*step)%len(coords)]
  if np.linalg.norm(last-a)>25:break
 return (last-a)/max(np.linalg.norm(last-a),1e-9)
for poly in parts:
 if poly.geom_type!='Polygon' or poly.area<100:continue
 coords=np.array(poly.simplify(.1,preserve_topology=True).exterior.coords)[:-1]
 for i,a in enumerate(coords):
  j=(i+1)%len(coords);b=coords[j];length=np.linalg.norm(b-a)
  if not 1.4<length<65:continue
  if max(coverage.boundary.distance(Point(a)),coverage.boundary.distance(Point(b)))>2.5:continue
  mid=(a+b)/2
  inward=tangent(coords,i,-1)+tangent(coords,j,1)
  d=-inward/max(np.linalg.norm(inward),1e-9)
  width=abs(np.cross(b-a,d))
  if not 1.3<width<38:continue
  if coverage.buffer(2).contains(Point(mid+d*25)):continue
  if not coverage.buffer(2).contains(Point(mid-d*25)):continue
  caps.append({'a':a.tolist(),'b':b.tolist(),'mid':mid.tolist(),'direction':d.tolist(),'width':float(width),'area':poly.area})
caps.sort(key=lambda c:-c['width'])
unique=[]
for c in caps:
 if any(np.linalg.norm(np.array(c['mid'])-d['mid'])<4 for d in unique):continue
 unique.append(c)
(work/'caps.json').write_text(json.dumps(unique,indent=2));(work/'coverage.wkt').write_text(coverage.wkt);(work/'roads.wkt').write_text(road.wkt)
print('ROAD_ENDS',len(unique))
for i,c in enumerate(unique):print(i,[round(x,1) for x in c['mid']],[round(x,3) for x in c['direction']],round(c['width'],1))

(work/'plot.json').write_text(json.dumps({'ground':[list(p.exterior.coords) for p in (list(coverage.geoms) if hasattr(coverage,'geoms') else [coverage]) if p.geom_type=='Polygon'],'roads':[list(p.exterior.coords) for p in parts if p.geom_type=='Polygon'],'caps':unique}))
