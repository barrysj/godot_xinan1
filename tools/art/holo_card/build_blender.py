"""Run the fixed RuiC builder, then adapt its 2:3 card to our 8:7 photo frame.

Blender is authoring-only. Godot consumes the original photograph and native shader.
Call with a task-local BLENDER_USER_CONFIG to preserve the user's preferences.
"""
from pathlib import Path
import json
import math
import runpy
import sys
import bpy

args = sys.argv[sys.argv.index('--') + 1:]
root = Path(args[0]).resolve()
upstream = Path(__file__).parent / 'upstream'
bpy.context.preferences.filepaths.save_version = 0
sys.argv = [str(upstream / 'build_card.py'), '--', str(root), '--skip-render']
runpy.run_path(str(upstream / 'build_card.py'), run_name='__main__')
scene = bpy.context.scene
pivot = bpy.data.objects['转卡控制 · 播放时间线预览']
pivot.animation_data_clear()
pivot.rotation_euler = (0, 0, 0)
pivot.scale.x = (1600 / 1400) / (6.3 / 9.45)
# Keep the source photo neutral in Blender; foil remains on the frame.
tree = bpy.data.materials['01 · 主体 + 背景 / 核心合成'].node_tree
mix = tree.nodes['主体 Alpha 叠加背景']
photo = tree.nodes['主体角色 PNG · 换卡替换这里']
neutral = tree.nodes.new('ShaderNodeEmission')
neutral.name = '原照保真 / unlit photo'
neutral.inputs['Strength'].default_value = 1.0
tree.links.new(photo.outputs['Color'], neutral.inputs['Color'])
tree.links.new(neutral.outputs[0], mix.inputs[2])
scene.view_settings.view_transform = 'Standard'
scene.view_settings.look = 'None'
scene.camera.data.ortho_scale = 13.2
scene.render.resolution_x = 1440
scene.render.resolution_y = 1260
scene.cycles.samples = 16
scene.render.film_transparent = True
scene['素材来源'] = 'User photograph, unchanged original retained outside this authoring package; no AI redraw.'
scene['Godot说明'] = 'Authoring reference only. Runtime uses native CanvasItem shader and Resource.'
# Neutral color space and ink/foil are adaptations, not a pixel-identical port.
bpy.ops.wm.save_as_mainfile(filepath=str(root / 'card.blend'))
for label, angle in [('front', 0), ('left', -10), ('right', 10)]:
    pivot.rotation_euler.z = math.radians(angle)
    scene.render.filepath = str(root / 'renders' / (label + '.png'))
    bpy.ops.render.render(write_still=True)
pivot.rotation_euler = (0, 0, 0)
# Export uses a temporary in-memory material replacement, leaving .blend intact.
sys.argv = [str(upstream / 'export_web.py'), '--', str(root)]
runpy.run_path(str(upstream / 'export_web.py'), run_name='__main__')
(root / 'adapter-report.json').write_text(json.dumps({
    'blender': bpy.app.version_string, 'upstream_commit': 'ae25b5d02996eb5f5eb2540b91c26fe20f484d55',
    'card_aspect': [8, 7], 'source_preserved': True,
    'runtime': 'Godot native CanvasItem, does not load GLB or blend',
    'render_views': ['front', 'left', 'right'], 'browser_tested': False
}, ensure_ascii=False, indent=2), encoding='utf-8')
print('HOLO_BLENDER_COMPLETE')
