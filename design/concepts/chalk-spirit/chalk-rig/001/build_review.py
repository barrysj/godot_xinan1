"""Assemble the throwaway rig capture frames into review artifacts."""

from __future__ import annotations

from pathlib import Path
import shutil

from PIL import Image


ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
REVIEW = HERE / "review"
FRAMES = ROOT / ".godot/chalk-rig-frames"


def main() -> None:
    frame_paths = sorted(FRAMES.glob("frame-*.png"))
    if len(frame_paths) != 40:
        raise RuntimeError(f"Expected 40 Godot captures, found {len(frame_paths)}")

    frames = [Image.open(path).convert("RGB") for path in frame_paths]
    frames[0].save(
        REVIEW / "rig-preview.gif",
        save_all=True,
        append_images=frames[1:],
        duration=80,
        loop=0,
        disposal=2,
    )

    states = ["idle", "windup", "release", "recovery"]
    contact_sheet = Image.new("RGB", (1920, 1080), (32, 58, 53))
    for index, state in enumerate(states):
        image = Image.open(REVIEW / f"rig-{state}-1920x1080.png").convert("RGB")
        image.thumbnail((960, 540), Image.Resampling.LANCZOS)
        contact_sheet.paste(image, ((index % 2) * 960, (index // 2) * 540))
    contact_sheet.save(REVIEW / "rig-state-contact-sheet.png")

    for frame in frames:
        frame.close()
    shutil.rmtree(FRAMES)
    print("chalk rig review: rig-preview.gif, rig-state-contact-sheet.png")


if __name__ == "__main__":
    main()
