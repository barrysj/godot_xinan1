import sys, math
from pathlib import Path
sys.path.insert(0,str(Path('.godot/dxf-research-deps').resolve()))
import ezdxf
doc=ezdxf.readfile('E:/Downloads/topoexport-B660A9/topoexport_3D_modeling.dxf')
meshes=[e for e in doc.modelspace() if e.dxftype()=='MESH']
colors={'TPX_BUILDINGS':'#d5dae0','TPX_ROADS_HATCH':'#faf7eb','TPX_WATERWAYS_HATCH':'#7cbecf','TPX_VEGETATION_GREEN_SPACES_HATCH':'#b6cf9c','TPX_TERRAIN_TERRAIN_MESH':'#e3ddcb'}
def project(v,tilt):
    x,y,z=v
    return (x,1013-y) if not tilt else (x,(1013-y)*.68-(z-528)*2)
def panel(tilt):
    parts=[]
    for layer in ('TPX_TERRAIN_TERRAIN_MESH','TPX_VEGETATION_GREEN_SPACES_HATCH','TPX_WATERWAYS_HATCH','TPX_ROADS_HATCH','TPX_BUILDINGS'):
        faces=[]
        for e in meshes:
            if e.dxf.layer != layer: continue
            verts=list(e.vertices)
            for face in e.faces:
                vs=[verts[i] for i in face]
                faces.append((sum(v[1] for v in vs)/len(vs),vs))
        for depth,vs in sorted(faces,key=lambda item:-item[0]):
            fill=colors[layer]
            if layer=='TPX_BUILDINGS':
                fill='#8d9baa' if max(v[2] for v in vs)-min(v[2] for v in vs)>1 else '#e1e6eb'
            points=' '.join('%.2f,%.2f'%project(v,tilt) for v in vs)
            parts.append(f'<polygon points="{points}" fill="{fill}" stroke="{fill}" stroke-width=".25"/>')
    return '<svg viewBox="-110 -110 1250 1240">'+''.join(parts)+'</svg>'
page='''<!doctype html><meta charset="utf-8"><style>body{background:#f2f5f5;font:18px Arial;margin:25px}main{display:flex;gap:20px}section{width:50%;background:white;padding:15px}svg{width:100%;height:820px}h1{font-size:25px}p{color:#456}</style><h1>DXF geometry inspection / NOT an art concept</h1><p>Actual exported building, water, road and terrain meshes. Trees omitted. Right view uses diagnostic Z x2; no textures or invented geometry.</p><main><section><h2>Top view / DXF +Y up</h2>TOP</section><section><h2>Oblique diagnostic projection</h2>OBLIQUE</section></main>'''.replace('TOP',panel(False)).replace('OBLIQUE',panel(True))
Path('.godot/dxf-inspection.html').write_text(page,encoding='utf-8')
print('Rendered mesh faces into diagnostic SVG; no source edits')
