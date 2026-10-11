import sys,json,collections
from pathlib import Path
sys.path.insert(0,str(Path('.godot/art-workflow/northwest-southwest/deps').resolve()))
import ezdxf,numpy as np
from shapely.geometry import Polygon
root=Path('design/references/m1-campus-map/topoexport'); out=Path('.godot/art-workflow/northwest-southwest')
def load(path):
 d=ezdxf.readfile(path); rows=[]
 for e in d.modelspace().query('LWPOLYLINE[layer=="TPX_BUILDINGS"]'):
  pts=np.array(e.get_points('xy')); p=Polygon(pts)
  if p.is_valid and p.area>20: rows.append({'h':e.dxf.handle,'p':p,'c':np.array(p.centroid.coords[0]),'a':p.area,'dims':np.array(p.bounds[2:])-p.bounds[:2]})
 return d,rows
anchors={}
for name,shift in [('core',[0,0]),('west',[-426.57890363,-185.61944805]),('north',[133.82638867,736.08427956])]:
 d,rows=load(root/(name+'-2d.dxf')); anchors[name]=(rows,np.array(shift))
result={}
for label,code in [('northwest','001EC1'),('southwest','E7EBC4')]:
 d,rows=load(Path('E:/Downloads/topoexport-'+code+'/topoexport_2D_vectorial.dxf'))
 candidates=[]
 for name,(ars,shift) in anchors.items():
  for a in ars:
   for b in rows:
    if abs(a['a']-b['a'])<.03 and np.max(abs(a['dims']-b['dims']))<.01:
     t=a['c']+shift-b['c']; candidates.append((t,name,a['h'],b['h']))
 counts=collections.Counter(tuple(np.round(c[0],2)) for c in candidates); best,n=counts.most_common(1)[0]
 matches=[c for c in candidates if np.linalg.norm(c[0]-best)<.05]; t=np.median([c[0] for c in matches],axis=0)
 r={'code':code,'translation_to_core':t.tolist(),'matches':len(matches),'max_residual':max(float(np.linalg.norm(c[0]-t)) for c in matches),'layers':dict(collections.Counter(e.dxf.layer for e in d.modelspace()))}
 frames=[list(e.get_points('xy')) for e in d.modelspace().query('LWPOLYLINE[layer=="TPX_FRAME_PROJECT"]')]; r['frames']=frames
 result[label]=r
print(json.dumps(result,indent=2)); (out/'alignment.json').write_text(json.dumps(result,indent=2))
