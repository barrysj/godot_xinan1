"""Rebuild Guard 008 melee colors from its retained pre-neutral source frames.

The source poses, alpha, timing and resource layout remain unchanged. All
runtime textures and source frames live in 008, independent of old candidates.
"""

from __future__ import annotations

import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

from guard_008_palette_helpers import contact_sheet, face_median, grade_skin, smoothstep

ROOT = Path(__file__).resolve().parents[4] / "design/concepts/characters"
OUT = ROOT / "guard/asset_008"
SOURCE = OUT / "source/pre-neutral-frames"
IDLE = OUT / "frames/idle_00.png"
COUNT = 24


def neutral_grade(frame: Image.Image) -> Image.Image:
    rgba = np.asarray(frame.convert("RGBA"), dtype=np.float32).copy()
    red, green, blue = rgba[..., 0], rgba[..., 1], rgba[..., 2]
    luminance = 0.2126 * red + 0.7152 * green + 0.0722 * blue
    chroma = np.maximum.reduce((red, green, blue)) - np.minimum.reduce((red, green, blue))
    _, skin_matte, _ = grade_skin(frame, [0.0, 0.0, 0.0])
    skin = np.asarray(skin_matte, dtype=np.float32) / 255.0
    non_skin = 1.0 - skin

    # The idle sprite's light neutral fabrics are slightly blue. Frame 007
    # matches at the start but later poses lose that blue and look peach.
    pale = (smoothstep(luminance, 145, 195) *
            (1.0 - smoothstep(chroma, 50, 85)) * non_skin)
    missing_blue = np.clip(15.0 - (blue - red), 0.0, 28.0)
    pale_shift = pale * missing_blue

    # Dark outlines and clothing receive only a small common correction.
    dark = (1.0 - smoothstep(luminance, 95, 155)) * non_skin
    # Keep saturated cyan sword light and magenta edge accents recognizable.
    gear = (smoothstep(blue - red, 55, 75) *
            smoothstep(green - red, 17, 35) *
            (1.0 - smoothstep(luminance, 185, 225)) * non_skin)
    gear_desaturation = np.clip(110.0 - (blue - red), 0.0, 30.0)

    delta = np.zeros_like(rgba[..., :3])
    delta[..., 0] = -0.36 * pale_shift - 2.0 * dark - 0.12 * gear * gear_desaturation - 2.0 * skin
    delta[..., 1] = 0.05 * pale_shift + 1.0 * dark + 0.08 * gear * gear_desaturation
    delta[..., 2] = 0.58 * pale_shift + 2.0 * dark + 0.22 * gear * gear_desaturation + 1.0 * skin
    rgba[..., :3] = np.clip(rgba[..., :3] + delta, 0.0, 255.0)
    return Image.fromarray(np.rint(rgba).astype(np.uint8), "RGBA")


def comparison(idle: Image.Image, before: list[Image.Image], after: list[Image.Image]) -> None:
    sheet = Image.new("RGB", (1536, 1270), "#eee9dd")
    draw = ImageDraw.Draw(sheet)
    samples = [("Idle reference", idle), ("Source start", before[0]),
               ("008 start", after[0]), ("Source attack", before[12]),
               ("008 attack", after[12]), ("008 recovery", after[20])]
    for index, (label, frame) in enumerate(samples):
        column, row = index % 3, index // 3
        x, y = column * 512, row * 635
        tile = Image.new("RGBA", frame.size, "#eee9dd")
        tile.alpha_composite(frame)
        sheet.paste(tile.resize((512, 256)).convert("RGB"), (x, y + 28))
        head = tile.crop((420, 18, 650, 190)).resize((460, 344))
        sheet.paste(head.convert("RGB"), (x + 26, y + 290))
        draw.text((x + 12, y + 8), label, fill="#222222")
    sheet.save(OUT / "review/idle-melee-palette-comparison.png")


def main() -> None:
    (OUT / "frames").mkdir(parents=True, exist_ok=True)
    (OUT / "review").mkdir(exist_ok=True)
    before = [Image.open(SOURCE / f"melee_{index:02d}.png").convert("RGBA")
              for index in range(COUNT)]
    idle = Image.open(IDLE).convert("RGBA")
    after = []
    max_change = 0
    for index, frame in enumerate(before):
        result = neutral_grade(frame)
        original = np.asarray(frame)
        corrected = np.asarray(result)
        assert np.array_equal(original[..., 3], corrected[..., 3])
        max_change = max(max_change, int(np.max(np.abs(
            original[..., :3].astype(np.int16) - corrected[..., :3].astype(np.int16)))))
        result.save(OUT / f"frames/melee_{index:02d}.png")
        after.append(result)

    resource = (OUT / "battle_animation.tres").read_text(encoding="utf-8")
    if "guard/asset_008/frames/melee_" not in resource or "guard/005/frames/" in resource:
        raise ValueError("Guard 008 resource must reference its own runtime frames")
    metadata_path = OUT / "battle_animation.frames.json"
    metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    metadata.update({
        "source": "source/melee.mp4",
        "identity_reference": "source/identity-first-frame.png",
        "palette_source": "source/pre-neutral-frames/melee_*.png",
        "palette_reference": "frames/idle_00.png",
        "color_method": "Shared soft neutral fabric, dark outline and blue equipment correction; alpha unchanged",
        "max_rgb_channel_change": max_change,
        "idle_face_median_rgb": face_median(idle).astype(int).tolist(),
    })
    metadata_path.write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    contact_sheet(after, [f"{index:02d}" for index in range(COUNT)],
                  OUT / "review/melee-contact.png")
    comparison(idle, before, after)
    print(f"Built Guard 008: {COUNT} neutral palette frames; max RGB change {max_change}")


if __name__ == "__main__":
    main()
