"""Small deterministic color-mask helpers for the retained Guard 008."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


def smoothstep(value: np.ndarray, low: float, high: float) -> np.ndarray:
    t = np.clip((value - low) / (high - low), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def skin_seed(rgba: Image.Image) -> Image.Image:
    rgb = np.asarray(rgba.convert("RGB"), dtype=np.int16)
    alpha = np.asarray(rgba.getchannel("A"), dtype=np.uint8)
    red, green, blue = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    y = np.arange(rgb.shape[0])[:, None]
    likely = ((alpha >= 160) & (y >= 54) & (y < 320) &
              (red >= 168) & (green >= 126) & (blue >= 96) &
              (red - green >= 12) & (red - green <= 60) &
              (green - blue >= 3) & (green - blue <= 45) &
              (red - blue >= 24) & (red - blue <= 92))
    seed = Image.fromarray((likely * 255).astype(np.uint8), "L")
    return seed.filter(ImageFilter.MedianFilter(size=3))


def grade_skin(source: Image.Image, delta: list[float]) -> tuple[Image.Image, Image.Image, float]:
    seed = skin_seed(source)
    rgb = np.asarray(source.convert("RGB"), dtype=np.int16)
    red, green, blue = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    relaxed = ((red >= 145) & (green >= 105) & (blue >= 82) &
               (red - green >= 9) & (red - green <= 70) &
               (green - blue >= 0) & (green - blue <= 55) &
               (red - blue >= 18) & (red - blue <= 105))
    dilated = seed.filter(ImageFilter.MaxFilter(size=7))
    expanded = np.asarray(dilated, dtype=np.float32) * relaxed
    matte = Image.fromarray(expanded.astype(np.uint8), "L").filter(
        ImageFilter.GaussianBlur(radius=1.0))
    weight = np.asarray(matte, dtype=np.float32) / 255.0
    weight *= np.asarray(source.getchannel("A"), dtype=np.float32) / 255.0
    graded = np.asarray(source, dtype=np.float32).copy()
    graded[..., :3] = np.clip(graded[..., :3] + weight[..., None] * np.asarray(delta), 0, 255)
    output = Image.fromarray(graded.astype(np.uint8), "RGBA")
    return output, matte, float(weight.sum())


def face_median(frame: Image.Image) -> np.ndarray:
    rgba = np.asarray(frame.convert("RGBA"))
    seed = np.asarray(skin_seed(frame), dtype=np.uint8) >= 200
    ys, xs = np.indices(seed.shape)
    face = seed & (ys < 180) & (xs > 420) & (xs < 700)
    if face.sum() < 400:
        raise ValueError(f"Not enough visible face pixels: {face.sum()}")
    return np.median(rgba[face, :3], axis=0)


def contact_sheet(frames: list[Image.Image], labels: list[str], path: Path) -> None:
    sheet = Image.new("RGB", (1280, 1080), "#222636")
    draw = ImageDraw.Draw(sheet)
    for index, (frame, label) in enumerate(zip(frames, labels)):
        x, y = index % 4 * 320, index // 4 * 180
        tile = Image.new("RGBA", (320, 160), "#eee9dd")
        tile.alpha_composite(frame.resize((320, 160), Image.Resampling.LANCZOS))
        sheet.paste(tile.convert("RGB"), (x, y + 20))
        draw.text((x + 8, y + 3), label, fill="white")
    sheet.save(path)
