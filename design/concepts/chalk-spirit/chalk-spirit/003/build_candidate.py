"""Build Chalk Spirit candidate 003 from three generated RGB animation sheets.

The generator baked a neutral checkerboard into the RGB sources. This script
extracts only the border-connected neutral background, preserves the authored
poses, validates per-cell safe margins, and writes reproducible Godot atlas
metadata without changing the source RGB files.
"""

from __future__ import annotations

from collections import deque
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image


ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
CANVAS = 352
BASELINE = 308
PAD = 2
SAFE_MARGIN = 2
PORTRAIT_REGION = [70, 110, 250, 250]

SHEETS = {
    "locomotion": {"rows": 3, "cols": 4},
    "combat": {"rows": 4, "cols": 4},
    "reaction": {"rows": 4, "cols": 4},
}

CLIPS = {
    "idle": (["locomotion:0", "locomotion:1", "locomotion:2", "locomotion:3"], 6.0, True),
    "move": ([f"locomotion:{index}" for index in range(4, 12)], 10.0, True),
    "attack": ([f"combat:{index}" for index in range(0, 8)], 12.0, False),
    "cast": ([f"combat:{index}" for index in range(8, 16)], 12.0, False),
    "hurt": ([f"reaction:{index}" for index in range(0, 4)], 12.0, False),
    "critical": ([f"reaction:{index}" for index in range(4, 8)], 6.0, True),
    "death": ([f"reaction:{index}" for index in range(8, 16)], 8.0, False),
}


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def border_connected_background(rgb: np.ndarray) -> np.ndarray:
    """Return pixels connected to the border that match the neutral checker."""
    # Use 32-bit channels: the weighted luma sum exceeds signed int16 at 255.
    values = rgb.astype(np.int32)
    spread = values.max(axis=2) - values.min(axis=2)
    luma = (54 * values[:, :, 0] + 183 * values[:, :, 1] + 19 * values[:, :, 2]) >> 8
    candidate = (spread <= 12) & (luma >= 165)
    height, width = candidate.shape
    outside = np.zeros((height, width), dtype=bool)
    queue: deque[tuple[int, int]] = deque()

    for x in range(width):
        if candidate[0, x]:
            outside[0, x] = True
            queue.append((0, x))
        if candidate[height - 1, x] and not outside[height - 1, x]:
            outside[height - 1, x] = True
            queue.append((height - 1, x))
    for y in range(height):
        if candidate[y, 0] and not outside[y, 0]:
            outside[y, 0] = True
            queue.append((y, 0))
        if candidate[y, width - 1] and not outside[y, width - 1]:
            outside[y, width - 1] = True
            queue.append((y, width - 1))

    while queue:
        y, x = queue.popleft()
        for next_y, next_x in ((y - 1, x), (y + 1, x), (y, x - 1), (y, x + 1)):
            if 0 <= next_y < height and 0 <= next_x < width:
                if candidate[next_y, next_x] and not outside[next_y, next_x]:
                    outside[next_y, next_x] = True
                    queue.append((next_y, next_x))
    return outside


def gutter_boundary(profile: np.ndarray, target: int, radius: int) -> int:
    """Choose the middle of the widest transparent run near a nominal split."""
    lower = max(1, target - radius)
    upper = min(len(profile) - 1, target + radius)
    zeroes = np.flatnonzero(profile[lower:upper] == 0) + lower
    runs: list[tuple[int, int]] = []
    if len(zeroes):
        start = previous = int(zeroes[0])
        for value in zeroes[1:]:
            value = int(value)
            if value != previous + 1:
                runs.append((start, previous + 1))
                start = value
            previous = value
        runs.append((start, previous + 1))
    if runs:
        start, end = max(
            runs,
            key=lambda run: (run[1] - run[0], -abs((run[0] + run[1]) / 2 - target)),
        )
        return round((start + end) / 2)
    return int(lower + np.argmin(profile[lower:upper]))


def row_boundaries(mask: np.ndarray, rows: int) -> list[int]:
    height = mask.shape[0]
    profile = mask.sum(axis=1)
    radius = round(height / rows * 0.22)
    return [0] + [
        gutter_boundary(profile, round(index * height / rows), radius)
        for index in range(1, rows)
    ] + [height]


def column_boundaries(mask: np.ndarray, cols: int) -> list[int]:
    width = mask.shape[1]
    profile = mask.sum(axis=0)
    radius = round(width / cols * 0.22)
    return [0] + [
        gutter_boundary(profile, round(index * width / cols), radius)
        for index in range(1, cols)
    ] + [width]


def process_sheet(name: str, rows: int, cols: int) -> tuple[dict, list[dict]]:
    source = HERE / f"{name}_sheet_source_rgb.png"
    output = HERE / f"{name}_sheet.png"
    image = Image.open(source).convert("RGB")
    rgb = np.asarray(image)
    outside = border_connected_background(rgb)
    alpha = np.where(outside, 0, 255).astype(np.uint8)
    rgba = np.dstack((rgb, alpha))
    Image.fromarray(rgba, "RGBA").save(output)

    records: list[dict] = []
    mask = alpha >= 80
    y_boundaries = row_boundaries(mask, rows)
    x_boundaries_by_row: list[list[int]] = []
    for index in range(rows * cols):
        col, row = index % cols, index // cols
        y0, y1 = y_boundaries[row], y_boundaries[row + 1]
        if col == 0:
            x_boundaries_by_row.append(column_boundaries(mask[y0:y1, :], cols))
        x_boundaries = x_boundaries_by_row[row]
        x0, x1 = x_boundaries[col], x_boundaries[col + 1]
        cell_alpha = alpha[y0:y1, x0:x1]
        ys, xs = np.nonzero(cell_alpha >= 80)
        if len(xs) == 0:
            raise ValueError(f"Empty pose {name}:{index}")
        left_raw, right_raw = int(xs.min()), int(xs.max()) + 1
        top_raw, bottom_raw = int(ys.min()), int(ys.max()) + 1
        edge_margin = [left_raw, top_raw, (x1 - x0) - right_raw, (y1 - y0) - bottom_raw]
        if min(edge_margin) < SAFE_MARGIN:
            raise ValueError(f"Unsafe cell edge margin for {name}:{index}: {edge_margin}")

        left, top = max(0, left_raw - PAD), max(0, top_raw - PAD)
        right = min(x1 - x0, right_raw + PAD)
        bottom = min(y1 - y0, bottom_raw + PAD)
        width, height = right - left, bottom - top
        if width > CANVAS or height > CANVAS:
            raise ValueError(f"Pose {name}:{index} exceeds {CANVAS}px canvas: {width}x{height}")
        pivot = (x1 - x0) / 2
        margin_left = CANVAS / 2 - (pivot - left)
        margin_top = BASELINE - (bottom_raw - top)
        if margin_left < 0 or margin_top < 0:
            raise ValueError(
                f"Negative normalized margin for {name}:{index}: "
                f"region={width}x{height}, left={margin_left}, top={margin_top}, bounds={[left_raw, top_raw, right_raw, bottom_raw]}"
            )
        records.append({
            "pose": f"{name}:{index}",
            "region": [x0 + left, y0 + top, width, height],
            "margin": [margin_left, margin_top, CANVAS - width, CANVAS - height],
            "cell_edge_margin": edge_margin,
            "source_baseline": bottom_raw,
        })

    summary = {
        "source": source.relative_to(ROOT).as_posix(),
        "output": output.relative_to(ROOT).as_posix(),
        "source_size": list(image.size),
        "grid": [cols, rows],
        "row_boundaries": y_boundaries,
        "column_boundaries_by_row": x_boundaries_by_row,
        "transparent_pixels": int((alpha == 0).sum()),
        "source_sha256": sha256(source),
        "output_sha256": sha256(output),
    }
    return summary, records


def godot_resource(all_records: dict[str, list[dict]]) -> str:
    lines = [
        '[gd_resource type="Resource" load_steps=50 format=3]',
        '[ext_resource type="Script" path="res://game/content/battle_animation_set.gd" id="script"]',
    ]
    for name in SHEETS:
        path = (HERE / f"{name}_sheet.png").relative_to(ROOT).as_posix()
        lines.append(f'[ext_resource type="Texture2D" path="res://{path}" id="{name}"]')

    for name, records in all_records.items():
        for index, record in enumerate(records):
            resource_id = f"{name}_{index}"
            lines.extend([
                f'\n[sub_resource type="AtlasTexture" id="{resource_id}"]',
                f'atlas = ExtResource("{name}")',
                'region = Rect2(%s)' % ', '.join(map(str, record["region"])),
                'margin = Rect2(%s)' % ', '.join(map(str, record["margin"])),
                'filter_clip = true',
            ])

    animations = []
    for clip, (poses, speed, loop) in CLIPS.items():
        frames = []
        for pose in poses:
            name, index = pose.split(":")
            frames.append('{"duration": 1.0, "texture": SubResource("%s_%s")}' % (name, index))
        animations.append('{"frames": [%s], "loop": %s, "name": &"%s", "speed": %s}' % (
            ', '.join(frames), str(loop).lower(), clip, speed,
        ))
    lines.extend([
        '\n[sub_resource type="SpriteFrames" id="frames"]',
        'animations = [%s]' % ',\n'.join(animations),
        '\n[resource]',
        'script = ExtResource("script")',
        'frames = SubResource("frames")',
        'display_size = Vector2(128, 128)',
        'anchor = Vector2(0.5, 0.875)',
        'impact_ratio = 0.625',
        'flip_with_facing = true',
        'launch_offset = Vector2(50, -52)',
        'hit_offset = Vector2(0, -42)',
    ])
    return "\n".join(lines) + "\n"


def write_gif_previews(all_records: dict[str, list[dict]]) -> None:
    review = HERE / "review"
    review.mkdir(exist_ok=True)
    images = {
        name: Image.open(HERE / f"{name}_sheet.png").convert("RGBA")
        for name in SHEETS
    }
    record_lookup = {
        record["pose"]: record
        for records in all_records.values()
        for record in records
    }
    for clip in ("move", "attack", "cast", "death"):
        poses, speed, _loop = CLIPS[clip]
        frames = []
        for pose in poses:
            sheet_name, _index = pose.split(":")
            record = record_lookup[pose]
            x, y, width, height = record["region"]
            crop = images[sheet_name].crop((x, y, x + width, y + height))
            canvas = Image.new("RGBA", (CANVAS, CANVAS), (31, 55, 52, 255))
            margin_x, margin_y = round(record["margin"][0]), round(record["margin"][1])
            canvas.alpha_composite(crop, (margin_x, margin_y))
            frames.append(canvas.convert("P", palette=Image.Palette.ADAPTIVE, colors=255))
        frame_ms = round(1000 / speed)
        frames[0].save(
            review / f"{clip}-preview.gif",
            save_all=True,
            append_images=frames[1:],
            duration=[frame_ms] * (len(frames) - 1) + [max(frame_ms, 350)],
            loop=0,
            disposal=2,
        )


def write_portrait_preview() -> dict:
    x, y, width, height = PORTRAIT_REGION
    source = Image.open(HERE / "locomotion_sheet.png").convert("RGBA")
    portrait = source.crop((x, y, x + width, y + height))
    output = HERE / "review" / "portrait-preview.png"
    output.parent.mkdir(exist_ok=True)
    portrait.save(output)
    return {
        "sheet": "locomotion",
        "region": PORTRAIT_REGION,
        "preview": output.relative_to(ROOT).as_posix(),
        "sha256": sha256(output),
    }


def main() -> None:
    sheets = {}
    poses = {}
    for name, layout in SHEETS.items():
        summary, records = process_sheet(name, layout["rows"], layout["cols"])
        sheets[name] = summary
        poses[name] = records

    portrait = write_portrait_preview()
    metadata = {
        "version": "003",
        "canvas": [CANVAS, CANVAS],
        "anchor": [0.5, 0.875],
        "portrait": portrait,
        "sheets": sheets,
        "poses": poses,
        "clips": {
            name: {"poses": values[0], "fps": values[1], "loop": values[2]}
            for name, values in CLIPS.items()
        },
    }
    (HERE / "battle_animation.frames.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    (HERE / "battle_animation.tres").write_text(godot_resource(poses), encoding="utf-8")
    write_gif_previews(poses)
    print("candidate 003: 44 poses, 7 clips")
    for name, summary in sheets.items():
        print(name, summary["grid"], "transparent", summary["transparent_pixels"], summary["output_sha256"])


if __name__ == "__main__":
    main()
