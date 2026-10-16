"""Audit the Godot 4 PCK directory without loading engine resources.
Run: py -3 tools/release/web_package_check.py builds/web/index.pck
"""
import argparse
import struct
from pathlib import Path


def entries(path):
    with path.open("rb") as stream:
        if stream.read(4) != b"GDPC":
            raise ValueError("Not a Godot PCK")
        version = struct.unpack("<I", stream.read(4))[0]
        if version != 4:
            raise ValueError(f"Unsupported PCK format {version}; update audit parser")
        stream.seek(32)
        directory = struct.unpack("<Q", stream.read(8))[0]
        stream.seek(directory)
        count = struct.unpack("<I", stream.read(4))[0]
        result = {}
        for _ in range(count):
            length = struct.unpack("<I", stream.read(4))[0]
            name = stream.read(length).rstrip(b"\0").decode("utf-8")
            _, size = struct.unpack("<QQ", stream.read(16))
            stream.read(20)  # MD5 and flags
            result[name] = size
        return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pack", type=Path)
    args = parser.parse_args()
    files = entries(args.pack)
    fonts = [name for name in files if name.endswith(".fontdata")]
    assert len(fonts) == 1 and "SourceHanSansSC-Medium" in fonts[0], fonts
    forbidden = [name for name in files if "NotoSansSC" in name or "open-sans/" in name]
    assert not forbidden, forbidden
    textures = [name for name in files if name.endswith(".ctex")]
    assert textures, "No imported textures"
    print(f"WEB_PACKAGE_CHECK files={len(files)} fonts={len(fonts)} textures={len(textures)} bytes={args.pack.stat().st_size} failures=0")
    print(f"FONT {fonts[0]} bytes={files[fonts[0]]}")


if __name__ == "__main__":
    main()
