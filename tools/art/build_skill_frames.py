"""Create atlas metadata for the original authored VFX sheet; never alter PNG pixels."""
import json
from pathlib import Path
from PIL import Image
ROOT = Path(__file__).resolve().parents[2]
source = ROOT / "assets/art/effects/guard_shield/burst_sheet.png"
image = Image.open(source)
assert image.mode == "RGBA" and image.getchannel("A").histogram()[0] > image.width * image.height * 0.3
regions = []
lines = ['[gd_resource type="Resource" load_steps=20 format=3]',
    '[ext_resource type="Script" path="res://game/content/battle_effect_set.gd" id="script"]',
    '[ext_resource type="Texture2D" path="res://assets/art/effects/guard_shield/burst_sheet.png" id="sheet"]']
for i in range(16):
    col, row = i % 4, i // 4
    x, y = round(col * image.width / 4), round(row * image.height / 4)
    w, h = round((col + 1) * image.width / 4) - x, round((row + 1) * image.height / 4) - y
    regions.append([x, y, w, h])
    lines += [f'\n[sub_resource type="AtlasTexture" id="frame_{i}"]', 'atlas = ExtResource("sheet")',
        f'region = Rect2({x}, {y}, {w}, {h})', 'filter_clip = true']
frames = ', '.join('{"duration": 1.0, "texture": SubResource("frame_%d")}' % i for i in range(16))
lines += ['\n[sub_resource type="SpriteFrames" id="frames"]',
    'animations = [{"frames": [%s], "loop": false, "name": &"burst", "speed": 24.0}]' % frames,
    '\n[resource]', 'script = ExtResource("script")', 'frames = SubResource("frames")',
    'display_size = Vector2(144, 144)', 'offset = Vector2(0, -44)']
output = ROOT / "resources/content/animations/guard_shield.tres"
output.write_text('\n'.join(lines) + '\n', encoding='utf-8')
source.with_name('burst_sheet.frames.json').write_text(json.dumps({
    'source_size': image.size, 'regions': regions, 'fps': 24, 'duration': 16 / 24,
    'transparent_pixels': image.getchannel("A").histogram()[0]
}, indent=2) + '\n', encoding='utf-8')
print("GUARD_SHIELD 16 distinct frames at 24 fps ->", output)

