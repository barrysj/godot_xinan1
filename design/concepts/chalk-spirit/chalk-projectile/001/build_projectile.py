"""Build the lightweight Chalk Spirit projectile candidate 001."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image


HERE = Path(__file__).resolve().parent
ROOT = Path(__file__).resolve().parents[5]
SOURCE = HERE / "projectile_source_rgba.png"
OUTPUT = HERE / "projectile.png"
RESOURCE = HERE / "chalk_projectile.tres"
CANVAS = (192, 96)
CONTENT_LIMIT = (168, 64)
DISPLAY_SIZE = (32, 16)
ALPHA_THRESHOLD = 8


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    rgba = np.asarray(source).copy()
    rgba[rgba[:, :, 3] < ALPHA_THRESHOLD] = 0
    alpha = rgba[:, :, 3]
    ys, xs = np.nonzero(alpha >= ALPHA_THRESHOLD)
    if len(xs) == 0:
        raise ValueError("Projectile source is empty")
    source_bbox = [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1]
    crop = Image.fromarray(rgba, "RGBA").crop(tuple(source_bbox))
    scale = min(CONTENT_LIMIT[0] / crop.width, CONTENT_LIMIT[1] / crop.height)
    size = (round(crop.width * scale), round(crop.height * scale))
    crop = crop.resize(size, Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    position = ((CANVAS[0] - size[0]) // 2, (CANVAS[1] - size[1]) // 2)
    canvas.alpha_composite(crop, position)
    canvas.save(OUTPUT)

    preview = Image.new("RGBA", (768, 288), (31, 55, 52, 255))
    preview.alpha_composite(canvas.resize((576, 288), Image.Resampling.NEAREST), (96, 0))
    preview.alpha_composite(canvas.resize(DISPLAY_SIZE, Image.Resampling.LANCZOS), (48, 244))
    preview.save(HERE / "review" / "projectile-preview.png")

    RESOURCE.write_text(
        """[gd_resource type="Resource" script_class="BattleProjectileStyle" load_steps=3 format=3]

[ext_resource type="Script" path="res://game/content/battle_projectile_style.gd" id="script"]
[ext_resource type="Texture2D" path="res://design/concepts/chalk-spirit/chalk-projectile/001/projectile.png" id="texture"]

[resource]
script = ExtResource("script")
texture = ExtResource("texture")
display_size = Vector2(32, 16)
anchor = Vector2(0.5, 0.5)
trail_gap = 2.0
""",
        encoding="utf-8",
    )
    metadata = {
        "version": "001",
        "source": SOURCE.relative_to(ROOT).as_posix(),
        "output": OUTPUT.relative_to(ROOT).as_posix(),
        "source_size": list(source.size),
        "source_bbox": source_bbox,
        "canvas": list(CANVAS),
        "content_size": list(size),
        "display_size": list(DISPLAY_SIZE),
        "alpha_threshold": ALPHA_THRESHOLD,
        "source_sha256": sha256(SOURCE),
        "output_sha256": sha256(OUTPUT),
    }
    (HERE / "projectile.metadata.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print("chalk projectile 001", metadata)


if __name__ == "__main__":
    main()
