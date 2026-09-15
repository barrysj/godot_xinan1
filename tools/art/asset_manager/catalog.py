"""Manifest-driven catalog for the Cyber Pop Campus art desk.

Only objects, variants and files explicitly registered by the project manifest
are managed. Directory roots are retained as a project-local validation scope;
they never create catalog entries.
"""

from __future__ import unicode_literals

import ast
import hashlib
import json
import os
import re
from pathlib import Path


IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp", ".svg"}
ANIMATION_EXTENSIONS = {".tres", ".res"}
CATEGORY_ORDER = {"场景": 0, "人物": 1, "UI": 2, "特效": 3, "未归类": 4}
TYPE_CATEGORIES = {
    "character": "人物",
    "enemy": "人物",
    "background": "场景",
    "scene": "场景",
    "ui": "UI",
    "effect": "特效",
}
CLIP_LABELS = {
    "idle": "待机", "move": "移动", "attack": "攻击", "cast": "施法",
    "hurt": "受击", "critical": "濒危", "death": "退场", "burst": "爆发",
}
ROLE_KINDS = {
    "concept": ("concept", "概念图"),
    "atlas": ("atlas", "图集"),
    "sprite_sheet": ("atlas", "图集"),
    "image": ("image", "图片"),
    "source": ("source", "处理来源"),
    "frame_metadata": ("metadata", "帧元数据"),
    "animation_resource": ("animation", "动画资源"),
    "effect_resource": ("effect_animation", "特效资源"),
    "projectile_resource": ("resource", "弹体资源"),
    "preview_gif": ("preview", "GIF 预览"),
    "review": ("review", "评审证据"),
    "dependency": ("resource", "依赖资源"),
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


def normalize_roots(raw_roots, allowed_roots=None):
    """Validate optional project-local roots without using them for discovery."""
    roots, errors, seen = [], [], set()
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
        if not any(_inside(root, parent) for parent in effective):
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


def _sha256(path):
    digest = hashlib.sha256()
    try:
        with Path(path).open("rb") as handle:
            for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                digest.update(chunk)
    except OSError:
        return None
    return digest.hexdigest()


def _integrity(path, baseline):
    baseline = str(baseline or "").strip().lower()
    if not Path(path).is_file():
        return {"status": "missing", "label": "文件缺失", "baseline": baseline or None, "actual": None}
    actual = _sha256(path)
    if not baseline:
        return {"status": "unset", "label": "未设基线", "baseline": None, "actual": actual}
    if actual == baseline:
        return {"status": "matched", "label": "一致", "baseline": baseline, "actual": actual}
    return {"status": "mismatch", "label": "不一致", "baseline": baseline, "actual": actual}


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
    project_root = find_project_root(path)
    missing_refs = []
    if project_root:
        for reference in re.findall(r'path="res://([^"]+)"', text):
            target = (project_root / reference.replace("/", os.sep)).resolve()
            if not target.exists():
                missing_refs.append("res://" + reference)
    return {"resource_type": resource_type, "project_root": str(project_root) if project_root else None, "missing_references": missing_refs}


def _registered_path(project_root, raw_path):
    path = (Path(project_root) / str(raw_path or "")).resolve()
    return path if _inside(path, project_root) else None


def _uri_path(project_root, uri):
    value = str(uri or "")
    return _registered_path(project_root, value[6:]) if value.startswith("res://") else None


def _kind_for(role, path):
    if role in ROLE_KINDS:
        return ROLE_KINDS[role]
    if Path(path).suffix.lower() in ANIMATION_EXTENSIONS:
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
            clips.append({
                "id": clip_id,
                "name": CLIP_LABELS.get(clip_id, clip_id),
                "frames": len(clip.get("poses", [])),
                "fps": clip.get("fps"),
                "loop": clip.get("loop"),
            })
    elif isinstance(data.get("regions"), list):
        clips.append({"id": "burst", "name": "爆发", "frames": len(data["regions"]), "fps": data.get("fps"), "loop": False})
    return clips


def _preview_target_info(config, project_root):
    unit = str(config.get("unit") or "")
    animation = str(config.get("animation") or "")
    projectile = str(config.get("projectile") or "")
    if not unit and not animation:
        return False, "Godot 预览未登记 Unit 或 Animation", None
    for label, uri in (("Unit", unit), ("Animation", animation), ("Projectile", projectile)):
        if not uri:
            continue
        path = _uri_path(project_root, uri)
        if path is None or not path.is_file():
            return False, "%s 资源缺失：%s" % (label, uri), None
    if animation:
        info = godot_resource_info(_uri_path(project_root, animation), project_root)
        if info["resource_type"] != "BattleAnimationSet":
            return False, "Animation 不是 BattleAnimationSet", None
        if info["missing_references"]:
            return False, "动画引用缺失：" + "、".join(info["missing_references"][:3]), None
    script = Path(project_root) / "run-motion-preview.ps1"
    if not script.is_file():
        return False, "项目缺少 run-motion-preview.ps1", None
    return True, "可预览", {"script": script, "unit_uri": unit or None, "animation_uri": animation or None, "projectile_uri": projectile or None}


class AssetCatalog(object):
    def __init__(self, project_root):
        self.project_root = Path(project_root).resolve()
        self.allowed_roots = [self.project_root / "assets" / "art", self.project_root / "design" / "concepts"]
        self.files = {}
        self.preview_items = {}

    def _file_item(self, raw, variant_id=None, file_id=None, effective=False, inherited_hash=None):
        raw = raw if isinstance(raw, dict) else {}
        path = _registered_path(self.project_root, raw.get("path"))
        if path is None:
            path = self.project_root / "__invalid_manifest_path__"
        role = str(raw.get("role") or "file")
        kind, label = _kind_for(role, path)
        item = {
            "id": _asset_id(path), "file_id": file_id, "name": path.name, "path": str(path),
            "manifest_path": str(raw.get("path") or ""), "kind": kind, "kind_label": label,
            "role": role, "variant_id": variant_id, "effective": effective, "exists": path.is_file(),
            "is_image": path.suffix.lower() in IMAGE_EXTENSIONS and path.is_file(),
            "integrity": _integrity(path, raw.get("sha256") or inherited_hash),
            "metadata": {key: value for key, value in raw.items() if key not in ("path", "role", "sha256")},
        }
        if path.suffix.lower() in ANIMATION_EXTENSIONS and path.is_file():
            item.update(godot_resource_info(path, self.project_root))
        if path.is_file():
            self.files[item["id"]] = path
        return item

    def _load_objects(self):
        main_path = self.project_root / "assets" / "art" / "asset_manifest.yaml"
        if not main_path.is_file():
            return [], [{"path": str(main_path), "message": "Manifest 不存在"}]
        main = parse_simple_yaml(main_path)
        if main.get("schema_version") != 2:
            return [], [{"path": str(main_path), "message": "仅支持 Manifest schema_version 2"}]
        loaded, errors = [], []
        for object_id, raw_path in (main.get("object_manifests", {}) or {}).items():
            path = _registered_path(self.project_root, raw_path)
            if path is None or not path.is_file():
                errors.append({"path": str(raw_path), "message": "对象 Manifest 不存在或越出项目"})
                continue
            data = parse_simple_yaml(path)
            if (data.get("object", {}) or {}).get("id") != object_id:
                errors.append({"path": str(path), "message": "对象 ID 与主索引不一致"})
                continue
            loaded.append((object_id, path, data))
        return loaded, errors

    def _reference_check(self, raw):
        raw = raw if isinstance(raw, dict) else {}
        source = _registered_path(self.project_root, raw.get("source"))
        target = str(raw.get("target") or "")
        if source is None or not source.is_file():
            return {"status": "missing", "label": "来源缺失", "source": str(raw.get("source") or ""), "target": target}
        source_integrity = _integrity(source, raw.get("source_sha256"))
        if source_integrity["status"] != "matched":
            return {"status": source_integrity["status"], "label": source_integrity["label"], "source": str(source), "target": target, "integrity": source_integrity}
        target_path = _uri_path(self.project_root, target)
        if not target:
            return {"status": "unset", "label": "未登记目标", "source": str(source), "target": target}
        if target_path is None or not target_path.is_file():
            return {"status": "missing", "label": "目标缺失", "source": str(source), "target": target}
        if target not in _read_text(source):
            return {"status": "mismatch", "label": "引用不一致", "source": str(source), "target": target}
        return {"status": "matched", "label": "引用一致", "source": str(source), "target": target, "integrity": source_integrity}

    def _binding_check(self, raw, selected_files, effective_files):
        raw = raw if isinstance(raw, dict) else {}
        mode = str(raw.get("compare") or "baseline_hash")
        if mode == "resource_reference":
            result = self._reference_check(raw)
            result["compare"] = mode
            return result
        selected = selected_files.get(raw.get("selected_file"))
        effective = effective_files.get(raw.get("effective_file"))
        if effective is None:
            return {"status": "missing", "label": "未登记生效文件", "compare": mode}
        if mode == "sha256_equal":
            if selected is None:
                return {"status": "unselected", "label": "未登记选取文件", "compare": mode}
            statuses = (selected["integrity"]["status"], effective["integrity"]["status"])
            if "missing" in statuses:
                return {"status": "missing", "label": "映射文件缺失", "compare": mode}
            if "mismatch" in statuses or selected["integrity"]["actual"] != effective["integrity"]["actual"]:
                return {"status": "mismatch", "label": "选取与生效不一致", "compare": mode}
            if "unset" in statuses:
                return {"status": "unset", "label": "映射未设基线", "compare": mode}
            return {"status": "matched", "label": "选取与生效一致", "compare": mode}
        status = effective["integrity"]["status"]
        return {"status": status, "label": effective["integrity"]["label"], "compare": mode}

    def _relationship_check(self, relation_id, raw, object_registry):
        relation = dict(raw, id=relation_id)
        target_id = str(raw.get("object_id") or "")
        target = object_registry.get(target_id)
        if target is None:
            return dict(relation, status="missing", status_label="关联对象未登记")
        resource_ref = str(raw.get("resource_ref") or "")
        if not resource_ref:
            return dict(relation, status="matched", status_label="对象已登记")
        parts = resource_ref.split(".")
        if len(parts) == 3 and parts[0] == target_id and parts[1] == "files":
            file_id = parts[2]
            registered = ((target.get("integration", {}) or {}).get("effective_files", {}) or {}).get(file_id)
        elif len(parts) == 4 and parts[0] == target_id and parts[2] == "files":
            variant_id, file_id = parts[1], parts[3]
            variant = (target.get("variants", {}) or {}).get(variant_id)
            registered = (variant.get("files", {}) or {}).get(file_id) if isinstance(variant, dict) else None
        else:
            return dict(relation, status="mismatch", status_label="resource_ref 格式无效")
        path = _registered_path(self.project_root, registered.get("path")) if isinstance(registered, dict) else None
        if path is None or not path.is_file():
            return dict(relation, status="missing", status_label="关联资源未登记或缺失")
        return dict(relation, status="matched", status_label="关联一致")

    def scan(self, raw_roots):
        self.files, self.preview_items = {}, {}
        roots, errors = normalize_roots(raw_roots, self.allowed_roots)
        loaded, manifest_errors = self._load_objects()
        errors.extend(manifest_errors)
        result_objects = []
        object_registry = {object_id: data for object_id, _path, data in loaded}
        for object_id, manifest_path, data in loaded:
            identity = data.get("object", {}) or {}
            variants, all_assets, selected_lookups, warnings = [], [], {}, []
            for variant_id, raw_variant in (data.get("variants", {}) or {}).items():
                if not isinstance(raw_variant, dict):
                    continue
                files, file_lookup = [], {}
                for file_id, raw_file in (raw_variant.get("files", {}) or {}).items():
                    item = self._file_item(raw_file, variant_id, file_id)
                    files.append(item); file_lookup[file_id] = item; all_assets.append(item)
                    if item["integrity"]["status"] != "matched":
                        warnings.append("%s/%s：%s" % (variant_id, file_id, item["integrity"]["label"]))
                animation = raw_variant.get("animation", {}) or {}
                clip_source = file_lookup.get(animation.get("clips_from"))
                clips = _load_frame_clips(clip_source["path"]) if clip_source else []
                raw_previews = raw_variant.get("previews", {}) or {}
                previews = []
                for clip_id, preview in (raw_previews.get("gifs", {}) or {}).items():
                    linked = file_lookup.get(preview.get("file")) if isinstance(preview, dict) else None
                    previews.append({"id": clip_id, "type": "gif", "file_id": linked["id"] if linked else None, "supported": bool(linked and linked["exists"]), "reason": "可播放" if linked and linked["exists"] else "GIF 文件缺失"})
                godot = raw_previews.get("godot")
                if isinstance(godot, dict):
                    supported, reason, resolved = _preview_target_info(godot, self.project_root)
                    preview_asset_id = _preview_id(object_id, variant_id)
                    if supported:
                        self.preview_items[preview_asset_id] = resolved
                    previews.append({"id": "godot", "asset_id": preview_asset_id, "type": "godot", "supported": supported, "reason": reason, "unit": godot.get("unit"), "animation": godot.get("animation"), "projectile": godot.get("projectile")})
                variant = {
                    "id": variant_id, "version": str(raw_variant.get("version") or variant_id),
                    "stage": str(raw_variant.get("stage") or "asset"),
                    "selection": str(raw_variant.get("selection") or "unknown"),
                    "approval": str(raw_variant.get("approval") or "unknown"),
                    "approval_evidence": raw_variant.get("approval_evidence"), "files": files,
                    "animation": {"representation": animation.get("representation"), "resource_file": animation.get("resource_file"), "clips_from": animation.get("clips_from"), "clips": clips} if animation else None,
                    "previews": previews, "metadata": raw_variant.get("metadata", {}) or {},
                }
                variants.append(variant); selected_lookups[variant_id] = file_lookup

            raw_integration = data.get("integration", {}) or {}
            active_variant = str(raw_integration.get("active_variant") or "")
            selected_files = selected_lookups.get(active_variant, {})
            effective_files, effective_lookup = [], {}
            for file_id, raw_file in (raw_integration.get("effective_files", {}) or {}).items():
                item = self._file_item(raw_file, active_variant or None, file_id, True)
                effective_files.append(item); effective_lookup[file_id] = item; all_assets.append(item)
                if item["integrity"]["status"] != "matched":
                    warnings.append("生效文件 %s：%s" % (file_id, item["integrity"]["label"]))
            bindings = []
            for binding_id, raw_binding in (raw_integration.get("bindings", {}) or {}).items():
                check = self._binding_check(raw_binding, selected_files, effective_lookup)
                check["id"] = binding_id
                bindings.append(check)
                if check["status"] != "matched":
                    warnings.append("生效映射 %s：%s" % (binding_id, check["label"]))
            declared = str(raw_integration.get("status") or "unknown")
            statuses = [item["integrity"]["status"] for item in effective_files] + [item["status"] for item in bindings]
            if declared == "not_integrated" or not active_variant:
                verified = "not_integrated"
            elif "missing" in statuses:
                verified = "missing"
            elif "mismatch" in statuses:
                verified = "mismatch"
            elif "unset" in statuses or "unselected" in statuses or not statuses:
                verified = "unknown"
            else:
                verified = "matched"
            relationships = [self._relationship_check(key, value, object_registry) for key, value in (data.get("relationships", {}) or {}).items() if isinstance(value, dict)]
            for relation in relationships:
                if relation["status"] != "matched":
                    warnings.append("对象关联 %s：%s" % (relation["id"], relation["status_label"]))
            integrity_statuses = [item["integrity"]["status"] for item in all_assets]
            integrity_counts = {status: integrity_statuses.count(status) for status in ("matched", "mismatch", "missing", "unset")}
            thumbnail_candidates = [item for item in all_assets if item["is_image"] and not item["effective"] and item["role"] not in ("source", "review", "preview_gif")]
            result_objects.append({
                "id": object_id, "name": identity.get("display_name") or object_id,
                "type": identity.get("type") or "unknown", "subtype": identity.get("subtype"),
                "category": TYPE_CATEGORIES.get(str(identity.get("type") or ""), "未归类"),
                "manifest_path": str(manifest_path), "variants": variants, "assets": all_assets,
                "thumbnail_id": thumbnail_candidates[0]["id"] if thumbnail_candidates else None,
                "relationships": relationships,
                "integration": {"declared_status": declared, "verified_status": verified, "active_variant": active_variant or None, "owner_resource": raw_integration.get("owner_resource"), "evidence": raw_integration.get("evidence"), "effective_files": effective_files, "bindings": bindings},
                "warnings": warnings,
                "counts": {"concepts": sum(v["stage"] == "concept" for v in variants), "animations": sum(bool(v.get("animation")) for v in variants), "atlases": sum(a["kind"] == "atlas" and not a["effective"] for a in all_assets), "files": len(all_assets), "integrity": integrity_counts},
                "statuses": sorted({v["approval"] for v in variants}),
            })
        result_objects.sort(key=lambda item: (CATEGORY_ORDER.get(item["category"], 9), item["name"].lower(), item["id"]))
        unique_files = {asset["id"] for obj in result_objects for asset in obj["assets"]}
        return {"roots": [str(root) for root in roots], "errors": errors, "objects": result_objects, "summary": {"objects": len(result_objects), "files": len(unique_files), "mismatches": sum(o["counts"]["integrity"]["mismatch"] for o in result_objects), "missing": sum(o["counts"]["integrity"]["missing"] for o in result_objects), "categories": {category: sum(o["category"] == category for o in result_objects) for category in CATEGORY_ORDER}}, "discovery": "manifest_only"}

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
