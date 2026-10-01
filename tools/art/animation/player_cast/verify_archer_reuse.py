"""Verify that two Archer appearances use exactly one motion structure/library."""

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[4] / "design/concepts/characters"
LIBRARY = 'animations.tres'


def normalized_resource(role: str, name: str) -> str:
    text = (ROOT / role / 'asset_001' / name).read_text(encoding='utf-8')
    assert text.count(LIBRARY) == 1, (role, name, 'shared library missing')
    return text.replace(f'/{role}/asset_001/', '/ROLE/asset_001/')


def main() -> None:
    assert (ROOT / 'archer/asset_001/animations.tres').read_bytes() == (ROOT / 'archer-alt/asset_001/animations.tres').read_bytes()
    for name in ('presentation.tscn', 'battle_animation.tres'):
        assert normalized_resource('archer', name) == normalized_resource('archer-alt', name), name

    first = np.asarray(Image.open(ROOT / 'archer/asset_001/frames/idle.png').convert('RGBA'))
    second = np.asarray(Image.open(ROOT / 'archer-alt/asset_001/frames/idle.png').convert('RGBA'))
    assert first.shape == second.shape == (512, 512, 4)
    visible = (first[:, :, 3] > 128) & (second[:, :, 3] > 128)
    assert visible.sum() > 10000
    changed = np.any(np.abs(first[:, :, :3].astype(np.int16) - second[:, :, :3].astype(np.int16)) > 30, axis=2)
    fraction = float(changed[visible].mean())
    assert fraction > 0.3, f'Appearance insufficiently different: {fraction:.3f}'
    print(f'ARCHER_REUSE_PASS shared_library={LIBRARY} identical_scene_and_clips=true '
          f'visibly_different_fraction={fraction:.3f}')


if __name__ == '__main__':
    main()
