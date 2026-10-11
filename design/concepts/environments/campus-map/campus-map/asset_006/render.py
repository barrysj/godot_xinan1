"""Render the retained campus master; run with Blender --background --python."""
import argparse,sys
from pathlib import Path
import bpy
parser=argparse.ArgumentParser()
parser.add_argument('--state',choices=['day','night','anomaly','all'],default='all')
parser.add_argument('--web',action='store_true',help='Render 3200x1500 delivery instead of desktop 7680x3600')
args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
bundle=Path(__file__).resolve().parent
for state in (['day','night','anomaly'] if args.state=='all' else [args.state]):
 bpy.ops.wm.open_mainfile(filepath=str(bundle/(state+'.blend')))
 scene=bpy.context.scene
 scene.render.resolution_x,scene.render.resolution_y=(3200,1500) if args.web else (7680,3600)
 scene.render.resolution_percentage=100
 scene.render.filepath=str(bundle/('web' if args.web else '.')/(state+'.png'))
 scene.render.image_settings.file_format='PNG'
 if scene.render.engine=='CYCLES':
  prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
  for device in prefs.devices:device.use=device.type=='OPTIX'
  scene.cycles.device='GPU'
  scene.cycles.samples=24 if args.web else 48
  scene.cycles.use_auto_tile=True
  scene.cycles.tile_size=512
 print('RENDER_START',state,scene.render.resolution_x,scene.cycles.samples,flush=True)
 bpy.ops.render.render(write_still=True)
 print('RENDER_DONE',state,flush=True)
