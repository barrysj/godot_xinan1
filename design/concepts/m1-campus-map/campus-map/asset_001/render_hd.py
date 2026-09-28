"""Render a retained state at 3x without modifying its Blender source.

Usage: blender -b -t 0 --python render_hd.py -- --state day
"""
import argparse
import sys
from pathlib import Path

import bpy

parser = argparse.ArgumentParser()
parser.add_argument('--state', choices=('day', 'night', 'anomaly'), required=True)
parser.add_argument('--output-dir', default='tmp_001', help='Sibling tmp_### directory')
args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
bundle = Path(__file__).resolve().parent
assert args.output_dir.startswith('tmp_') and args.output_dir[4:].isdigit(), args.output_dir
output = bundle.parent / args.output_dir
output.mkdir(exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(bundle / f'{args.state}.blend'))
scene = bpy.context.scene
scene.render.resolution_x = 5400
scene.render.resolution_y = 4500
scene.render.resolution_percentage = 100
scene.render.filepath = str(output / f'{args.state}.png')
scene.render.image_settings.file_format = 'PNG'
if scene.render.engine == 'CYCLES':
    prefs = bpy.context.preferences.addons['cycles'].preferences
    prefs.compute_device_type = 'OPTIX'
    prefs.get_devices()
    for device in prefs.devices:
        device.use = device.type == 'OPTIX'
    scene.cycles.device = 'GPU'
print('HD_RENDER', args.state, scene.render.engine, flush=True)
bpy.ops.render.render(write_still=True)
