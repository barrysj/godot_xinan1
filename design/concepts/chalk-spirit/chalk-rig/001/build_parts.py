"""Build a throwaway cutout-rig prototype from the approved Chalk Spirit art."""

from __future__ import annotations

from collections import deque
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
SOURCE = ROOT / "assets/art/characters/chalk_spirit/locomotion_sheet.png"
METADATA = ROOT / "assets/art/characters/chalk_spirit/battle_animation.frames.json"
CANVAS = 384
ANCHOR = (192, 336)
LAUNCHER_PIVOT = (246, 191)


def components(mask: np.ndarray) -> list[dict]:
    height, width = mask.shape
    visited = np.zeros_like(mask, dtype=bool)
    found = []
    for start_y, start_x in zip(*np.nonzero(mask)):
        if visited[start_y, start_x]:
            continue
        queue = deque([(int(start_y), int(start_x))])
        visited[start_y, start_x] = True
        pixels = []
        while queue:
            y, x = queue.popleft()
            pixels.append((y, x))
            for next_y in range(max(0, y - 1), min(height, y + 2)):
                for next_x in range(max(0, x - 1), min(width, x + 2)):
                    if mask[next_y, next_x] and not visited[next_y, next_x]:
                        visited[next_y, next_x] = True
                        queue.append((next_y, next_x))
        ys = np.fromiter((pixel[0] for pixel in pixels), dtype=np.int32)
        xs = np.fromiter((pixel[1] for pixel in pixels), dtype=np.int32)
        found.append({
            "area": len(pixels),
            "bbox": [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1],
            "pixels": pixels,
        })
    return sorted(found, key=lambda item: item["area"], reverse=True)


def source_frame() -> Image.Image:
    metadata = json.loads(METADATA.read_text(encoding="utf-8"))
    record = metadata["poses"]["locomotion"][0]
    x, y, width, height = record["region"]
    atlas = Image.open(SOURCE).convert("RGBA")
    frame = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    frame.alpha_composite(
        atlas.crop((x, y, x + width, y + height)),
        (round(record["margin"][0]), round(record["margin"][1])),
    )
    return frame


def layer_from_mask(rgba: np.ndarray, mask: np.ndarray) -> Image.Image:
    layer = rgba.copy()
    layer[:, :, 3] = np.where(mask, rgba[:, :, 3], 0)
    return Image.fromarray(layer, "RGBA")


def bbox(mask: np.ndarray) -> list[int]:
    ys, xs = np.nonzero(mask)
    return [int(xs.min()), int(ys.min()), int(xs.max()) + 1, int(ys.max()) + 1]


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main() -> None:
    parts = HERE / "parts"
    review = HERE / "review"
    parts.mkdir(exist_ok=True)
    review.mkdir(exist_ok=True)
    frame = source_frame()
    frame.save(review / "source-frame.png")
    rgba = np.asarray(frame)
    found = components(rgba[:, :, 3] >= 80)
    palette = [
        (255, 95, 158, 255), (76, 214, 196, 255), (255, 205, 89, 255),
        (142, 120, 255, 255), (255, 135, 76, 255), (96, 178, 255, 255),
    ]
    component_map = np.zeros_like(rgba)
    report = []
    for index, item in enumerate(found):
        if item["area"] < 8:
            continue
        color = palette[index % len(palette)]
        for y, x in item["pixels"]:
            component_map[y, x] = color
        report.append({"index": index, "area": item["area"], "bbox": item["bbox"]})
    Image.fromarray(component_map, "RGBA").save(review / "component-map.png")

    alpha_mask = rgba[:, :, 3] >= 80
    launcher_shape = Image.new("1", (CANVAS, CANVAS), 0)
    ImageDraw.Draw(launcher_shape).polygon(
        # Start at the arm socket instead of the face edge.  The approved
        # painting connects these shapes, so a broad crop accidentally pulls
        # eye/shadow pixels into the moving launcher layer.
        [(245, 176), (260, 176), (330, 191), (330, 246), (252, 238), (244, 208)],
        fill=1,
    )
    launcher_mask = alpha_mask & np.asarray(launcher_shape, dtype=bool)
    orbiter_back_mask = np.zeros_like(alpha_mask)
    orbiter_top_mask = np.zeros_like(alpha_mask)
    for y, x in found[1]["pixels"]:
        orbiter_back_mask[y, x] = True
    for y, x in found[2]["pixels"]:
        orbiter_top_mask[y, x] = True
    yy, xx = np.indices(alpha_mask.shape)
    removed_dust_mask = alpha_mask & (yy >= 265)
    # Keep the painted shoulder socket on the body as an overlap flap.  Cutting
    # every launcher pixel out of the body exposes a background-coloured seam
    # as soon as the launcher rotates a few degrees.
    launcher_cut_mask = launcher_mask & ((xx >= 258) | (yy >= 194))
    body_mask = alpha_mask & ~launcher_cut_mask & ~orbiter_back_mask & ~orbiter_top_mask & ~removed_dust_mask

    masks = {
        "body": body_mask,
        "launcher": launcher_mask,
        "orbiter_back": orbiter_back_mask,
        "orbiter_top": orbiter_top_mask,
    }
    for name, mask in masks.items():
        layer_from_mask(rgba, mask).save(parts / f"{name}.png")

    dust_component = found[9]
    dust_mask = np.zeros_like(alpha_mask)
    for y, x in dust_component["pixels"]:
        dust_mask[y, x] = True
    dust_bounds = bbox(dust_mask)
    x0, y0, x1, y1 = dust_bounds
    dust = layer_from_mask(rgba, dust_mask).crop((x0, y0, x1, y1))
    dust.save(parts / "dust_particle.png")

    assembled = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
    for name in ("body", "launcher", "orbiter_back", "orbiter_top"):
        assembled.alpha_composite(Image.open(parts / f"{name}.png").convert("RGBA"))
    assembled.save(review / "assembled-rest.png")
    comparison = Image.new("RGBA", (CANVAS * 2, CANVAS), (31, 55, 52, 255))
    comparison.alpha_composite(frame, (0, 0))
    comparison.alpha_composite(assembled, (CANVAS, 0))
    ImageDraw.Draw(comparison).line((CANVAS, 0, CANVAS, CANVAS), fill=(255, 205, 89, 255), width=2)
    comparison.save(review / "rest-comparison.png")

    manifest = {
        "prototype": True,
        "source": SOURCE.relative_to(ROOT).as_posix(),
        "source_sha256": sha256(SOURCE),
        "canvas": [CANVAS, CANVAS],
        "anchor": list(ANCHOR),
        "launcher_pivot": list(LAUNCHER_PIVOT),
        "removed_dust_region_y": 265,
        "parts": {
            name: {"file": f"parts/{name}.png", "bbox": bbox(mask)}
            for name, mask in masks.items()
        },
        "dust_particle": {"file": "parts/dust_particle.png", "bbox": dust_bounds},
        "component_report": report,
    }
    (HERE / "rig_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    print("chalk rig parts:", ", ".join(masks))
    print("source:", manifest["source_sha256"])


if __name__ == "__main__":
    main()
