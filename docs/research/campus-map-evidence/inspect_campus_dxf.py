import sys, json, hashlib
from pathlib import Path
from collections import Counter, defaultdict
sys.path.insert(0,str(Path('.godot/dxf-research-deps').resolve()))
import ezdxf
from ezdxf import bbox

for name in ('topoexport_2D_vectorial.dxf','topoexport_3D_modeling.dxf'):
    p=Path('E:/Downloads/topoexport-B660A9')/name
    doc=ezdxf.readfile(p)
    msp=doc.modelspace()
    groups=defaultdict(list)
    for e in msp: groups[e.dxf.layer].append(e)
    report={'name':name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'version':doc.dxfversion,'units':doc.units,'entity_types':dict(Counter(e.dxftype() for e in msp)),'layers':{}}
    for layer,entities in groups.items():
        box=bbox.extents(entities,fast=True)
        row={'types':dict(Counter(e.dxftype() for e in entities)),'min':list(box.extmin) if box.has_data else None,'max':list(box.extmax) if box.has_data else None}
        meshes=[e for e in entities if e.dxftype()=='MESH']
        row['mesh_vertices']=sum(len(e.vertices) for e in meshes)
        row['mesh_faces']=sum(len(e.faces) for e in meshes)
        row['insert_blocks']=dict(Counter(e.dxf.name for e in entities if e.dxftype()=='INSERT'))
        report['layers'][layer]=row
    report['blocks']=[{'name':b.name,'types':dict(Counter(e.dxftype() for e in b))} for b in doc.blocks if not b.name.startswith('*')]
    report['geodata_count']=sum(1 for e in doc.objects if e.dxftype()=='GEODATA')
    report['audit_errors']=len(doc.audit().errors)
    (Path('.godot')/(name+'.json')).write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps(report,indent=2))
