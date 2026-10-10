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
    assert (scene.render.resolution_x, scene.render.resolution_y) == (1800, 1500), state
    source = (bundle / f'{state}.png').read_bytes()
    assert source[:8] == b'\x89PNG\r\n\x1a\n', state
    assert struct.unpack('>II', source[16:24]) == (5400, 4500), state
    runtime = project / 'assets/art/campus_map/expanded_neutral' / f'{state}.png'
    assert source == runtime.read_bytes(), state
    web = (bundle / 'web' / f'{state}.png').read_bytes()
    assert web[:8] == b'\x89PNG\r\n\x1a\n', state
    assert struct.unpack('>II', web[16:24]) == (1800, 1500), state
    report[state] = dict(objects=len(bpy.data.objects), sha256=hashlib.sha256(source).hexdigest(), web_sha256=hashlib.sha256(web).hexdigest())
assert len({entry['sha256'] for entry in report.values()}) == 3
assert len({entry['web_sha256'] for entry in report.values()}) == 3
print('CAMPUS_BUNDLE_PASS', json.dumps(report))
