import bpy,sys
from pathlib import Path
p=Path.cwd()/'design/concepts/environments/campus-map/campus-map/tmp_007'
(p/'desktop').mkdir(exist_ok=True)
for state in ['day','night','anomaly']:
 bpy.ops.wm.open_mainfile(filepath=str(p/(state+'.blend')))
 scene=bpy.context.scene;scene.render.resolution_x=7680;scene.render.resolution_y=3600;scene.render.resolution_percentage=100;scene.cycles.samples=48
 prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
 for d in prefs.devices:d.use=d.type=='OPTIX'
 scene.cycles.device='GPU';scene.render.filepath=str(p/'desktop'/(state+'.png'))
 print('DESKTOP_RENDER_START',state,flush=True);bpy.ops.render.render(write_still=True);print('DESKTOP_RENDER_DONE',state,flush=True)
