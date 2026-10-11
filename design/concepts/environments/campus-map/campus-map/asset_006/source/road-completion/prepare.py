import sys,json
from pathlib import Path
sys.path.insert(0,str(Path('.godot/art-workflow/road-two-points/deps').resolve()))
import numpy as np
from shapely import wkt,STRtree,constrained_delaunay_triangles
from shapely.geometry import Polygon,Point,LineString,MultiPoint
from shapely.ops import unary_union
b=Path('design/concepts/environments/campus-map/campus-map/asset_005');w=Path('.godot/art-workflow/road-two-points')
caps=json.loads((b/'source/seams/caps.json').read_text());roads=wkt.loads((w/'all-roads.wkt').read_text())
original=json.loads((b/'source/continuation/base-geometry.json').read_text())['mesh']
extras=sum([json.loads((b/p).read_text()) for p in ['source/infill-meshes.json','source/continuation/meshes.json','source/seams/meshes.json']],[])
ground=[o for o in original if any('terrain' in m.lower() for m in o['mats']) and not o['name'].startswith('051')]+[o for o in extras if o['kind']=='ground']
triangles=[];polys=[]
for o in ground:
 for f in o['f']:
  for k in range(1,len(f)-1):
   tri=np.array([o['v'][i] for i in [f[0],f[k],f[k+1]]]);p=Polygon(tri[:,:2])
   if p.area>1e-6:triangles.append(tri);polys.append(p)
segments=[];paths=[]
def unit(d):return d/np.linalg.norm(d)
for i in [89,77,83,86]:
 c=caps[i];a=np.array(c['mid']);d=np.array(c['direction']);ray=LineString([a+d*10,a+d*500]);hits=ray.intersection(roads)
 parts=sorted(hits.geoms,key=lambda p: p.distance(Point(a)))[:2];points=[q for part in parts for q in part.coords];length=max(np.dot(np.array(q)-a,d) for q in points)
 # Stop inside the final existing road band, rather than beyond its far edge.
 end=a+d*(length-0.5);path=LineString([a-d*.8,end]);segments.append(path.buffer(c['width']/2,cap_style=2));paths.append({'cap':i,'start':a.tolist(),'end':end.tolist()})
for i,j in [(3,14),(5,35),(4,25),(38,15)]:
 ca,cb=caps[i],caps[j];a=np.array(ca['mid']);b1=np.array(cb['mid']);da=unit(np.array(ca['direction']));db=-unit(np.array(cb['direction']));p1=a+da*95;p2=b1-db*95;stations=[]
 for t in np.linspace(0,1,101):
  p=(1-t)**3*a+3*(1-t)**2*t*p1+3*(1-t)*t*t*p2+t**3*b1
  d=unit(3*(1-t)**2*(p1-a)+6*(1-t)*t*(p2-p1)+3*t*t*(b1-p2));n=np.array([-d[1],d[0]]);r=(ca['width']*(1-t)+cb['width']*t)/2
  if t==0:p-=da*.8
  if t==1:p+=db*.8
  stations.append([p-n*r,p+n*r])
 segments.append(unary_union([Polygon([p[0],p[1],q[1],q[0]]) for p,q in zip(stations,stations[1:])]))
 paths.append({'caps':[i,j],'handle_length':95})
new=unary_union(segments)
blockers=[]
for o in original:
 if any('facade' in m.lower() or 'roof' in m.lower() for m in o['mats']):blockers.append((o['name'],MultiPoint([p[:2] for p in o['v']]).convex_hull))
for o in extras:
 if o['kind'] in ['building','buildings']:blockers.append((o['name'],MultiPoint([p[:2] for p in o['v']]).convex_hull))
collisions=[(name,p.intersection(new).area) for name,p in blockers if p.intersection(new).area>.1]
print('COLLISIONS',collisions,flush=True)
assert not collisions,collisions
verts=[];faces=[];covered=[]
# Use original ground where present, continuation ground only covers gaps.
for tri,p in zip(triangles,polys):
 if not p.intersects(new):continue
 q=p.intersection(new)
 for piece in (list(q.geoms) if hasattr(q,'geoms') else [q]):
  if piece.geom_type!='Polygon' or piece.area<1e-6:continue
  covered.append(piece)
  for t in constrained_delaunay_triangles(piece).geoms:
   coords=list(t.exterior.coords)[:3]
   if np.linalg.det(np.array([np.array(coords[1])-coords[0],np.array(coords[2])-coords[0]]))<0:coords.reverse()
   f=[]
   for x,y in coords:
    weights=np.linalg.solve(np.vstack((tri[:,:2].T,np.ones(3))),[x,y,1]);f.append(len(verts));verts.append([x,y,float(weights@tri[:,2])+.20])
   faces.append(f)
missing=new.difference(unary_union(covered)).area
assert missing<.05,missing
entries=[dict(name='059 Requested west and north road completions',kind='roads',v=verts,f=faces)]
(w/'meshes.json').write_text(json.dumps(entries,separators=(',',':')))
(w/'recipe.json').write_text(json.dumps({'base_commit':'b16bb30','base_bundle':'asset_005','editor_targets':[[95,914],[989,54]],'paths':paths,'building_collisions':collisions,'uncovered_area':missing,'faces':len(faces)},indent=2))
print('GEOMETRY_PASS',len(faces),'faces',flush=True)
