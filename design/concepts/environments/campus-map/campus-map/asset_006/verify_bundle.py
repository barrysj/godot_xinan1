"""Read-only validation of the retained bundle; run inside Blender."""
import hashlib
import json
import struct
from pathlib import Path

import bpy

bundle = Path(__file__).resolve().parent
project = next(parent for parent in bundle.parents if (parent / "project.godot").is_file())
report = {}
for state in ('day', 'night', 'anomaly'):
    bpy.ops.wm.open_mainfile(filepath=str(bundle / f'{state}.blend'))
    missing = []
    for collection in (bpy.data.libraries, bpy.data.images, bpy.data.fonts):
        for item in collection:
            path = getattr(item, 'filepath', '')
            if not path or path == '<builtin>' or getattr(item, 'packed_file', None) or getattr(item, 'packed_files', None):
                continue
            if hasattr(item, 'source') and item.source != 'FILE':
                continue
            if not Path(bpy.path.abspath(path)).is_file():
                missing.append(path)
    assert not missing, (state, missing)
    scene = bpy.context.scene
    assert scene.camera is not None, state
    assert (scene.render.resolution_x, scene.render.resolution_y) == (3200, 1500), state
    source = (bundle / f'{state}.png').read_bytes()
    assert source[:8] == b'\x89PNG\r\n\x1a\n', state
    assert struct.unpack('>II', source[16:24]) == (7680, 3600), state
    runtime = project / 'assets/art/campus_map/expanded_neutral' / f'{state}.png'
    assert source == runtime.read_bytes(), state
    web = (bundle / 'web' / f'{state}.png').read_bytes()
    assert web[:8] == b'\x89PNG\r\n\x1a\n', state
    assert struct.unpack('>II', web[16:24]) == (3200, 1500), state
    web_runtime = project / 'assets/art/web_campus_map/expanded_neutral' / f'{state}.png'
    assert web == web_runtime.read_bytes(), state
    added = [o for o in scene.objects if o.get('purpose') == 'peripheral background infill']
    assert len(added) == 187, (state, len(added))
    extension = [o for o in scene.objects if o.name.startswith('057 ')]
    assert len(extension) == 22, (state, len(extension))
    assert sum(len(o.data.polygons) for o in extension) == 6257, state
    assert not any(o.name.startswith('056 ') for o in scene.objects), state
    assert len([o for o in extension if o.get('kind') == 'building']) == 20, state
    seams = [o for o in scene.objects if o.name.startswith('058 ')]
    recipe = json.loads((bundle / 'source/seams/recipe.json').read_text())
    assert len(seams) == recipe['objects'], (state, len(seams))
    assert sum(len(o.data.polygons) for o in seams) == recipe['faces'], state
    assert len([o for o in seams if o.get('kind') == 'building']) == recipe['buildings'], state
    for obj in extension + seams:
        if obj.get('kind') in ('ground', 'roads'):
            assert all((obj.matrix_world.to_3x3() @ face.normal).z >= 0 for face in obj.data.polygons), (state, obj.name)
    completions = [o for o in scene.objects if o.name.startswith('059 ')]
    completion_recipe = json.loads((bundle / 'source/road-completion/recipe.json').read_text())
    assert len(completions) == 1, state
    assert sum(len(o.data.polygons) for o in completions) == completion_recipe['faces'], state
    assert all(face.normal.z > 0 for obj in completions for face in obj.data.polygons), state
    terrain = bpy.data.objects['051 Neutral terrain beneath export edges'].data.materials[0]
    nodes = terrain.node_tree.nodes
    assert nodes.get('Seam shared ground palette') is not None, state
    assert nodes.get('Seam shared world-up normal') is not None, state
    if state == 'anomaly':
        assert nodes.get('Seam preserve state color chain') is not None, state
        preserved = nodes['Seam preserve state color chain'].inputs[1].links
        assert len(preserved) == 1 and preserved[0].from_node.name == 'Mix (Legacy).001', state
    assert abs(nodes['Seam broad ground variation'].inputs['Scale'].default_value - recipe['noise_scale']) < 1e-7, state
    assert abs(scene.camera.data.ortho_scale - 2200 * 3200 / 1800) < .001, state
    assert len([o for o in added if o.get('source_kind') == 'buildings']) == 82, state
    report[state] = dict(objects=len(bpy.data.objects), sha256=hashlib.sha256(source).hexdigest(), web_sha256=hashlib.sha256(web).hexdigest())
assert len({entry['sha256'] for entry in report.values()}) == 3
assert len({entry['web_sha256'] for entry in report.values()}) == 3
print('CAMPUS_BUNDLE_PASS', json.dumps(report))
