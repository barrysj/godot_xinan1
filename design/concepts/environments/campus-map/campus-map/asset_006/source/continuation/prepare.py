import sys,json,math,random
from pathlib import Path
sys.path.insert(0,str(Path('.godot/art-workflow/northwest-southwest/deps').resolve()))
import numpy as np
from shapely import wkt,points,STRtree,constrained_delaunay_triangles
from shapely.geometry import Polygon,Point,LineString,box
from shapely.ops import triangulate,unary_union,nearest_points
work=Path('.godot/art-workflow/road-continuation');caps=json.loads((work/'caps.json').read_text());coverage=wkt.loads((work/'coverage.wkt').read_text())
data=json.loads(Path('.godot/art-workflow/northwest-southwest/geometry.json').read_text())['mesh']
patch=json.loads(Path('design/concepts/environments/campus-map/campus-map/asset_002/source/infill-meshes.json').read_text())
grounds=[o for o in data if any('terrain' in m.lower() for m in o['mats']) and not o['name'].startswith('051')]+[o for o in patch if o['kind']=='ground']
road_sources=[o for o in data if any('paving' in m.lower() for m in o['mats'])]+[o for o in patch if o['kind']=='roads']
def terrain_index(objects):
 triangles=[];xy=[]
 for o in objects:
  for f in o['f']:
   for j in range(1,len(f)-1):
    v=np.array([o['v'][f[k]] for k in [0,j,j+1]])
    poly=Polygon(v[:,:2])
    if poly.area<1e-7:continue
    triangles.append(v);xy.append(poly)
 return np.array(triangles),xy,STRtree(xy)
gv,gpolys,gt=terrain_index(grounds);rv,rpolys,rt=terrain_index(road_sources)
domain=box(-2300,-1400,2300,1850);gap=domain.difference(coverage.buffer(-.08));height_cache={}
def sampled(x,y,verts,polys,tree):
 p=Point(x,y);idx=tree.nearest(p);near=nearest_points(polys[idx],p)[0];v=verts[idx]
 weights=np.linalg.solve(np.vstack((v[:,:2].T,np.ones(3))),[near.x,near.y,1])
 return float(weights@v[:,2]),p.distance(near)
def height(x,y):
 key=(round(x,4),round(y,4))
 if key not in height_cache:
  h,distance=sampled(x,y,gv,gpolys,gt);t=min(1,distance/200);t=t*t*(3-2*t)
  height_cache[key]=h*(1-t)+4*t-.08
 return height_cache[key]
def roadheight(x,y):
 h,distance=sampled(x,y,rv,rpolys,rt);t=min(1,distance/70);t=t*t*(3-2*t)
 return max(h*(1-t)+(height(x,y)+.16)*t,height(x,y)+.12)
# IDs are measured end caps, not a generated street grid. Nearby parallel edge bands stay paired.
groups=[[16,18,21],[12,46,53],[50,52],[0,29],[47,48,49],[15],[20],[4],[10],[19,30,33,43],[14,22],[32,39,55],[31]]
strips=[];corridors=[]
for ids in groups:
 subset=[caps[i] for i in ids];d=np.mean([c['direction'] for c in subset],axis=0);d/=np.linalg.norm(d);mid=np.mean([c['mid'] for c in subset],axis=0)
 lengths=[]
 for i in ids:
  c=caps[i];a=np.array(c['a']);b=np.array(c['b']);m=np.array(c['mid'])
  ray=LineString([m,m+d*4200]).intersection(domain)
  parts=list(ray.geoms) if hasattr(ray,'geoms') else [ray]
  line=max((p for p in parts if p.geom_type=='LineString'),key=lambda p:p.length)
  length=max(np.dot(np.array(p)-m,d) for p in line.coords)
  # A few minor source roads merge tangentially into their neighbouring continuation.
  merge={20:(15,500),10:(4,580),31:(39,520)}.get(i)
  if merge:
   target_id,along=merge;target_group=next(g for g in groups if target_id in g)
   target_d=np.mean([caps[k]['direction'] for k in target_group],axis=0);target_d/=np.linalg.norm(target_d)
   end=np.array(caps[target_id]['mid'])+target_d*along
   p0=m;p1=m+d*min(230,np.linalg.norm(end-m)*.4);p2=end-target_d*min(210,np.linalg.norm(end-m)*.35);p3=end
   stations=[];bands=[]
   initial_angle=math.atan2(d[1],d[0]);offsets=[a-m,b-m]
   for t in np.linspace(0,1,33):
    center=(1-t)**3*p0+3*(1-t)**2*t*p1+3*(1-t)*t*t*p2+t**3*p3
    tangent=3*(1-t)**2*(p1-p0)+6*(1-t)*t*(p2-p1)+3*t*t*(p3-p2)
    angle=math.atan2(tangent[1],tangent[0])-initial_angle;rot=np.array([[math.cos(angle),-math.sin(angle)],[math.sin(angle),math.cos(angle)]])
    stations.append([center+rot@v for v in offsets])
   for first,last in zip(stations,stations[1:]):bands.append(Polygon([first[0],first[1],last[1],last[0]]))
   poly=unary_union(bands).intersection(gap);length=min(length,np.linalg.norm(end-m))
  else:poly=Polygon([a-d*.12,b-d*.12,b+d*length,a+d*length]).intersection(gap)
  strips.append(poly);lengths.append(length)
 corridors.append(dict(ids=ids,mid=mid.tolist(),direction=d.tolist(),length=min(lengths),width=max(np.dot(np.array(c['mid'])-mid,[-d[1],d[0]])+c['width']/2 for c in subset)-min(np.dot(np.array(c['mid'])-mid,[-d[1],d[0]])-c['width']/2 for c in subset)))
road=unary_union(strips);out=[]
def parts(poly):return list(poly.geoms) if hasattr(poly,'geoms') else [poly]
def surf(poly,name,kind,fn,grid=80):
 vertices=[];faces=[];vmap={}
 def vertex(x,y):
  key=(round(x,5),round(y,5))
  if key not in vmap:vmap[key]=len(vertices);vertices.append([x,y,fn(x,y)])
  return vmap[key]
 minx,miny,maxx,maxy=poly.bounds
 for x in np.arange(math.floor(minx/grid)*grid,maxx,grid):
  for y in np.arange(math.floor(miny/grid)*grid,maxy,grid):
   q=poly.intersection(box(x,y,x+grid,y+grid))
   for piece in parts(q):
    if piece.geom_type!='Polygon' or piece.area<.0001:continue
    for t in constrained_delaunay_triangles(piece).geoms:

     faces.append([vertex(*p) for p in list(t.exterior.coords)[:3]])
 actual=sum(Polygon([vertices[i][:2] for i in f]).area for f in faces)
 assert abs(actual-poly.area)<max(.01,poly.area*1e-7),(name,actual,poly.area)
 out.append(dict(name=name,kind=kind,v=vertices,f=faces))
# Road-side building clusters, aligned to their actual parent road rather than an unrelated grid.
rng=random.Random(1111);buildings=[];drives=[]
for j,c in enumerate(corridors):
 m=np.array(c['mid']);d=np.array(c['direction']);n=np.array([-d[1],d[0]])
 if c['ids'][0] in [20,10,31]:continue
 placed=0
 for along,side in [(240,1),(490,-1),(720,1),(160,-1)]:
  if placed>=2 or along>c['length']-100:continue
  length=rng.choice([38,46,54]);depth=rng.choice([16,20,24]);offset=c['width']/2+depth/2+rng.uniform(16,25)
  center=m+d*along+n*side*offset
  rect=Polygon([center+d*length/2+n*depth/2,center-d*length/2+n*depth/2,center-d*length/2-n*depth/2,center+d*length/2-n*depth/2])
  if not box(-2100,-1100,2100,1500).covers(rect) or not gap.covers(rect.buffer(4)) or road.intersects(rect.buffer(5)):continue
  if any(p.intersects(rect.buffer(12)) for p in buildings):continue
  coords=list(rect.exterior.coords)[:4];base=min(height(*p) for p in coords)-.1;h=rng.choice([10,13,16]);v=[[x,y,base] for x,y in coords]+[[x,y,base+h] for x,y in coords]
  # Input corners run CCW; roof is explicitly triangulated later by Blender.
  out.append(dict(name=f'057 Roadside building {len(buildings)+1:02}',kind='building',v=v,f=[[3,2,1,0],[4,5,6,7],[0,1,5,4],[1,2,6,5],[2,3,7,6],[3,0,4,7]]))
  edge=center-n*side*depth/2;start=m+d*along+n*side*(c['width']/2)
  drives.append(LineString([start,edge]).buffer(1.5,cap_style=2).intersection(gap));buildings.append(rect);placed+=1
surf(gap,'057 Ground continuation','ground',height,90)
# Partition roads by the actual ground triangles so interpolation cannot bury road strips.
ground_mesh=out[-1];road_poly=road.union(unary_union(drives));vertices=[];faces=[]
for face in ground_mesh['f']:
 gvtx=np.array([ground_mesh['v'][i] for i in face]);tri=Polygon(gvtx[:,:2]);piece=tri.intersection(road_poly)
 if piece.is_empty or tri.area<1e-7:continue
 for part in parts(piece):
  if part.geom_type!='Polygon' or part.area<1e-7:continue
  for t in constrained_delaunay_triangles(part).geoms:
   indices=[]
   for x,y in list(t.exterior.coords)[:3]:
    weights=np.linalg.solve(np.vstack((gvtx[:,:2].T,np.ones(3))),[x,y,1]);z=max(roadheight(x,y),float(weights@gvtx[:,2])+.14)
    indices.append(len(vertices));vertices.append([x,y,z])
   faces.append(indices)
out.append(dict(name='057 Existing roads extended',kind='roads',v=vertices,f=faces))
(work/'meshes.json').write_text(json.dumps(out,separators=(',',':')))
report={'base_commit':'bb2d7c7','road_caps_used':[i for g in groups for i in g],'corridors':corridors,'cap_count':sum(len(g) for g in groups),'buildings':len(buildings),'objects':len(out),'faces':sum(len(o['f']) for o in out),'method':'extend measured road endcaps with paired edge bands; three minor branches merge tangentially; no independent grid','merges':{'20':[15,500],'10':[4,580],'31':[39,520]},'canvas':[3200,1500],'origin':[-700,0]}
(work/'recipe.json').write_text(json.dumps(report,indent=2));print({k:v for k,v in report.items() if k!='corridors'})
(work/'plot-new.json').write_text(json.dumps({'ground':[list(p.exterior.coords) for p in parts(coverage) if p.geom_type=='Polygon'],'roads':[list(p.exterior.coords) for p in parts(wkt.loads((work/'roads.wkt').read_text())) if p.geom_type=='Polygon'],'extensions':[list(p.exterior.coords) for p in parts(road) if p.geom_type=='Polygon'],'buildings':[list(p.exterior.coords) for p in buildings]}))
