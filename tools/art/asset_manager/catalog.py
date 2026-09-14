"""Scan local art folders into object-oriented cards.

The catalog deliberately uses only Python's standard library.  It reads real
files first, then enriches them with authoritative project metadata when that
metadata can be tied to an exact path or object id.
"""

from __future__ import unicode_literals

import ast
import hashlib
import json
import os
import re
from collections import OrderedDict
from pathlib import Path


IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".svg"}
ANIMATION_EXTENSIONS = {".tres", ".res"}
SUPPORTED_EXTENSIONS = IMAGE_EXTENSIONS | ANIMATION_EXTENSIONS

CATEGORY_ALIASES = {
    "characters": "人物",
    "character": "人物",
    "people": "人物",
    "人物": "人物",
    "enemies": "人物",
    "enemy": "人物",
    "敌人": "人物",
    "backgrounds": "场景",
    "background": "场景",
    "scenes": "场景",
    "scene": "场景",
    "environment": "场景",
    "场景": "场景",
    "ui": "UI",
    "interface": "UI",
    "interfaces": "UI",
    "icons": "UI",
    "界面": "UI",
    "effects": "特效",
    "effect": "特效",
    "vfx": "特效",
    "fx": "特效",
    "特效": "特效",
}

CATEGORY_ORDER = {"场景": 0, "人物": 1, "UI": 2, "特效": 3, "未归类": 4}
CLIP_LABELS = {
    "idle": "待机",
    "move": "移动",
    "attack": "攻击",
    "cast": "施法",
    "hurt": "受击",
    "critical": "濒危",
    "death": "退场",
    "burst": "爆发",
}
KNOWN_DISPLAY_NAMES = {
    "battle_courtyard": "校园庭院",
    "battle_lab": "电子实验室",
    "battle_classroom": "异变教室",
    "guard_shield": "守护护盾",
}


def _path_key(path):
    return os.path.normcase(str(Path(path).resolve()))


def _inside(path, root):
    try:
        Path(path).resolve().relative_to(Path(root).resolve())
        return True
    except ValueError:
        return False


def _asset_id(path):
    return hashlib.sha256(_path_key(path).encode("utf-8")).hexdigest()[:20]


def _clean_name(value):
    return str(value).replace("_", " ").replace("-", " ").strip() or "未命名对象"


def _parse_scalar(value):
    value = value.strip()
    if not value:
        return {}
    if value.startswith("[") and value.endswith("]"):
        body = value[1:-1].strip()
        if not body:
            return []
        return [_parse_scalar(piece) for piece in body.split(",")]
    if value in ("true", "false"):
        return value == "true"
    if value in ("null", "~"):
        return None
    if (value.startswith('"') and value.endswith('"')) or (
        value.startswith("'") and value.endswith("'")
    ):
        try:
            return ast.literal_eval(value)
        except (ValueError, SyntaxError):
            return value[1:-1]
    try:
        return float(value) if "." in value else int(value)
    except ValueError:
        return value


def parse_simple_yaml(path):
    """Parse the mapping/list subset used by asset_manifest.yaml."""
    root = {}
    stack = [(-1, root)]
    for raw_line in Path(path).read_text(encoding="utf-8-sig").splitlines():
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue
        indent = len(raw_line) - len(raw_line.lstrip(" "))
        stripped = raw_line.strip()
        if stripped.startswith("-"):
            continue
        if ":" not in stripped:
            continue
        key, value = stripped.split(":", 1)
        while stack[-1][0] >= indent:
            stack.pop()
        parent = stack[-1][1]
        parsed = _parse_scalar(value)
        parent[key.strip()] = parsed
        if isinstance(parsed, dict):
            stack.append((indent, parsed))
    return root


def normalize_roots(raw_roots, allowed_roots=None):
    """Resolve, validate and de-duplicate roots, removing nested overlaps."""
    roots = []
    errors = []
    seen = set()
    for raw in raw_roots:
        value = str(raw).strip().strip('"')
        if not value:
            continue
        path = Path(value).expanduser().resolve()
        key = _path_key(path)
        if key in seen:
            continue
        if not path.exists():
            errors.append({"path": str(path), "message": "目录不存在"})
            continue
        if not path.is_dir():
            errors.append({"path": str(path), "message": "不是目录"})
            continue
        if allowed_roots and not any(_inside(path, boundary) for boundary in allowed_roots):
            errors.append({"path": str(path), "message": "仅支持本项目的 assets/art 与 design/concepts"})
            continue
        seen.add(key)
        roots.append(path)
    roots.sort(key=lambda item: (len(item.parts), _path_key(item)))
    effective = []
    for root in roots:
        if any(_inside(root, parent) for parent in effective):
            continue
        effective.append(root)
    return effective, errors


def find_project_root(path):
    current = Path(path).resolve()
    if current.is_file():
        current = current.parent
    for parent in (current,) + tuple(current.parents):
        if (parent / "project.godot").is_file():
            return parent
    return None


def _read_text(path):
    try:
        return Path(path).read_text(encoding="utf-8-sig")
    except (OSError, UnicodeError):
        return ""


def godot_resource_info(path, trusted_project_root=None):
    text = _read_text(path)
    lower = text.lower()
    if "battle_animation_set.gd" in lower or 'script_class="battleanimationset"' in lower:
        resource_type = "BattleAnimationSet"
    elif "battle_effect_set.gd" in lower or 'script_class="battleeffectset"' in lower:
        resource_type = "BattleEffectSet"
    else:
        resource_type = "GodotResource"

    clips = []
    for name in re.findall(r'"name"\s*:\s*&?"([^"]+)"', text):
        if name not in [item["id"] for item in clips]:
            clips.append({"id": name, "name": CLIP_LABELS.get(name, name)})

    project_root = find_project_root(path)
    missing_refs = []
    unimported_refs = []
    if project_root:
        for reference in re.findall(r'path="res://([^"]+)"', text):
            target = (project_root / reference.replace("/", os.sep)).resolve()
            if not target.exists():
                missing_refs.append("res://" + reference)
            elif target.suffix.lower() in IMAGE_EXTENSIONS:
                import_path = Path(str(target) + ".import")
                import_text = _read_text(import_path)
                remap = re.search(r'^path="res://([^"]+)"', import_text, re.MULTILINE)
                if not remap or not (project_root / remap.group(1).replace("/", os.sep)).is_file():
                    unimported_refs.append("res://" + reference)

    supported = False
    reason = "不是 BattleAnimationSet，当前预览入口不支持"
    resource_uri = None
    if resource_type == "BattleEffectSet":
        reason = "技能特效暂不支持独立预览"
    elif resource_type == "BattleAnimationSet":
        if project_root is None:
            reason = "未找到所属 project.godot"
        elif missing_refs:
            reason = "资源引用缺失：" + "、".join(missing_refs[:3])
        elif unimported_refs:
            reason = "资源尚未导入：" + "、".join(unimported_refs[:3])
        elif trusted_project_root is None or project_root.resolve() != Path(trusted_project_root).resolve():
            reason = "需在所属项目预览；该项目入口尚未设为受信"
        elif not (project_root / "run-motion-preview.ps1").is_file():
            reason = "所属项目缺少 run-motion-preview.ps1"
        else:
            supported = True
            reason = "可预览"
            relative = Path(path).resolve().relative_to(project_root).as_posix()
            resource_uri = "res://" + relative

    return {
        "resource_type": resource_type,
        "clips": clips,
        "project_root": str(project_root) if project_root else None,
        "resource_uri": resource_uri,
        "preview_supported": supported,
        "preview_reason": reason,
        "missing_references": missing_refs,
        "unimported_references": unimported_refs,
    }


def _load_frame_clips(metadata_path):
    try:
        data = json.loads(Path(metadata_path).read_text(encoding="utf-8-sig"))
    except (OSError, ValueError):
        return []
    clips = []
    for clip_id, clip in data.get("clips", {}).items():
        clips.append(
            {
                "id": clip_id,
                "name": CLIP_LABELS.get(clip_id, clip_id),
                "frames": len(clip.get("poses", [])),
                "fps": clip.get("fps"),
            }
        )
    return clips


def _infer_category(path):
    parts = [part.lower() for part in Path(path).parts]
    for index in range(len(parts) - 1, -1, -1):
        if parts[index] in CATEGORY_ALIASES:
            return CATEGORY_ALIASES[parts[index]], index
    return "未归类", -1


def _infer_kind(path, root, manifest_type=None):
    suffix = Path(path).suffix.lower()
    lowered = "/".join(part.lower() for part in Path(path).parts)
    manifest_type = (manifest_type or "").lower()
    if suffix in ANIMATION_EXTENSIONS:
        info = godot_resource_info(path)
        if info["resource_type"] == "BattleEffectSet":
            return "effect_animation", "特效资源"
        if info["resource_type"] == "BattleAnimationSet":
            return "animation", "动画资源"
        return "resource", "Godot 资源"
    if "concept" in lowered or "概念" in lowered or "design/concepts" in lowered:
        return "concept", "概念图"
    if "concept" in manifest_type:
        return "concept", "概念图"
    if "sheet" in manifest_type or "atlas" in manifest_type:
        return "atlas", "图集"
    if any(token in Path(path).stem.lower() for token in ("sheet", "atlas", "grid")):
        return "atlas", "图集"
    if "background" in manifest_type:
        return "image", "场景图"
    return "image", "图片"


def _manifest_records(project_root):
    manifest_path = Path(project_root) / "assets" / "art" / "asset_manifest.yaml"
    if not manifest_path.is_file():
        return []
    try:
        data = parse_simple_yaml(manifest_path)
    except OSError:
        return []
    records = []
    section_map = {
        "characters": "人物",
        "enemies": "人物",
        "backgrounds": "场景",
        "ui": "UI",
        "effects": "特效",
    }
    for section, objects in data.get("assets", {}).items():
        if not isinstance(objects, dict):
            continue
        category = section_map.get(section, "未归类")
        for object_id, variants in objects.items():
            if not isinstance(variants, dict):
                continue
            for version, metadata in variants.items():
                if not isinstance(metadata, dict) or not metadata.get("file"):
                    continue
                file_path = (Path(project_root) / str(metadata["file"])).resolve()
                record = {
                    "object_id": object_id,
                    "name": KNOWN_DISPLAY_NAMES.get(object_id, _clean_name(object_id)),
                    "category": category,
                    "version": version,
                    "path": file_path,
                    "metadata": metadata,
                    "manifest_path": manifest_path,
                }
                records.append(record)
    return records


def _unit_names(project_root):
    names = {}
    content_root = Path(project_root) / "resources" / "content"
    for section in ("characters", "enemies"):
        directory = content_root / section
        if not directory.is_dir():
            continue
        for path in directory.glob("*.tres"):
            text = _read_text(path)
            object_match = re.search(r'^id\s*=\s*"([^"]+)"', text, re.MULTILINE)
            name_match = re.search(r'^display_name\s*=\s*"([^"]+)"', text, re.MULTILINE)
            if object_match and name_match:
                names[object_match.group(1)] = name_match.group(1)
    return names


class AssetCatalog(object):
    def __init__(self, project_root):
        self.project_root = Path(project_root).resolve()
        self.allowed_roots = [
            self.project_root / "assets" / "art",
            self.project_root / "design" / "concepts",
        ]
        self.files = {}
        self.animation_items = {}

    def _new_object(self, objects, object_id, name, category):
        key = str(object_id)
        if key not in objects:
            objects[key] = {
                "id": key,
                "name": name,
                "category": category,
                "assets": OrderedDict(),
                "warnings": [],
            }
        return objects[key]

    def _add_asset(self, obj, path, root, kind=None, label=None, metadata=None, version=None):
        path = Path(path).resolve()
        key = _path_key(path)
        if key in obj["assets"]:
            existing = obj["assets"][key]
            if metadata:
                existing["metadata"].update(metadata)
            return existing
        asset_id = _asset_id(path)
        metadata = dict(metadata or {})
        inferred_kind, inferred_label = _infer_kind(path, root, metadata.get("type"))
        kind = kind or inferred_kind
        label = label or inferred_label
        exists = path.is_file()
        item = {
            "id": asset_id,
            "name": path.name,
            "path": str(path),
            "kind": kind,
            "kind_label": label,
            "version": version,
            "exists": exists,
            "is_image": path.suffix.lower() in IMAGE_EXTENSIONS and exists,
            "metadata": metadata,
            "clips": [],
            "preview_supported": False,
            "preview_reason": "仅角色 BattleAnimationSet 可预览",
        }
        if path.suffix.lower() in ANIMATION_EXTENSIONS and exists:
            item.update(godot_resource_info(path, self.project_root))
            self.animation_items[asset_id] = item
        obj["assets"][key] = item
        if exists:
            self.files[asset_id] = path
        return item

    def scan(self, raw_roots):
        self.files = {}
        self.animation_items = {}
        roots, errors = normalize_roots(raw_roots, self.allowed_roots)
        objects = OrderedDict()
        manifest_records = _manifest_records(self.project_root)
        manifest_by_path = {_path_key(item["path"]): item for item in manifest_records}
        manifest_by_object = {}
        for record in manifest_records:
            manifest_by_object.setdefault(record["object_id"], record)
        names = _unit_names(self.project_root)
        discovered = set()

        for root in roots:
            for path in root.rglob("*"):
                if not path.is_file() or path.name == ".art-object.json":
                    continue
                if path.suffix.lower() not in SUPPORTED_EXTENSIONS or path.name.endswith(".import"):
                    continue
                key = _path_key(path)
                if key in discovered:
                    continue
                discovered.add(key)
                manifest = manifest_by_path.get(key)
                if manifest:
                    object_id = manifest["object_id"]
                    name = names.get(object_id, KNOWN_DISPLAY_NAMES.get(object_id, manifest["name"]))
                    category = manifest["category"]
                else:
                    category, category_index = _infer_category(path)
                    if _inside(path, self.project_root / "design" / "concepts"):
                        relative = path.relative_to(self.project_root / "design" / "concepts")
                        object_id = relative.parts[1] if len(relative.parts) > 2 else relative.parts[0]
                        linked_manifest = manifest_by_object.get(object_id)
                        if linked_manifest:
                            category = linked_manifest["category"]
                            name = names.get(
                                object_id,
                                KNOWN_DISPLAY_NAMES.get(object_id, linked_manifest["name"]),
                            )
                        else:
                            name = _clean_name(object_id)
                    elif category_index >= 0 and category_index + 1 < len(path.parts):
                        object_id = path.parts[category_index + 1]
                        name = _clean_name(object_id)
                    else:
                        try:
                            relative = path.relative_to(root)
                            object_id = relative.parts[0] if len(relative.parts) > 1 else root.name
                        except ValueError:
                            object_id = path.parent.name
                        name = _clean_name(object_id)
                obj = self._new_object(objects, object_id, name, category)
                metadata = manifest["metadata"] if manifest else {}
                version = manifest["version"] if manifest else None
                item = self._add_asset(obj, path, root, metadata=metadata, version=version)

        # Manifest links are authoritative: attach exact animation and frame metadata
        # to the object whose exact image file was discovered.  Missing links remain
        # visible so the user gets a useful error instead of a silent fallback.
        for manifest in manifest_records:
            source_key = _path_key(manifest["path"])
            if source_key not in discovered:
                continue
            object_id = manifest["object_id"]
            obj = self._new_object(
                objects,
                object_id,
                names.get(object_id, KNOWN_DISPLAY_NAMES.get(object_id, manifest["name"])),
                manifest["category"],
            )
            metadata = manifest["metadata"]
            frame_metadata = metadata.get("frame_metadata")
            animation_resource = metadata.get("animation_resource")
            if frame_metadata:
                meta_path = (self.project_root / str(frame_metadata)).resolve()
                clips = _load_frame_clips(meta_path)
                source_item = obj["assets"].get(source_key)
                if source_item:
                    source_item["clips"] = clips
                    source_item["metadata"]["frame_metadata_exists"] = meta_path.is_file()
            if animation_resource:
                animation_path = (self.project_root / str(animation_resource)).resolve()
                animation_item = self._add_asset(
                    obj,
                    animation_path,
                    self.project_root,
                    metadata={"declared_by": str(manifest["manifest_path"])},
                    version=manifest["version"],
                )
                if frame_metadata and not animation_item["clips"]:
                    animation_item["clips"] = _load_frame_clips(
                        (self.project_root / str(frame_metadata)).resolve()
                    )
                if not animation_item["exists"]:
                    animation_item["preview_reason"] = "Manifest 指向的动画资源不存在"
                    obj["warnings"].append(animation_item["preview_reason"])

        result_objects = []
        for obj in objects.values():
            assets = list(obj.pop("assets").values())
            assets.sort(key=lambda item: (item["kind_label"], item["version"] or "", item["path"]))
            thumbnails = [item["id"] for item in assets if item["is_image"]]
            obj["assets"] = assets
            obj["thumbnail_id"] = thumbnails[0] if thumbnails else None
            obj["counts"] = {
                "concepts": sum(item["kind"] == "concept" for item in assets),
                "animations": sum(item["kind"] in ("animation", "effect_animation") for item in assets),
                "atlases": sum(item["kind"] == "atlas" for item in assets),
                "files": len(assets),
            }
            statuses = sorted(
                {str(item["metadata"].get("status")) for item in assets if item["metadata"].get("status")}
            )
            obj["statuses"] = statuses
            result_objects.append(obj)
        result_objects.sort(
            key=lambda item: (CATEGORY_ORDER.get(item["category"], 9), item["name"].lower(), item["id"])
        )

        return {
            "roots": [str(root) for root in roots],
            "errors": errors,
            "objects": result_objects,
            "summary": {
                "objects": len(result_objects),
                "files": sum(item["counts"]["files"] for item in result_objects),
                "categories": {
                    category: sum(item["category"] == category for item in result_objects)
                    for category in CATEGORY_ORDER
                },
            },
        }

    def resolve_file(self, asset_id):
        path = self.files.get(asset_id)
        if path is None or not path.is_file():
            return None
        return path

    def resolve_animation(self, asset_id):
        item = self.animation_items.get(asset_id)
        if not item or not item.get("preview_supported"):
            return None
        path = Path(item["path"]).resolve()
        if not path.is_file() or find_project_root(path) != self.project_root:
            return None
        refreshed = godot_resource_info(path, self.project_root)
        if not refreshed["preview_supported"]:
            return None
        return {
            "path": path,
            "resource_uri": refreshed["resource_uri"],
            "project_root": self.project_root,
            "script": self.project_root / "run-motion-preview.ps1",
        }
