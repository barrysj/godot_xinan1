from pathlib import Path
from shutil import copyfile

from PIL import Image


ROOT = Path(__file__).resolve().parents[3]
CROP = (200, 260, 1400, 940)
SOURCES = {
    "day": ROOT / "design/concepts/m1-campus-map/runtime-sources/core-day.png",
    "night": ROOT / "design/concepts/m1-campus-map/runtime-sources/core-night.png",
    "anomaly": ROOT / "design/concepts/m1-campus-map/runtime-sources/core-anomaly.png",
}
OUTPUT = ROOT / "assets/art/campus_map"


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for state, source in SOURCES.items():
        copyfile(source, OUTPUT / f"full-{state}.png")
        with Image.open(source) as image:
            if image.size != (1600, 1200):
                raise RuntimeError(f"unexpected {state} source size: {image.size}")
            cropped = image.convert("RGB").crop(CROP)
            target = OUTPUT / f"{state}.png"
            cropped.save(target, optimize=True)
            print(f"{state}: {source.relative_to(ROOT)} -> {target.relative_to(ROOT)} {cropped.size}")


if __name__ == "__main__":
    main()
