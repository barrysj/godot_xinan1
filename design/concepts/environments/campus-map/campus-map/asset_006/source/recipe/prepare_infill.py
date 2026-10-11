import sys,json,struct,collections,hashlib
from pathlib import Path
sys.path.insert(0,str(Path('.godot/art-workflow/northwest-southwest/deps').resolve()))
import numpy as np
from shapely.geometry import Polygon,box
from shapely.ops import unary_union,triangulate
from shapely import make_valid
work=Path('.godot/art-workflow/northwest-southwest'); geom=json.loads((work/'geometry.json').read_text()); alignment=json.loads((work/'alignment.json').read_text())
def polys(o):
 v=np.array(o['v']); ps=[]
 for f in o['f']:
  p=Polygon(v[f,:2])
  if p.area>.001: ps.append(make_valid(p))
 return unary_union(ps)
terrains=[polys(o) for o in geom['mesh'] if any('terrain' in m.lower() for m in o['mats']) and not o['name'].startswith('051')]
coverage=unary_union(terrains).buffer(.015)
buildings=unary_union([polys(o) for o in geom['mesh'] if any('facade' in m for m in o['mats'])]).buffer(.1)
def glb(path):
 b=path.read_bytes(); n=struct.unpack_from('<I',b,12)[0]; d=json.loads(b[20:20+n]); binary=b[28+n:]
 def acc(i):
  a=d['accessors'][i]; bv=d['bufferViews'][a['bufferView']]; dtype={5126:'<f4',5125:'<u4',5123:'<u2',5121:'u1'}[a['componentType']]; size={'SCALAR':1,'VEC3':3}[a['type']]
  stride=bv.get('byteStride',np.dtype(dtype).itemsize*size)
  return np.ndarray((a['count'],size),dtype=dtype,buffer=binary,offset=bv.get('byteOffset',0)+a.get('byteOffset',0),strides=(stride,np.dtype(dtype).itemsize))
 rows=[]
 for m in d['meshes']:
  if not m['name'].startswith(('TPX_Buildings_','TPX_RoadsOutlines_','TPX_Waterways_','TPX_Ground_')): continue
  for pr in m['primitives']:
   if pr.get('mode',4)!=4: continue
   rows.append({'name':m['name'],'v':acc(pr['attributes']['POSITION']).astype(float),'f':acc(pr['indices']).reshape(-1,3)})
 return rows
output=[]; report={}
for region,al in alignment.items():
 shift=np.array([*al['translation_to_core'],0])-np.array([487.238728951721,506.594165236689,528])
 frame=Polygon(al['frames'][0]); frame=Polygon(np.array(frame.exterior.coords)+shift[:2]); gap=frame.difference(coverage)
 code=al['code']; src=Path('E:/Downloads/topoexport-'+code); rows=glb(src/'topoexport_3D_modeling.glb'); cnt=collections.Counter(); areas=collections.defaultdict(float)
 for o in rows:
  o['v']+=shift; kind=o['name'].split('_')[1].lower().replace('roadsoutlines','roads'); vs=o['v']; fs=o['f']; footprint=unary_union([Polygon(vs[f,:2]) for f in fs if Polygon(vs[f,:2]).area>.001])
  if kind=='buildings':
   if footprint.area<500: cnt['small_buildings_skipped']+=1;continue
   if footprint.intersection(buildings).area>.5 or footprint.intersection(gap).area<footprint.area*.5: cnt['existing_buildings_skipped']+=1;continue
   outv=vs.tolist();outf=fs.tolist(); areas[kind]+=footprint.area; buildings=buildings.union(footprint.buffer(.1))
  else:
   if kind in ('roads','waterways') and footprint.area<100: cnt['small_'+kind+'_skipped']+=1;continue
   clipped=footprint.intersection(gap)
   if clipped.area<(20 if kind!='ground' else 1):continue
   verts=[];faces=[]; vmap={}
   def vertex(p):
    key=tuple(round(float(x),5) for x in p)
    if key not in vmap:vmap[key]=len(verts);verts.append(list(p))
    return vmap[key]
   for f in fs:
    tri=vs[f]; poly=Polygon(tri[:,:2])
    if poly.area<1e-6:continue
    inter=poly.intersection(gap)
    if inter.is_empty:continue
    pieces=list(inter.geoms) if hasattr(inter,'geoms') else [inter]
    for piece in pieces:
     if piece.geom_type!='Polygon' or piece.area<.001:continue
     for t in triangulate(piece):
      if not piece.buffer(1e-7).covers(t):continue
      coords=np.array(t.exterior.coords)[:3]; weights=np.linalg.solve(np.vstack((tri[:,:2].T,np.ones(3))),np.vstack((coords.T,np.ones(3))))
      zz=tri[:,2]@weights
      if kind=='roads':zz+=.08
      if kind=='waterways':zz+=.06
      faces.append([vertex([*xy,float(z)]) for xy,z in zip(coords,zz)])
   if not faces:continue
   outv=verts;outf=faces;areas[kind]+=clipped.area
  cnt[kind]+=1
  output.append({'name':region.upper()+'_'+o['name'],'region':region,'source':code,'kind':kind,'v':outv,'f':outf})
 report[region]={'counts':dict(cnt),'area_m2':dict(areas),'gap_area_m2':gap.area,'source_sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in src.iterdir() if p.is_file()},'alignment':al}
 coverage=coverage.union(frame)
(work/'infill-meshes.json').write_text(json.dumps(output,separators=(',',':')))
(work/'report.json').write_text(json.dumps(report,indent=2))
print(json.dumps({k:{'counts':r['counts'],'area':r['area_m2']} for k,r in report.items()},indent=2))
print('TOTAL',len(output),'VERTS',sum(len(o['v']) for o in output),'FACES',sum(len(o['f']) for o in output))
