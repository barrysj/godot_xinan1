"""Build conservative bone + key-pose animation candidates for M1 allies.

The rigid rig moves the root and head only. Large weapon poses are whole-frame
key poses so the previous mesh-folding failure cannot recur in this prototype.
"""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

PROJECT = Path(__file__).resolve().parents[4]
ROOT = PROJECT / "design/concepts/characters"
CANVAS = 512
FEET_Y = 480
HEIGHT = 448
SHARED = Path(__file__).resolve().parent

ROLES = {
    "archer": {
        "source": ROOT / "archer/asset_001/source/idle-master.png",
        "attack": ROOT / "archer/asset_001/source/ranged-keypose.png",
        "head_cut": 111,
        "attack_shift_x": 23,
        "muzzle": (386, 99),
        "attack_name": "ranged",
        "effect": "pistol",
    },
    "archer-alt": {
        "source": ROOT / "archer-alt/asset_001/source/idle-master.png",
        "attack": ROOT / "archer-alt/asset_001/source/ranged-keypose.png",
        "head_cut": 111,
        "attack_shift_x": 23,
        "muzzle": (386, 99),
        "attack_name": "ranged",
        "effect": "pistol",
    },
    "striker": {
        "source": ROOT / "striker/asset_001/source/idle-master.png",
        "attack": ROOT / "striker/asset_001/source/melee-keypose.png",
        "head_cut": 111,
        "attack_shift_x": 0,
        "muzzle": (389, 201),
        "attack_name": "melee",
        "effect": "daggers",
    },
    "inventor": {
        "source": ROOT / "inventor/asset_001/source/idle-master.png",
        "attack": ROOT / "inventor/asset_001/source/idle-master.png",
        "head_cut": 113,
        "attack_shift_x": 0,
        "muzzle": (403, 228),
        "attack_name": "ranged",
        "effect": "railgun",
    },
    "healer": {
        "source": ROOT / "healer/asset_001/source/idle-master.png",
        "attack": ROOT / "healer/asset_001/source/idle-master.png",
        "head_cut": 150,
        "attack_shift_x": 0,
        "muzzle": (352, 278),
        "attack_name": "ranged",
        "effect": "healing",
    },
}


def normalize(source: Path, reference: dict | None = None, shift_x: int = 0) -> tuple[Image.Image, dict]:
    image = Image.open(source).convert("RGBA")
    alpha = np.asarray(image.getchannel("A"))
    box = Image.fromarray((alpha > 128).astype(np.uint8) * 255).getbbox()
    if box is None:
        raise ValueError(f"No subject in {source}")
    if reference is None:
        anchor_x = (box[0] + box[2]) / 2
        scale = HEIGHT / (box[3] - box[1])
    else:
        anchor_x = reference["anchor_x"]
        scale = reference["scale"]
    resized = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.LANCZOS)
    result = Image.new("RGBA", (CANVAS, CANVAS))
    left = round(CANVAS / 2 - anchor_x * scale + shift_x)
    top = round(FEET_Y - box[3] * scale)
    result.alpha_composite(resized, (left, top))
    info = {"source": str(source.relative_to(PROJECT)).replace("\\", "/"),
            "source_bbox": list(box), "anchor_x": anchor_x, "scale": scale,
            "placement": [left, top], "canvas": [CANVAS, CANVAS], "feet_y": FEET_Y}
    return result, info


def head_and_body(idle: Image.Image, cut: int) -> tuple[Image.Image, Image.Image]:
    data = np.asarray(idle, dtype=np.uint8)
    head = data.copy()
    body = data.copy()
    head[cut:, :, :] = 0
    body[:cut, :, :] = 0
    return Image.fromarray(head, "RGBA"), Image.fromarray(body, "RGBA")


def flash(aim: Image.Image, muzzle: tuple[int, int], effect: str, big: bool = False) -> Image.Image:
    result = aim.copy()
    layer = Image.new("RGBA", aim.size)
    draw = ImageDraw.Draw(layer)
    x, y = muzzle
    if effect == 'daggers':
        radius = 29 if big else 17
        draw.arc((x - radius, y - radius, x + radius, y + radius),
                 285, 55, fill=(250, 107, 255, 215), width=4 if big else 3)
        draw.ellipse((x - 3, y - 3, x + 3, y + 3), fill=(213, 251, 255, 190))
    elif effect == 'healing':
        radius = 23 if big else 15
        draw.ellipse((x - radius, y - radius, x + radius, y + radius),
                     outline=(103, 246, 202, 215), width=4 if big else 2)
        draw.line((x - 7, y, x + 7, y), fill=(220, 255, 235, 220), width=2)
        draw.line((x, y - 7, x, y + 7), fill=(220, 255, 235, 220), width=2)
    else:
        length = (24 if big else 12) if effect == 'railgun' else (48 if big else 26)
        draw.line((x, y, min(CANVAS - 10, x + length), y),
                  fill=(52, 225, 255, 220), width=5 if big else 3)
        draw.ellipse((x - 7, y - 7, x + 7, y + 7), fill=(225, 253, 255, 190))
        draw.line((x + 5, y - 9, x + 13, y + 9), fill=(75, 220, 255, 170), width=2)
    result.alpha_composite(layer)
    return result


def defeat_frames(sheet_path: Path) -> tuple[Image.Image, Image.Image, dict]:
    """Cut the two reviewed key poses into fixed-footprint game frames."""
    sheet = Image.open(sheet_path).convert("RGBA")
    if sheet.width != sheet.height * 2:
        raise ValueError(f"Expected two square transparent panels: {sheet_path}")
    poses = []
    placements = []
    for index, (height_limit, width_limit) in enumerate(((365, 460), (230, 480))):
        panel = sheet.crop((index * sheet.height, 0, (index + 1) * sheet.height, sheet.height))
        solid = panel.getchannel("A").point(lambda alpha: 255 if alpha > 100 else 0)
        box = solid.getbbox()
        if box is None:
            raise ValueError(f"Empty pose {index} in {sheet_path}")
        margin = 16
        crop_box = (max(0, box[0] - margin), max(0, box[1] - margin),
                    min(sheet.height, box[2] + margin), min(sheet.height, box[3] + margin))
        pose = panel.crop(crop_box)
        scale = min(width_limit / pose.width, height_limit / pose.height)
        size = (round(pose.width * scale), round(pose.height * scale))
        pose = pose.resize(size, Image.Resampling.LANCZOS)
        frame = Image.new("RGBA", (CANVAS, CANVAS))
        position = ((CANVAS - size[0]) // 2, FEET_Y - size[1])
        frame.alpha_composite(pose, position)
        poses.append(frame)
        placements.append({"crop": crop_box, "size": size, "position": position})
    return poses[0], poses[1], {"source": str(sheet_path.relative_to(PROJECT)).replace("\\", "/"),
                                "panels": placements}


def track(path: str, times: list[float], values: list[str], index: int) -> str:
    floats = ", ".join(f"{time:g}" for time in times)
    transitions = ", ".join("1" for _ in times)
    return (f'tracks/{index}/type = "value"\n'
            f'tracks/{index}/imported = false\n'
            f'tracks/{index}/enabled = true\n'
            f'tracks/{index}/path = NodePath("{path}")\n'
            f'tracks/{index}/interp = 1\n'
            f'tracks/{index}/loop_wrap = true\n'
            f'tracks/{index}/keys = {{\n'
            f'"times": PackedFloat32Array({floats}),\n'
            f'"transitions": PackedFloat32Array({transitions}),\n'
            f'"update": 0,\n'
            f'"values": [{", ".join(values)}]\n'
            f'}}\n')


def write_library() -> None:
    SHARED.mkdir(exist_ok=True)
    states = {
        "idle": (1.4, True, [0, .35, .7, 1.05, 1.4],
                 [0, -.018, 0, .018, 0], [(0, 0), (0, -2), (0, 0), (0, 1), (0, 0)]),
        "move": (.8, True, [0, .2, .4, .6, .8],
                 [0, -.025, 0, .025, 0], [(0, 0), (0, -7), (0, 0), (0, -7), (0, 0)]),
        "hurt": (.55, False, [0, .08, .22, .38, .55],
                 [0, .035, .09, .05, 0], [(0, 0), (-5, 0), (-14, 3), (-9, 1), (0, 0)]),
    }
    lines = ['[gd_resource type="AnimationLibrary" format=3]', '']
    for name, (length, loop, times, head, root) in states.items():
        lines.extend([f'[sub_resource type="Animation" id="{name}"]',
                      f'resource_name = "{name}"', f'length = {length}'])
        if loop:
            lines.append('loop_mode = 1')
        lines.append(track('Rig/Skeleton2D/RootBone/HeadBone:rotation', times,
                           [f'{angle:g}' for angle in head], 0))
        lines.append(track('Rig/Skeleton2D/RootBone:position', times,
                           [f'Vector2({x}, {y})' for x, y in root], 1))
    lines.extend(['[resource]', '_data = {'])
    lines.extend(f'&"{name}": SubResource("{name}"){"," if index < len(states)-1 else ""}'
                 for index, name in enumerate(states))
    lines.append('}')
    (SHARED / 'animations.tres').write_text('\n'.join(lines) + '\n', encoding='utf-8')


def scene(role: str, cut: int) -> str:
    base = f'res://design/concepts/characters/{role}/asset_001'
    pivot_y = cut - FEET_Y
    offset_y = CANVAS / 2 - cut
    return f'''[gd_scene load_steps=5 format=3]
[ext_resource type="Script" path="res://scenes/battle_demo/presentations/hybrid_presentation.gd" id="script"]
[ext_resource type="Texture2D" path="{base}/parts/body.png" id="body"]
[ext_resource type="Texture2D" path="{base}/parts/head.png" id="head"]
[ext_resource type="AnimationLibrary" path="{base}/animations.tres" id="library"]

[node name="Presentation" type="Node2D"]
visible = false
texture_filter = 4
script = ExtResource("script")
canvas_size = Vector2(512, 512)

[node name="Rig" type="Node2D" parent="."]

[node name="Skeleton2D" type="Skeleton2D" parent="Rig"]

[node name="RootBone" type="Bone2D" parent="Rig/Skeleton2D"]
rest = Transform2D(1, 0, 0, 1, 0, 0)
auto_calculate_length_and_angle = false
length = 1.0
bone_angle = 0.0

[node name="Body" type="Sprite2D" parent="Rig/Skeleton2D/RootBone"]
position = Vector2(0, -224)
texture = ExtResource("body")

[node name="HeadBone" type="Bone2D" parent="Rig/Skeleton2D/RootBone"]
position = Vector2(0, {pivot_y})
rest = Transform2D(1, 0, 0, 1, 0, {pivot_y})
auto_calculate_length_and_angle = false
length = 1.0
bone_angle = 0.0

[node name="Head" type="Sprite2D" parent="Rig/Skeleton2D/RootBone/HeadBone"]
position = Vector2(0, {offset_y:g})
texture = ExtResource("head")

[node name="AnimationPlayer" type="AnimationPlayer" parent="."]
callback_mode_process = 2
libraries/ = ExtResource("library")
'''


def clip_definitions(attack_name: str) -> dict:
    return {
        'idle': (['idle'], True, 8),
        'move': (['idle'], True, 8),
        attack_name: (['idle', 'aim', 'aim', 'shot', 'aim', 'idle'], False, 8),
        'cast': (['idle', 'aim', 'cast', 'cast', 'aim', 'idle'], False, 8),
        'hurt': (['idle'], False, 8),
        'critical': (['death_1'], True, 8),
        'death': (['death_2'], False, 4),
    }


def frame_resource(role: str, attack_name: str) -> str:
    base = f'res://design/concepts/characters/{role}/asset_001'
    textures = ('idle', 'aim', 'shot', 'cast', 'death_1', 'death_2')
    lines = [f'[gd_resource type="Resource" load_steps={len(textures) + 4} format=3]',
             '[ext_resource type="Script" path="res://game/content/battle_animation_set.gd" id="script"]']
    lines.extend(f'[ext_resource type="Texture2D" path="{base}/frames/{name}.png" id="{name}"]'
                 for name in textures)
    lines.append(f'[ext_resource type="PackedScene" path="{base}/presentation.tscn" id="presentation"]')
    lines.append(f'[ext_resource type="AnimationLibrary" path="{base}/animations.tres" id="library"]')
    clips = clip_definitions(attack_name)
    entries = []
    for name, (frames, loop, speed) in clips.items():
        items = ', '.join('{"duration": 1.0, "texture": ExtResource("' + frame + '")}' for frame in frames)
        entries.append('{"frames": [' + items + '], "loop": ' + str(loop).lower() +
                       ', "name": &"' + name + '", "speed": ' + str(speed) + '}')
    lines.extend(['', '[sub_resource type="SpriteFrames" id="frames"]',
                  'animations = [' + ',\n'.join(entries) + ']', '', '[resource]',
                  'script = ExtResource("script")', 'frames = SubResource("frames")',
                  'display_size = Vector2(128, 128)', 'anchor = Vector2(0.5, 0.9375)',
                  'impact_ratio = 0.45', 'flip_with_facing = true',
                  'presentation_scene = ExtResource("presentation")',
                  'animation_library = ExtResource("library")'])
    return '\n'.join(lines) + '\n'


def build(role: str) -> None:
    config = ROLES[role]
    target = ROOT / role / 'asset_001'
    (target / 'parts').mkdir(parents=True, exist_ok=True)
    (target / 'frames').mkdir(exist_ok=True)
    (target / 'review').mkdir(exist_ok=True)
    idle, idle_info = normalize(config['source'])
    aim, aim_info = normalize(config['attack'], idle_info, config['attack_shift_x'])
    head, body = head_and_body(idle, config['head_cut'])
    head.save(target / 'parts/head.png')
    body.save(target / 'parts/body.png')
    idle.save(target / 'frames/idle.png')
    aim.save(target / 'frames/aim.png')
    flash(aim, config['muzzle'], config['effect']).save(target / 'frames/shot.png')
    flash(aim, config['muzzle'], config['effect'], True).save(target / 'frames/cast.png')
    dying, gone, defeat_info = defeat_frames(target / 'source/critical-death-sheet.png')
    dying.save(target / 'frames/death_1.png')
    gone.save(target / 'frames/death_2.png')
    (target / 'presentation.tscn').write_text(scene(role, config['head_cut']), encoding='utf-8')
    (target / 'battle_animation.tres').write_text(frame_resource(role, config['attack_name']), encoding='utf-8')
    (target / 'battle_animation.frames.json').write_text(json.dumps({
        'method': 'rigid RootBone and HeadBone for idle/move/hurt; key pose frames for attack/cast/critical/death',
        'idle': idle_info, 'attack': aim_info, 'head_cut_y': config['head_cut'],
        'defeat': defeat_info,
        'muzzle': config['muzzle'], 'effect': config['effect'], 'attack_name': config['attack_name'],
        'canvas': [CANVAS, CANVAS], 'display_size': [128, 128],
        'clips': {name: {'poses': frames, 'fps': speed, 'loop': loop}
                  for name, (frames, loop, speed) in clip_definitions(config['attack_name']).items()},
    }, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    write_library()
    (target / 'animations.tres').write_bytes((SHARED / 'animations.tres').read_bytes())
    print(f'Built {role} bone + key-pose candidate: {target}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--role', choices=ROLES, required=True)
    build(parser.parse_args().role)
