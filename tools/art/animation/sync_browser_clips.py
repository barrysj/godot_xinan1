"""Sync the art browser's clip index from a Godot SpriteFrames resource.

This only adds clip metadata for browsing; it does not change animation images,
timing, or the runtime resource.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


def clips_from_resource(resource: Path) -> dict:
    source = resource.read_text(encoding="utf-8")
    textures = {resource_id: Path(path).stem for path, resource_id in re.findall(
        r'\[ext_resource type="Texture2D" path="([^"]+)" id="([^"]+)"\]', source
    )}
    clips = {}
    for line in source.splitlines():
        if '"name": &"' not in line:
            continue
        name = re.search(r'"name": &"([^"]+)"', line)
        speed = re.search(r'"speed": (\d+)', line)
        loop = re.search(r'"loop": (true|false)', line)
        references = re.findall(r'"texture": ExtResource\("([^"]+)"\)', line)
        if not (name and speed and loop and references):
            raise ValueError(f"Cannot parse clip in {resource}: {line[:100]}")
        poses = [textures[reference] for reference in references]
        clips[name.group(1)] = {
            "poses": poses,
            "fps": int(speed.group(1)),
            "loop": loop.group(1) == "true",
        }
    if not clips:
        raise ValueError(f"No clips found in {resource}")
    return clips


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("resource", type=Path)
    parser.add_argument("metadata", type=Path)
    args = parser.parse_args()
    metadata = json.loads(args.metadata.read_text(encoding="utf-8-sig"))
    metadata["clips"] = clips_from_resource(args.resource)
    args.metadata.write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"BROWSER_CLIPS_SYNC count={len(metadata['clips'])} metadata={args.metadata}")


if __name__ == "__main__":
    main()
