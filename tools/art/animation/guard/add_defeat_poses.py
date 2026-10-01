"""Rebuild distinct critical and death stills for retained Guard 008."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[4] / "design/concepts/characters"
RESOURCE_ROOT = "res://design/concepts/characters/guard"
TARGETS = {"008": (1024, 600, 450, 700, 275)}
FEET_Y = 485


def extract_stills(sheet_path: Path, version: str) -> None:
    canvas_width, critical_width, critical_height, death_width, death_height = TARGETS[version]
    sheet = Image.open(sheet_path).convert("RGBA")
    if sheet.width != sheet.height * 2:
        raise ValueError(f"Expected two square panels: {sheet_path}")
    out = ROOT / "guard" / ("asset_" + version) / "frames"
    out.mkdir(exist_ok=True)
    for index, name, width_limit, height_limit in (
        (0, "critical", critical_width, critical_height),
        (1, "death", death_width, death_height),
    ):
        side = sheet.height
        panel = sheet.crop((index * side, 0, (index + 1) * side, side))
        alpha = panel.getchannel("A").point(lambda value: 255 if value > 100 else 0)
        box = alpha.getbbox()
        if box is None:
            raise ValueError(f"Empty {name} pose in {sheet_path}")
        margin = 8
        crop = panel.crop((max(0, box[0] - margin), max(0, box[1] - margin),
                           min(side, box[2] + margin), min(side, box[3] + margin)))
        scale = min(width_limit / crop.width, height_limit / crop.height)
        size = (round(crop.width * scale), round(crop.height * scale))
        pose = crop.resize(size, Image.Resampling.LANCZOS)
        frame = Image.new("RGBA", (canvas_width, 512))
        frame.alpha_composite(pose, ((canvas_width - size[0]) // 2, FEET_Y - size[1]))
        frame.save(out / f"{name}.png")


def update_resource(version: str) -> None:
    path = ROOT / "guard" / ("asset_" + version) / "battle_animation.tres"
    source = path.read_text(encoding="utf-8")
    fresh = 'id="critical_pose"' not in source
    if fresh:
        source, count = re.subn(r"load_steps=(\d+)", lambda m: f"load_steps={int(m[1]) + 2}", source, count=1)
        if count != 1:
            raise ValueError(f"Missing load_steps in {path}")
        resources = "".join(
            f'[ext_resource type="Texture2D" path="{RESOURCE_ROOT}/asset_{version}/frames/{name}.png" id="{name}_pose"]\n'
            for name in ("critical", "death")
        )
        source = source.replace('[sub_resource type="SpriteFrames" id="frames"]',
                                resources + '\n[sub_resource type="SpriteFrames" id="frames"]', 1)
    lines = source.splitlines()
    critical_lines = [i for i, line in enumerate(lines) if '"name": &"critical"' in line]
    if len(critical_lines) != 1:
        raise ValueError(f"Expected one critical clip in {path}")
    index = critical_lines[0]
    if not lines[index].endswith(("]", ",")):
        raise ValueError(f"Expected critical clip before death in {path}")
    speed_match = re.search(r'"speed": ([\d.]+)\}[\],]$', lines[index])
    if not speed_match:
        raise ValueError(f"Cannot read critical speed in {path}")
    lines[index] = (f'{{"frames": [{{"duration": 1.0, "texture": ExtResource("critical_pose")}}], '
                    '"loop": true, "name": &"critical", "speed": 4},')
    death_line = ('{"frames": [{"duration": 1.0, "texture": ExtResource("death_pose")}], '
                  '"loop": false, "name": &"death", "speed": 4}]')
    if index + 1 < len(lines) and '"name": &"death"' in lines[index + 1]:
        lines[index + 1] = death_line
    else:
        lines.insert(index + 1, death_line)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def update_metadata(version: str) -> None:
    path = ROOT / "guard" / ("asset_" + version) / "battle_animation.frames.json"
    metadata = json.loads(path.read_text(encoding="utf-8"))
    metadata["clips"]["critical"] = {"poses": ["critical"], "fps": 4, "loop": True}
    metadata["clips"]["death"] = {"poses": ["death"], "fps": 4, "loop": False}
    metadata["defeat_source"] = "source/critical-death-sheet.png"
    path.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def apply_to_version(version: str) -> None:
    if version not in TARGETS:
        raise ValueError(version)
    sheet = ROOT / "guard" / ("asset_" + version) / "source" / "critical-death-sheet.png"
    if not sheet.is_file():
        raise FileNotFoundError(sheet)
    extract_stills(sheet, version)
    update_resource(version)
    update_metadata(version)
    print(f"Guard {version}: critical and death stills ready")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("version", choices=TARGETS)
    apply_to_version(parser.parse_args().version)
