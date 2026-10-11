import sys,json,math
from pathlib import Path
sys.path.insert(0,str(Path('.godot/art-workflow/seam-blending/deps').resolve()))
import numpy as np
from shapely import wkt,STRtree,constrained_delaunay_triangles
from shapely.geometry import Polygon,Point,LineString,MultiPoint
from shapely.ops import unary_union,nearest_points
base=Path('design/concepts/environments/campus-map/campus-map/asset_004');w=Path('.godot/art-workflow/seam-blending')
caps=json.loads((w/'caps.json').read_text());original=json.loads((base/'source/continuation/base-geometry.json').read_text())['mesh'];infill=json.loads((base/'source/infill-meshes.json').read_text());ext=json.loads((base/'source/continuation/meshes.json').read_text());coverage=wkt.loads((w/'coverage.wkt').read_text())
ground=[o for o in original if any('terrain' in m.lower() for m in o['mats']) and not o['name'].startswith('051')]+[o for o in infill+ext if o['kind']=='ground']
triangles=[];polys=[]
for o in ground:
 for face in o['f']:
  for k in range(1,len(face)-1):
   tri=np.array([o['v'][i] for i in [face[0],face[k],face[k+1]]]);p=Polygon(tri[:,:2])
   if p.area>1e-6:triangles.append(tri);polys.append(p)
tree=STRtree(polys)
def height(x,y):
 p=Point(x,y);idx=tree.nearest(p);v=triangles[idx];q=nearest_points(polys[idx],p)[0];b=np.linalg.solve(np.vstack((v[:,:2].T,np.ones(3))),[q.x,q.y,1]);return float(b@v[:,2])
def unit(v):return v/max(np.linalg.norm(v),1e-9)
def curve(a,b,da,db,wa,wb,handles=None):
 a=np.array(a);b=np.array(b);da=unit(np.array(da));db=unit(np.array(db));length=np.linalg.norm(b-a);h=handles or [length*.38,length*.38];p1=a+da*h[0];p2=b-db*h[1];stations=[]
 for t in np.linspace(0,1,65):
  p=(1-t)**3*a+3*(1-t)**2*t*p1+3*(1-t)*t*t*p2+t**3*b;d=unit(3*(1-t)**2*(p1-a)+6*(1-t)*t*(p2-p1)+3*t*t*(b-p2));n=np.array([-d[1],d[0]]);r=(wa*(1-t)+wb*t)/2;stations.append([p-n*r,p+n*r])
 return unary_union([Polygon([p[0],p[1],q[1],q[0]]) for p,q in zip(stations,stations[1:])])
segments=[];pairs=[(10,100),(12,72),(21,88),(24,91),(23,74),(17,73)]
for a,b in pairs:
 ca,cb=caps[a],caps[b];segments.append(curve(ca['mid'],cb['mid'],ca['direction'],-np.array(cb['direction']),ca['width'],cb['width']))
# Tie the two north-east cut streets into a soft outer bend that joins the existing extension.
c=caps[31];end=np.array(caps[19]['mid'])+np.array(caps[19]['direction'])*190
segments.append(curve(c['mid'],end,c['direction'],caps[19]['direction'],c['width'],caps[19]['width'],[390,95]))
a=np.array(c['mid']);p1=a+unit(np.array(c['direction']))*390;p2=end-unit(np.array(caps[19]['direction']))*95
for i,t in [(20,.43),(26,.66)]:
 target=(1-t)**3*a+3*(1-t)**2*t*p1+3*(1-t)*t*t*p2+t**3*end
 direction=3*(1-t)**2*(p1-a)+6*(1-t)*t*(p2-p1)+3*t*t*(end-p2)
 c=caps[i];segments.append(curve(c['mid'],target,c['direction'],direction,c['width'],4.2))
newroads=unary_union(segments).intersection(coverage.buffer(.5).difference(coverage.buffer(-.5)).union(coverage.envelope.buffer(1100).difference(coverage)))
# Existing continuation and all source roads are blockers for new roadside buildings.
roadpolys=[wkt.loads((w/'roads.wkt').read_text())]
for o in ext:
 if o['kind']=='roads':roadpolys.extend(Polygon([o['v'][i][:2] for i in f]) for f in o['f'])
roads=unary_union(roadpolys+[newroads])
blockers=[]
for o in original:
 if any('facade' in m.lower() or 'roof' in m.lower() for m in o['mats']):blockers.append(MultiPoint([p[:2] for p in o['v']]).convex_hull)
for o in infill+ext:
 if o['kind'] in ['building','buildings']:blockers.append(MultiPoint([p[:2] for p in o['v']]).convex_hull)
occupied=unary_union(blockers).buffer(7);out=[];added=[];drives=[]
targets=[(761,1112),(824,1030),(776,979),(798,904),(780,845),(863,786),(946,682),(974,548),(991,333),(974,40),(989,-400),(969,-720),(-933,574),(-947,360),(-940,80),(-964,-173),(-940,-380),(-1006,-680)]
for j,(x,y) in enumerate(targets):
 angle=-.73 if x>0 else -.56;d=np.array([math.cos(angle),math.sin(angle)]);n=np.array([-d[1],d[0]]);placed=False
 for dx,dy in [(0,0),(24,0),(0,24),(-24,0),(0,-24),(40,25),(-30,-25),(20,-40),(45,-30)]:
  center=np.array([x+dx,y+dy]);length=[34,42,48][j%3];depth=[18,22][j%2]
  corners=[center+d*length/2+n*depth/2,center-d*length/2+n*depth/2,center-d*length/2-n*depth/2,center+d*length/2-n*depth/2];p=Polygon(corners)
  if occupied.intersects(p) or roads.buffer(5).intersects(p):continue
  if not 2<coverage.boundary.distance(p.centroid)<175:continue
  if any(p.buffer(9).intersects(q) for q in added):continue
  z=min(height(*q) for q in corners)-.15;h=[10,13,16][j%3];v=[[float(a),float(b),z] for a,b in corners]+[[float(a),float(b),z+h] for a,b in corners]
  out.append(dict(name=f'058 Seam building {len(added)+1:02}',kind='building',v=v,f=[[3,2,1,0],[4,5,6,7],[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7]]));added.append(p);placed=True;break
# Lay the bridges on the existing surface, splitting at ground triangles to prevent burial.
verts=[];faces=[]
for tri,p in zip(triangles,polys):
 q=p.intersection(newroads)
 parts=list(q.geoms) if hasattr(q,'geoms') else [q]
 for piece in parts:
  if piece.geom_type!='Polygon' or piece.area<1e-5:continue
  for t in constrained_delaunay_triangles(piece).geoms:
   f=[]
   coords=list(t.exterior.coords)[:3]
   if np.cross(np.array(coords[1])-coords[0],np.array(coords[2])-coords[0])<0:coords.reverse()
   for x,y in coords:
    weights=np.linalg.solve(np.vstack((tri[:,:2].T,np.ones(3))),[x,y,1]);f.append(len(verts));verts.append([x,y,float(weights@tri[:,2])+.19])
   faces.append(f)
out.append(dict(name='058 Northeast road connections',kind='roads',v=verts,f=faces))
(w/'meshes.json').write_text(json.dumps(out,separators=(',',':')))
(w/'recipe.json').write_text(json.dumps({'base':'5042aae / asset_004','matched_cap_pairs':pairs,'curved_outer_links':3,'buildings':len(added),'objects':len(out),'faces':sum(len(o['f']) for o in out),'ground_material':'shared world-space low-frequency color variation, unified world-up shading normal','noise_scale':.0045},indent=2))
print('SEAM_GEOMETRY',len(out),'objects',len(added),'buildings',len(faces),'road faces')
