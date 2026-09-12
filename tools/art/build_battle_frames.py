"""Build Godot AtlasTexture/SpriteFrames metadata without modifying source image pixels.

All regions and foot offsets are reproducible from the original RGBA sheet.
Run with Python 3 + Pillow. The source sheet remains the authored image.
"""
import argparse
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
CANVAS = 384
BASELINE = 336
CLIPS = {
    "idle": ([0, 1, 0], [1.8, 0.5, 1.8], 3.0, True),
    "move": ([2, 0, 3, 1], [1.0, 0.35, 1.0, 0.35], 6.0, True),
    "attack": ([0, 4, 5, 6, 7, 0], [0.3, 0.7, 0.35, 0.4, 0.45, 0.3], 6.0, False),
    "cast": ([0, 8, 9, 9, 7, 0], [0.3, 0.7, 0.35, 0.4, 0.45, 0.3], 6.0, False),
    "hurt": ([10, 11, 0], [1, 1, 0.5], 10.0, False),
    "critical": ([12], [1], 2.0, True),
    "death": ([13, 14, 15], [0.8, 1, 1.2], 4.0, False),
}

def build(character):
    source = ROOT / f"assets/art/characters/{character}/battle_sheet.png"
    image = Image.open(source)
    if image.mode != "RGBA":
        raise ValueError("Sprite sheet must have real RGBA transparency")
    alpha = image.getchannel("A")
    histogram = alpha.histogram()
    if histogram[0] < image.width * image.height * 0.3:
        raise ValueError("Insufficient transparent area; reject baked backgrounds")
    records = []
    for index in range(16):
        col, row = index % 4, index // 4
        x0, x1 = round(col * image.width / 4), round((col + 1) * image.width / 4)
        y0, y1 = round(row * image.height / 4), round((row + 1) * image.height / 4)
        mask = alpha.crop((x0, y0, x1, y1)).point(lambda value: 255 if value >= 80 else 0)
        bounds = mask.getbbox()
        if bounds is None:
            raise ValueError(f"Empty pose {index}")
        left, top, right, bottom = bounds
        baseline = bottom
        # Cell center is the stable body pivot. Do not center extended fists or weapons.
        pivot = (x1 - x0) / 2
        left, top = max(0, left - 2), max(0, top - 2)
        right, bottom = min(x1 - x0, right + 2), min(y1 - y0, bottom + 2)
        width, height = right - left, bottom - top
        region = [x0 + left, y0 + top, width, height]
        margin = [CANVAS / 2 - (pivot - left), BASELINE - (baseline - top), CANVAS - width, CANVAS - height]
        if margin[0] < 0 or margin[1] < 0:
            raise ValueError(f"Pose {index} exceeds normalized canvas")
        records.append({"pose": index, "region": region, "margin": margin, "source_baseline": baseline})
    asset_path = source.relative_to(ROOT).as_posix()
    lines = ['[gd_resource type="Resource" load_steps=20 format=3]',
        '[ext_resource type="Script" path="res://game/content/battle_animation_set.gd" id="script"]',
        f'[ext_resource type="Texture2D" path="res://{asset_path}" id="sheet"]']
    for record in records:
        lines += [f'\n[sub_resource type="AtlasTexture" id="pose_{record["pose"]}"]',
            'atlas = ExtResource("sheet")',
            'region = Rect2(%s)' % ', '.join(map(str, record['region'])),
            'margin = Rect2(%s)' % ', '.join(map(str, record['margin'])),
            'filter_clip = true']
    animations = []
    for name, (poses, weights, speed, loop) in CLIPS.items():
        frames = ', '.join('{"duration": %s, "texture": SubResource("pose_%d")}' % (weight, pose)
                           for pose, weight in zip(poses, weights))
        animations.append('{"frames": [%s], "loop": %s, "name": &"%s", "speed": %s}' %
                          (frames, str(loop).lower(), name, speed))
    lines += ['\n[sub_resource type="SpriteFrames" id="frames"]', 'animations = [%s]' % ',\n'.join(animations),
        '\n[resource]', 'script = ExtResource("script")', 'frames = SubResource("frames")',
        'display_size = Vector2(128, 128)', 'anchor = Vector2(0.5, 0.875)',
        'impact_ratio = 0.4', 'flip_with_facing = true']
    output = ROOT / f"resources/content/animations/{character}.tres"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text('\n'.join(lines) + '\n', encoding='utf-8')
    source.with_name('battle_sheet.frames.json').write_text(json.dumps({
        'source': asset_path, 'source_size': image.size, 'canvas': [CANVAS, CANVAS],
        'anchor': [0.5, 0.875], 'transparent_pixels': histogram[0], 'poses': records,
        'clips': {name: {'poses': data[0], 'weights': data[1], 'fps': data[2]} for name, data in CLIPS.items()}},
        indent=2) + '\n', encoding='utf-8')
    print(character, '16 poses, 7 clips, transparent pixels:', histogram[0], '->', output)
    for entry in records: print(entry)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('character', choices=['guard', 'archer'])
    build(parser.parse_args().character)
