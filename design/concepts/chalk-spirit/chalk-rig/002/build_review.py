"""Assemble Godot captures for the throwaway hybrid-animation candidate 002."""

from __future__ import annotations

from pathlib import Path
import shutil

from PIL import Image


ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
REVIEW = HERE / "review"
ATTACK_FRAMES = ROOT / ".godot/chalk-rig-frames"
TOUR_FRAMES = ROOT / ".godot/chalk-rig-tour-frames"


def load_frames(directory: Path, expected: int) -> list[Image.Image]:
    paths = sorted(directory.glob("frame-*.png"))
    if len(paths) != expected:
        raise RuntimeError(f"Expected {expected} captures in {directory}, found {len(paths)}")
    return [Image.open(path).convert("RGB") for path in paths]


def save_gif(frames: list[Image.Image], path: Path, duration: int) -> None:
    frames[0].save(
        path,
        save_all=True,
        append_images=frames[1:],
        duration=duration,
        loop=0,
        disposal=2,
    )


def contact_sheet(names: list[str], columns: int, output: str) -> None:
    width, height = 1920, 1080
    rows = (len(names) + columns - 1) // columns
    cell = (width // columns, height // rows)
    sheet = Image.new("RGB", (width, height), (32, 58, 53))
    for index, name in enumerate(names):
        image = Image.open(REVIEW / f"rig-{name}-1920x1080.png").convert("RGB")
        image.thumbnail(cell, Image.Resampling.LANCZOS)
        x = (index % columns) * cell[0] + (cell[0] - image.width) // 2
        y = (index // columns) * cell[1] + (cell[1] - image.height) // 2
        sheet.paste(image, (x, y))
        image.close()
    sheet.save(REVIEW / output)


def main() -> None:
    attack = load_frames(ATTACK_FRAMES, 40)
    tour = load_frames(TOUR_FRAMES, 112)
    save_gif(attack, REVIEW / "rig-preview.gif", 80)
    save_gif(tour, REVIEW / "rig-all-actions.gif", 75)
    contact_sheet(["idle", "windup", "release", "recovery"], 2, "rig-attack-contact-sheet.png")
    contact_sheet(["idle", "move", "attack", "cast", "hurt", "critical", "death"], 3, "rig-all-actions-contact-sheet.png")
    for frame in attack + tour:
        frame.close()
    shutil.rmtree(ATTACK_FRAMES)
    shutil.rmtree(TOUR_FRAMES)
    print("chalk rig 002 review: attack GIF, all-actions GIF, contact sheets")


if __name__ == "__main__":
    main()
