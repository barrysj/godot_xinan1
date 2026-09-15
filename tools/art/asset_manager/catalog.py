"""Manifest-driven catalog for the Cyber Pop Campus art desk.

The main manifest is the only discovery input. Object roots make file entries
short; file types and Godot references are derived from the registered files.
"""

from __future__ import unicode_literals

import ast
import hashlib
import json
import os
import re
from pathlib import Path


IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".svg"}
RESOURCE_EXTENSIONS = {".tres", ".res"}
CATEGORY_ORDER = {"场景": 0, "人物": 1, "UI": 2, "特效": 3, "未归类": 4}
TYPE_CATEGORIES = {
    "character": "人物", "enemy": "人物", "background": "场景",
    "scene": "场景", "ui": "UI", "effect": "特效",
}
CLIP_LABELS = {
    "idle": "待机", "move": "移动", "attack": "攻击", "cast": "施法",
    "hurt": "受击", "critical": "濒危", "death": "退场", "burst": "爆发",
}
ROLE_KINDS = {
    "concept": ("concept", "概念图"), "atlas": ("atlas", "图集"),
    "image": ("image", "图片"), "source": ("source", "处理来源"),
    "frame_metadata": ("metadata", "帧元数据"),
    "animation_resource": ("animation", "动画资源"),
    "effect_resource": ("effect_animation", "特效资源"),
    "projectile_resource": ("resource", "弹体资源"),
    "preview_gif": ("preview", "GIF 预览"), "dependency": ("resource", "依赖资源"),
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


def _preview_id(object_id, variant_id):
    value = "%s/%s/godot" % (object_id, variant_id)
    return "preview-" + hashlib.sha256(value.encode("utf-8")).hexdigest()[:16]


def _parse_scalar(value):
    value = value.strip()
    if not value:
        return {}
    if value.startswith("[") and value.endswith("]"):
        body = value[1:-1].strip()
        return [] if not body else [_parse_scalar(piece) for piece in body.split(",")]
    if value in ("true", "false"):
        return value == "true"
    if value in ("null", "~"):
        return None
    if (value.startswith('"') and value.endswith('"')) or (value.startswith("'") and value.endswith("'")):
        try:
            return ast.literal_eval(value)
        except (ValueError, SyntaxError):
            return value[1:-1]
    if re.match(r"^0\d+$", value):
        return value
    try:
        return float(value) if "." in value else int(value)
    except ValueError:
        return value


def parse_simple_yaml(path):
    """Parse the mapping and scalar-list subset used by project manifests."""
    root = {}
    stack = [(-1, root)]
    for raw_line in Path(path).read_text(encoding="utf-8-sig").splitlines():
        if not raw_line.strip() or raw_line.lstrip().startswith("#"):
            continue
        indent = len(raw_line) - len(raw_line.lstrip(" "))
        stripped = raw_line.strip()
        if stripped.startswith("-") or ":" not in stripped:
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


def _sha256(path):
    digest = hashlib.sha256()
    try:
        with Path(path).open("rb") as handle:
            for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                digest.update(chunk)
    except OSError:
        return None
    return digest.hexdigest()


def _file_status(path):
    if not Path(path).is_file():
        return {"status": "missing", "label": "文件缺失", "actual": None}
    return {"status": "matched", "label": "可读取", "actual": _sha256(path)}


def _registered_path(project_root, raw_path, base=None):
    value = str(raw_path or "").strip().strip('"')
    if not value:
        return None
    path = Path(value)
    if not path.is_absolute():
        path = Path(base or project_root) / path
    path = path.resolve()
    return path if _inside(path, project_root) else None


def _uri_path(project_root, uri):
    value = str(uri or "")
    return _registered_path(project_root, value[6:]) if value.startswith("res://") else None


def godot_resource_info(path, trusted_project_root=None):
    text = _read_text(path)
    lower = text.lower()
    if "battle_animation_set.gd" in lower or 'script_class="battleanimationset"' in lower:
        resource_type = "BattleAnimationSet"
    elif "battle_effect_set.gd" in lower or 'script_class="battleeffectset"' in lower:
        resource_type = "BattleEffectSet"
    elif "battle_projectile_style.gd" in lower or 'script_class="battleprojectilestyle"' in lower:
        resource_type = "BattleProjectileStyle"
    else:
        resource_type = "GodotResource"
    project_root = Path(trusted_project_root).resolve() if trusted_project_root else find_project_root(path)
    references, missing_refs = [], []
    if project_root:
        for reference in re.findall(r'path="res://([^"]+)"', text):
            uri = "res://" + reference
            references.append(uri)
            target = (project_root / reference.replace("/", os.sep)).resolve()
            if not target.exists():
                missing_refs.append(uri)
    return {"resource_type": resource_type, "project_root": str(project_root) if project_root else None, "references": references, "missing_references": missing_refs}


def _role_for(file_id, path, stage="asset"):
    key = str(file_id or "").lower()
    name = Path(path).name.lower()
    suffix = Path(path).suffix.lower()
    if suffix == ".gif" or key.startswith("gif_"):
        return "preview_gif"
    if name.endswith(".frames.json") or key in ("frames", "frame_metadata"):
        return "frame_metadata"
    if suffix in RESOURCE_EXTENSIONS:
        resource_type = godot_resource_info(path).get("resource_type") if Path(path).is_file() else ""
        return {"BattleAnimationSet": "animation_resource", "BattleEffectSet": "effect_resource", "BattleProjectileStyle": "projectile_resource"}.get(resource_type, "dependency")
    if "source" in key:
        return "source"
    if stage == "concept":
        return "concept"
    if "sheet" in key or "sheet" in name or "atlas" in key:
        return "atlas"
    if suffix in IMAGE_EXTENSIONS:
        return "image"
    return "dependency"


def _kind_for(role, path):
    if role in ROLE_KINDS:
        return ROLE_KINDS[role]
    if Path(path).suffix.lower() in RESOURCE_EXTENSIONS:
        return "resource", "Godot 资源"
    if Path(path).suffix.lower() in IMAGE_EXTENSIONS:
        return "image", "图片"
    return "file", "文件"


def _load_frame_clips(path):
    try:
        data = json.loads(Path(path).read_text(encoding="utf-8-sig"))
    except (OSError, ValueError):
        return []
    clips = []
    if isinstance(data.get("clips"), dict):
        for clip_id, clip in data["clips"].items():
            clips.append({"id": clip_id, "name": CLIP_LABELS.get(clip_id, clip_id), "frames": len(clip.get("poses", [])), "fps": clip.get("fps"), "loop": clip.get("loop")})
    elif isinstance(data.get("regions"), list):
        clips.append({"id": "burst", "name": "爆发", "frames": len(data["regions"]), "fps": data.get("fps"), "loop": False})
    return clips


def _preview_target_info(config, project_root):
    unit = str(config.get("unit") or "")
    animation = str(config.get("animation") or "")
    projectile = str(config.get("projectile") or "")
    if not unit and not animation:
        return False, "Godot 预览未登记对象或动画", None
    for label, uri in (("对象", unit), ("动画", animation), ("弹体", projectile)):
        if not uri:
            continue
        path = _uri_path(project_root, uri)
        if path is None or not path.is_file():
            return False, "%s资源缺失：%s" % (label, uri), None
    if animation:
        info = godot_resource_info(_uri_path(project_root, animation), project_root)
        if info["resource_type"] != "BattleAnimationSet":
            return False, "动画资源类型不正确", None
        if info["missing_references"]:
            return False, "动画引用缺失：" + "、".join(info["missing_references"][:3]), None
    script = Path(project_root) / "run-motion-preview.ps1"
    if not script.is_file():
        return False, "项目缺少动作预览入口", None
    return True, "可预览", {"script": script, "unit_uri": unit or None, "animation_uri": animation or None, "projectile_uri": projectile or None}


class AssetCatalog(object):
    def __init__(self, project_root):
        self.project_root = Path(project_root).resolve()
        self.default_manifest = self.project_root / "assets" / "art" / "asset_manifest.yaml"
        self.files = {}
        self.preview_items = {}

    def _file_item(self, root, relative, variant_id=None, file_id=None, stage="asset", effective=False):
        base = _registered_path(self.project_root, root or ".")
        path = _registered_path(self.project_root, relative, base) if base else None
        if path is None:
            path = self.project_root / "__invalid_manifest_path__"
        role = _role_for(file_id, path, stage)
        kind, label = _kind_for(role, path)
        item = {
            "id": _asset_id(path), "file_id": file_id, "name": path.name, "path": str(path),
            "manifest_path": str(relative or ""), "root": str(root or "."), "kind": kind,
            "kind_label": label, "role": role, "variant_id": variant_id, "stage": stage,
            "effective": effective, "exists": path.is_file(),
            "is_image": path.suffix.lower() in IMAGE_EXTENSIONS and path.is_file(),
            "integrity": _file_status(path), "metadata": {},
        }
        if path.suffix.lower() in RESOURCE_EXTENSIONS and path.is_file():
            item.update(godot_resource_info(path, self.project_root))
        if path.is_file():
            self.files[item["id"]] = path
        return item

    def _manifest_path(self, raw_manifest):
        return _registered_path(self.project_root, raw_manifest or self.default_manifest)

    def _load_objects(self, raw_manifest):
        main_path = self._manifest_path(raw_manifest)
        if main_path is None or not main_path.is_file():
            return None, [], [{"path": str(raw_manifest or self.default_manifest), "message": "Manifest 不存在或越出当前项目"}]
        main = parse_simple_yaml(main_path)
        if main.get("schema_version") != 3:
            return main_path, [], [{"path": str(main_path), "message": "仅支持 Manifest schema_version 3"}]
        loaded, errors = [], []
        for object_id, raw_path in (main.get("objects", {}) or {}).items():
            path = _registered_path(self.project_root, raw_path, main_path.parent)
            if path is None or not path.is_file():
                errors.append({"path": str(raw_path), "message": "对象 Manifest 不存在或越出当前项目"})
                continue
            data = parse_simple_yaml(path)
            if data.get("schema_version") != 3:
                errors.append({"path": str(path), "message": "对象 Manifest 不是 schema_version 3"})
                continue
            if (data.get("object", {}) or {}).get("id") != object_id:
                errors.append({"path": str(path), "message": "对象 ID 与主 Manifest 不一致"})
                continue
            loaded.append((object_id, path, data))
        return main_path, loaded, errors

    def _copy_check(self, file_id, selected, effective):
        if selected is None:
            return {"id": file_id, "kind": "文件内容", "status": "unselected", "label": "选用版本未登记同名文件"}
        source_hash = selected["integrity"]["actual"]
        target_hash = effective["integrity"]["actual"]
        if source_hash is None or target_hash is None:
            return {"id": file_id, "kind": "文件内容", "status": "missing", "label": "对比文件缺失"}
        if source_hash != target_hash:
            return {"id": file_id, "kind": "文件内容", "status": "mismatch", "label": "选用与生效内容不同", "source_hash": source_hash, "target_hash": target_hash}
        return {"id": file_id, "kind": "文件内容", "status": "matched", "label": "选用与生效内容相同", "source_hash": source_hash, "target_hash": target_hash}

    def _owner_check(self, owner, expected_uris):
        source = _registered_path(self.project_root, owner)
        if source is None or not source.is_file():
            return {"id": Path(str(owner)).stem or "owner", "kind": "Godot 引用", "status": "missing", "label": "所有者资源缺失", "source": str(owner)}
        text = _read_text(source)
        target = next((uri for uri in expected_uris if uri in text), None)
        if target is None:
            return {"id": source.stem, "kind": "Godot 引用", "status": "mismatch", "label": "未引用登记的生效资源", "source": str(owner)}
        return {"id": source.stem, "kind": "Godot 引用", "status": "matched", "label": "引用已连接", "source": str(owner), "target": target}

    def scan(self, raw_manifest=None):
        self.files, self.preview_items = {}, {}
        main_path, loaded, errors = self._load_objects(raw_manifest)
        result_objects = []
        for object_id, manifest_path, data in loaded:
            identity = data.get("object", {}) or {}
            variants, all_assets, variant_lookups, warnings = [], [], {}, []
            for variant_id, raw_variant in (data.get("variants", {}) or {}).items():
                if not isinstance(raw_variant, dict):
                    continue
                stage = str(raw_variant.get("stage") or "asset")
                root = str(raw_variant.get("root") or ".")
                files, file_lookup = [], {}
                for file_id, relative in (raw_variant.get("files", {}) or {}).items():
                    item = self._file_item(root, relative, variant_id, file_id, stage)
                    files.append(item); file_lookup[file_id] = item; all_assets.append(item)
                    if item["integrity"]["status"] == "missing":
                        warnings.append("%s/%s：文件缺失" % (variant_id, file_id))
                resource = raw_variant.get("resource")
                if resource:
                    item = self._file_item(".", resource, variant_id, "resource", stage)
                    files.append(item); file_lookup["resource"] = item; all_assets.append(item)
                    if item["integrity"]["status"] == "missing":
                        warnings.append("%s/resource：文件缺失" % variant_id)
                    elif item.get("missing_references"):
                        warnings.append("%s/resource：Godot 引用缺失" % variant_id)
                animation_config = raw_variant.get("animation", {}) or {}
                clip_source = file_lookup.get(animation_config.get("frames"))
                clips = _load_frame_clips(clip_source["path"]) if clip_source else []
                animation = {"label": "序列帧动画", "frames": animation_config.get("frames"), "clips": clips} if animation_config else None
                raw_previews = raw_variant.get("previews", {}) or {}
                previews = []
                for clip_id, file_id in (raw_previews.get("gifs", {}) or {}).items():
                    linked = file_lookup.get(file_id)
                    previews.append({"id": clip_id, "type": "gif", "file_id": linked["id"] if linked else None, "supported": bool(linked and linked["exists"]), "reason": "可播放" if linked and linked["exists"] else "GIF 文件缺失"})
                godot = raw_previews.get("godot")
                if isinstance(godot, dict):
                    supported, reason, resolved = _preview_target_info(godot, self.project_root)
                    preview_asset_id = _preview_id(object_id, variant_id)
                    if supported:
                        self.preview_items[preview_asset_id] = resolved
                    previews.append({"id": "godot", "asset_id": preview_asset_id, "type": "godot", "supported": supported, "reason": reason, "unit": godot.get("unit"), "animation": godot.get("animation"), "projectile": godot.get("projectile")})
                visual_candidates = [item for item in files if item["is_image"] and item["role"] != "preview_gif"]
                visual_candidates.sort(key=lambda item: (item["role"] == "source", item["role"] not in ("concept", "atlas", "image")))
                validation_statuses = [item["integrity"]["status"] for item in files]
                has_missing_reference = any(item.get("missing_references") for item in files)
                if "missing" in validation_statuses or has_missing_reference:
                    validation_status, validation_label = "missing", "文件缺失"
                elif files:
                    validation_status, validation_label = "matched", "校验通过"
                else:
                    validation_status, validation_label = "unknown", "待校验"
                evidence = raw_variant.get("approval_evidence") or {}
                variant = {
                    "id": variant_id, "version": str(raw_variant.get("version") or variant_id),
                    "stage": stage, "selection": str(raw_variant.get("selection") or "unknown"),
                    "approval": str(raw_variant.get("approval") or "unknown"),
                    "approval_evidence": raw_variant.get("approval_evidence"), "root": root,
                    "files": files, "animation": animation, "previews": previews,
                    "metadata": raw_variant.get("metadata", {}) or {},
                    "summary": {
                        "date": str(evidence.get("date") or "日期未记录"),
                        "thumbnail_id": visual_candidates[0]["id"] if visual_candidates else None,
                        "images": len(visual_candidates), "animations": len(clips),
                        "validation_status": validation_status, "validation_label": validation_label,
                    },
                }
                variants.append(variant); variant_lookups[variant_id] = file_lookup

            raw_integration = data.get("integration", {}) or {}
            active_variant = str(raw_integration.get("active_variant") or "")
            selected_files = variant_lookups.get(active_variant, {})
            integration_root = str(raw_integration.get("root") or ".")
            effective_files, effective_lookup = [], {}
            for file_id, relative in (raw_integration.get("files", {}) or {}).items():
                item = self._file_item(integration_root, relative, active_variant or None, file_id, "integration", True)
                effective_files.append(item); effective_lookup[file_id] = item; all_assets.append(item)
                if item["integrity"]["status"] == "missing":
                    warnings.append("生效文件 %s：文件缺失" % file_id)
            resource = raw_integration.get("resource")
            resource_item = None
            if resource:
                resource_item = self._file_item(".", resource, active_variant or None, "resource", "integration", True)
                effective_files.append(resource_item); all_assets.append(resource_item)
                if resource_item["integrity"]["status"] == "missing":
                    warnings.append("生效资源：文件缺失")
                elif resource_item.get("missing_references"):
                    warnings.append("生效资源：Godot 引用缺失")

            checks = []
            for file_id, effective in effective_lookup.items():
                if effective["is_image"]:
                    check = self._copy_check(file_id, selected_files.get(file_id), effective)
                    checks.append(check)
                    if check["status"] != "matched":
                        warnings.append("生效文件 %s：%s" % (file_id, check["label"]))
            expected_uris = []
            if resource:
                expected_uris.append("res://" + str(resource).replace("\\", "/"))
            else:
                expected_uris.extend("res://" + str(Path(integration_root) / str(relative)).replace("\\", "/") for relative in (raw_integration.get("files", {}) or {}).values())
            owners = raw_integration.get("owners", []) or []
            if raw_integration.get("owner"):
                owners = [raw_integration.get("owner")]
            for owner in owners:
                check = self._owner_check(owner, expected_uris)
                checks.append(check)
                if check["status"] != "matched":
                    warnings.append("Godot 所有者 %s：%s" % (owner, check["label"]))
            if resource_item and resource_item.get("missing_references"):
                checks.append({"id": "resource", "kind": "Godot 依赖", "status": "missing", "label": "引用文件缺失"})

            declared = str(raw_integration.get("status") or "not_integrated")
            statuses = [item["integrity"]["status"] for item in effective_files] + [item["status"] for item in checks]
            if declared == "not_integrated" or not active_variant:
                verified = "not_integrated"
            elif "missing" in statuses:
                verified = "missing"
            elif "mismatch" in statuses:
                verified = "mismatch"
            elif not statuses:
                verified = "unknown"
            else:
                verified = "matched"

            relationships = [{"id": relation_id, "kind": relation_id, "object_id": str(target_id)} for relation_id, target_id in (data.get("relationships", {}) or {}).items()]
            missing_count = sum(item["integrity"]["status"] == "missing" for item in all_assets)
            mismatch_count = sum(check["status"] == "mismatch" for check in checks)
            result_objects.append({
                "id": object_id, "name": identity.get("display_name") or object_id,
                "type": identity.get("type") or "unknown", "subtype": identity.get("subtype"),
                "category": TYPE_CATEGORIES.get(str(identity.get("type") or ""), "未归类"),
                "manifest_path": str(manifest_path), "variants": variants, "assets": all_assets,
                "thumbnail_id": None, "relationships": relationships,
                "integration": {"declared_status": declared, "verified_status": verified, "active_variant": active_variant or None, "owner_resource": owners[0] if owners else None, "owners": owners, "resource": resource, "evidence": raw_integration.get("evidence"), "effective_files": effective_files, "bindings": checks},
                "warnings": warnings,
                "counts": {"concepts": sum(v["stage"] == "concept" for v in variants), "animations": sum(bool(v.get("animation")) for v in variants), "atlases": sum(a["kind"] == "atlas" and not a["effective"] for a in all_assets), "files": len(all_assets), "integrity": {"matched": len(all_assets) - missing_count, "mismatch": mismatch_count, "missing": missing_count, "unset": 0}},
                "statuses": sorted({v["approval"] for v in variants}),
            })

        object_map = {item["id"]: item for item in result_objects}
        for obj in result_objects:
            candidates = [asset for variant in obj["variants"] for asset in variant["files"] if asset["is_image"] and asset["role"] not in ("source", "preview_gif")]
            selected_ids = {variant["id"] for variant in obj["variants"] if variant["selection"] == "selected"}
            candidates.sort(key=lambda asset: (asset["stage"] != "asset", asset["variant_id"] not in selected_ids))
            obj["thumbnail_id"] = candidates[0]["id"] if candidates else None
        for obj in result_objects:
            for relation in obj["relationships"]:
                target = object_map.get(relation["object_id"])
                if target is None:
                    relation.update(status="missing", status_label="关联对象未登记", target_name=relation["object_id"], thumbnail_id=None)
                    obj["warnings"].append("对象关联 %s：关联对象未登记" % relation["id"])
                else:
                    relation.update(status="matched", status_label="关联对象可用", target_name=target["name"], target_category=target["category"], thumbnail_id=target["thumbnail_id"])

        result_objects.sort(key=lambda item: (CATEGORY_ORDER.get(item["category"], 9), item["name"].lower(), item["id"]))
        unique_files = {asset["id"] for obj in result_objects for asset in obj["assets"]}
        return {"manifest": str(main_path) if main_path else str(raw_manifest or self.default_manifest), "errors": errors, "objects": result_objects, "summary": {"objects": len(result_objects), "files": len(unique_files), "mismatches": sum(o["counts"]["integrity"]["mismatch"] for o in result_objects), "missing": sum(o["counts"]["integrity"]["missing"] for o in result_objects), "categories": {category: sum(o["category"] == category for o in result_objects) for category in CATEGORY_ORDER}}, "discovery": "manifest_only"}

    def resolve_file(self, asset_id):
        path = self.files.get(asset_id)
        return path if path is not None and path.is_file() else None

    def resolve_animation(self, asset_id):
        resolved = self.preview_items.get(asset_id)
        if not resolved:
            return None
        for uri in (resolved.get("unit_uri"), resolved.get("animation_uri"), resolved.get("projectile_uri")):
            path = _uri_path(self.project_root, uri) if uri else None
            if uri and (path is None or not path.is_file()):
                return None
        return dict(resolved, project_root=self.project_root)
