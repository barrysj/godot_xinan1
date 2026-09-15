from __future__ import unicode_literals

import hashlib
import http.client
import json
import tempfile
import threading
import unittest
from pathlib import Path
from unittest import mock

import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from catalog import AssetCatalog, godot_resource_info  # noqa: E402
from server import ArtManagerServer, Handler, PreviewManager  # noqa: E402


PNG_BYTES = b"\x89PNG\r\n\x1a\nfixture"


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


class ProjectFixture(object):
    def __init__(self):
        self.temp = tempfile.TemporaryDirectory(prefix="art manager 中文 ")
        self.root = Path(self.temp.name)
        (self.root / "project.godot").write_text("[application]\n", encoding="utf-8")
        for relative in ("assets/art/manifests", "design/concepts", "resources/content/animations", "resources/content/characters", "game/content"):
            (self.root / relative).mkdir(parents=True, exist_ok=True)
        (self.root / "game/content/battle_animation_set.gd").write_text("extends Resource\n", encoding="utf-8")
        (self.root / "run-motion-preview.ps1").write_text("param()\n", encoding="utf-8")

    def close(self):
        self.temp.cleanup()

    def file(self, relative, content=PNG_BYTES):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)
        return path

    def text(self, relative, content):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        return path

    def install_index(self, objects):
        lines = ["schema_version: 2", "object_manifests:"]
        for object_id in objects:
            lines.append("  %s: assets/art/manifests/%s.yaml" % (object_id, object_id))
        self.text("assets/art/asset_manifest.yaml", "\n".join(lines) + "\n")

    def character_manifest(self, selected="selected", approval="approved", integrated=True):
        concept = self.file("design/concepts/chalk/chalk/001/concept.png")
        sheet = self.file("design/concepts/chalk/chalk/002/sheet.png")
        frames = self.text("design/concepts/chalk/chalk/002/animation.frames.json", json.dumps({"clips": {"idle": {"poses": ["a", "b"], "fps": 6, "loop": True}}}))
        animation = self.text(
            "design/concepts/chalk/chalk/002/animation.tres",
            '[ext_resource type="Script" path="res://game/content/battle_animation_set.gd" id="s"]\n'
            '[ext_resource type="Texture2D" path="res://design/concepts/chalk/chalk/002/sheet.png" id="t"]\n',
        )
        gif = self.file("design/concepts/chalk/chalk/002/review/idle.gif", b"GIF89a fixture")
        formal = self.file("assets/art/characters/chalk/sheet.png", sheet.read_bytes())
        formal_animation = self.text(
            "resources/content/animations/chalk.tres",
            '[ext_resource type="Script" path="res://game/content/battle_animation_set.gd" id="s"]\n'
            '[ext_resource type="Texture2D" path="res://assets/art/characters/chalk/sheet.png" id="t"]\n',
        )
        unit = self.text(
            "resources/content/characters/chalk.tres",
            '[ext_resource type="Resource" path="res://resources/content/animations/chalk.tres" id="a"]\n'
            '[resource]\nbattle_animation = ExtResource("a")\n',
        )
        integration = "" if not integrated else """
integration:
  status: active
  active_variant: asset_002
  owner_resource: resources/content/characters/chalk.tres
  effective_files:
    sheet:
      path: assets/art/characters/chalk/sheet.png
      role: atlas
      sha256: {formal_hash}
    animation:
      path: resources/content/animations/chalk.tres
      role: animation_resource
      sha256: {formal_animation_hash}
  bindings:
    sheet_copy:
      compare: sha256_equal
      selected_file: sheet
      effective_file: sheet
    animation_baseline:
      compare: baseline_hash
      selected_file: animation
      effective_file: animation
    unit_animation:
      compare: resource_reference
      source: resources/content/characters/chalk.tres
      source_sha256: {unit_hash}
      target: res://resources/content/animations/chalk.tres
""".format(formal_hash=digest(formal), formal_animation_hash=digest(formal_animation), unit_hash=digest(unit))
        self.text(
            "assets/art/manifests/chalk.yaml",
            """schema_version: 2
object:
  id: chalk
  display_name: 粉笔精灵
  type: character
  subtype: enemy
variants:
  concept_001:
    stage: concept
    version: 001
    selection: selected
    approval: approved
    files:
      concept:
        path: design/concepts/chalk/chalk/001/concept.png
        role: concept
        sha256: {concept_hash}
  asset_002:
    stage: asset
    version: 002
    selection: {selected}
    approval: {approval}
    files:
      sheet:
        path: design/concepts/chalk/chalk/002/sheet.png
        role: atlas
        sha256: {sheet_hash}
      frames:
        path: design/concepts/chalk/chalk/002/animation.frames.json
        role: frame_metadata
        sha256: {frames_hash}
      animation:
        path: design/concepts/chalk/chalk/002/animation.tres
        role: animation_resource
        sha256: {animation_hash}
      gif_idle:
        path: design/concepts/chalk/chalk/002/review/idle.gif
        role: preview_gif
        sha256: {gif_hash}
    animation:
      representation: sprite_frames
      resource_file: animation
      clips_from: frames
    previews:
      gifs:
        idle:
          file: gif_idle
      godot:
        unit: res://resources/content/characters/chalk.tres
        animation: res://design/concepts/chalk/chalk/002/animation.tres
relationships:
  projectile:
    kind: projectile
    object_id: chalk_projectile
    resource_ref: chalk_projectile.files.runtime_resource
{integration}""".format(
                concept_hash=digest(concept), sheet_hash=digest(sheet), frames_hash=digest(frames),
                animation_hash=digest(animation), gif_hash=digest(gif), selected=selected,
                approval=approval, integration=integration,
            ),
        )
        self.install_index(["chalk"])
        return {"sheet": sheet, "formal": formal, "unit": unit}


class CatalogTests(unittest.TestCase):
    def setUp(self):
        self.fixture = ProjectFixture()

    def tearDown(self):
        self.fixture.close()

    def test_manifest_is_only_discovery_source_and_loads_versions_gif_clips_relationship(self):
        self.fixture.character_manifest()
        self.fixture.file("assets/art/characters/unregistered/stray.png")
        result = AssetCatalog(self.fixture.root).scan([self.fixture.root / "assets/art", self.fixture.root / "design/concepts"])
        self.assertEqual("manifest_only", result["discovery"])
        self.assertEqual(1, len(result["objects"]))
        obj = result["objects"][0]
        self.assertEqual("chalk", obj["id"])
        self.assertEqual("粉笔精灵", obj["name"])
        self.assertEqual(2, len(obj["variants"]))
        asset = next(item for item in obj["variants"] if item["id"] == "asset_002")
        self.assertEqual("002", asset["version"])
        self.assertEqual(["idle"], [clip["id"] for clip in asset["animation"]["clips"]])
        self.assertEqual(2, asset["animation"]["clips"][0]["frames"])
        self.assertEqual({"gif", "godot"}, {item["type"] for item in asset["previews"]})
        self.assertEqual("chalk_projectile", obj["relationships"][0]["object_id"])
        self.assertEqual("missing", obj["relationships"][0]["status"])
        self.assertFalse(any("stray.png" in item["path"] for item in obj["assets"]))
        self.assertEqual("matched", obj["integration"]["verified_status"])

    def test_qualified_relationship_resolves_target_active_variant_file(self):
        self.fixture.character_manifest()
        projectile = self.fixture.file("assets/art/effects/chalk_projectile/projectile.tres", b"projectile")
        self.fixture.text(
            "assets/art/manifests/chalk_projectile.yaml",
            """schema_version: 2
object:
  id: chalk_projectile
  display_name: 粉笔弹体
  type: effect
  subtype: projectile
variants:
  asset_001:
    stage: asset
    version: 001
    selection: selected
    approval: approved
    files:
      runtime_resource:
        path: assets/art/effects/chalk_projectile/projectile.tres
        role: projectile_resource
        sha256: {file_hash}
integration:
  status: active
  active_variant: asset_001
  effective_files:
    runtime_resource:
      path: assets/art/effects/chalk_projectile/projectile.tres
      role: projectile_resource
      sha256: {file_hash}
""".format(file_hash=digest(projectile)),
        )
        self.fixture.install_index(["chalk", "chalk_projectile"])
        result = AssetCatalog(self.fixture.root).scan([self.fixture.root / "assets/art"])
        chalk = next(item for item in result["objects"] if item["id"] == "chalk")
        self.assertEqual("matched", chalk["relationships"][0]["status"])

    def test_real_hash_mismatch_and_missing_file_are_reported_without_rebaselining(self):
        paths = self.fixture.character_manifest()
        catalog = AssetCatalog(self.fixture.root)
        paths["sheet"].write_bytes(b"changed")
        result = catalog.scan([self.fixture.root / "design/concepts"])
        obj = result["objects"][0]
        self.assertGreater(obj["counts"]["integrity"]["mismatch"], 0)
        self.assertEqual("mismatch", next(item for item in obj["integration"]["bindings"] if item["id"] == "sheet_copy")["status"])
        paths["formal"].unlink()
        result = catalog.scan([self.fixture.root / "assets/art"])
        self.assertGreater(result["summary"]["missing"], 0)

    def test_unselected_and_not_integrated_are_not_promoted(self):
        self.fixture.character_manifest(selected="unselected", approval="review", integrated=False)
        obj = AssetCatalog(self.fixture.root).scan([self.fixture.root / "assets/art"])["objects"][0]
        variant = next(item for item in obj["variants"] if item["id"] == "asset_002")
        self.assertEqual("unselected", variant["selection"])
        self.assertEqual("review", variant["approval"])
        self.assertEqual("not_integrated", obj["integration"]["verified_status"])

    def test_project_migration_preserves_base_and_chalk_objects_and_baselines(self):
        project_root = Path(__file__).resolve().parents[4]
        result = AssetCatalog(project_root).scan([project_root / "assets/art", project_root / "design/concepts"])
        objects = {obj["id"]: obj for obj in result["objects"]}
        self.assertTrue({"guard", "archer", "guard_shield", "battle_courtyard",
                         "battle_lab", "battle_classroom", "chalk_spirit", "chalk_projectile"}.issubset(objects))
        self.assertEqual(0, result["summary"]["mismatches"])
        self.assertEqual(0, result["summary"]["missing"])
        self.assertTrue(all(obj["integration"]["verified_status"] == "matched" for obj in result["objects"]))

    def test_empty_missing_overlapping_and_external_roots(self):
        self.fixture.install_index([])
        empty = self.fixture.root / "design/concepts"
        missing = empty / "不存在"
        outside = Path(self.fixture.temp.name).parent
        result = AssetCatalog(self.fixture.root).scan([empty, missing, self.fixture.root / "assets/art", self.fixture.root / "assets/art", outside])
        messages = [item["message"] for item in result["errors"]]
        self.assertIn("目录不存在", messages)
        self.assertIn("仅支持本项目的 assets/art 与 design/concepts", messages)
        self.assertEqual(2, len(result["roots"]))

    def test_missing_godot_reference_is_reported(self):
        resource = self.fixture.text(
            "resources/content/animations/broken.tres",
            '[ext_resource type="Script" path="res://game/content/battle_animation_set.gd" id="s"]\n'
            '[ext_resource type="Texture2D" path="res://assets/art/characters/missing.png" id="t"]\n',
        )
        info = godot_resource_info(resource, self.fixture.root)
        self.assertEqual(["res://assets/art/characters/missing.png"], info["missing_references"])


class PreviewTests(unittest.TestCase):
    def setUp(self):
        self.fixture = ProjectFixture()
        self.engine = self.fixture.file("Godot.exe", b"")

    def tearDown(self):
        self.fixture.close()

    @mock.patch("server.subprocess.Popen")
    @mock.patch("server.shutil.which", return_value="C:/Program Files/PowerShell/7/pwsh.exe")
    def test_preview_uses_explicit_unit_animation_and_projectile_without_shell(self, which, popen):
        process = mock.Mock(); process.poll.return_value = None; popen.return_value = process
        manager = PreviewManager(self.fixture.root)
        resolved = {
            "script": self.fixture.root / "run-motion-preview.ps1",
            "unit_uri": "res://resources/content/characters/chalk.tres",
            "animation_uri": "res://resources/content/animations/chalk.tres",
            "projectile_uri": "res://resources/content/animations/projectile.tres",
        }
        ok, message = manager.start(resolved, str(self.engine))
        self.assertTrue(ok); self.assertIn("已启动", message)
        args, kwargs = popen.call_args
        command = args[0]
        self.assertEqual("C:/Program Files/PowerShell/7/pwsh.exe", command[0])
        self.assertEqual(["-Unit", resolved["unit_uri"], "-Animation", resolved["animation_uri"], "-Projectile", resolved["projectile_uri"]], command[-6:])
        self.assertFalse(kwargs["shell"])

    def test_preview_rejects_untrusted_script(self):
        manager = PreviewManager(self.fixture.root)
        ok, message = manager.start({"script": self.fixture.root / "other.ps1", "unit_uri": "res://bad.tres"}, str(self.engine))
        self.assertFalse(ok); self.assertIn("不受信", message)


class ServerSecurityTests(unittest.TestCase):
    def setUp(self):
        self.fixture = ProjectFixture()
        self.server = ArtManagerServer(("127.0.0.1", 0), Handler, self.fixture.root)
        self.thread = threading.Thread(target=self.server.serve_forever); self.thread.daemon = True; self.thread.start()

    def tearDown(self):
        self.server.shutdown(); self.server.server_close(); self.thread.join(timeout=2); self.fixture.close()

    def test_cross_site_launch_and_unknown_file_id_are_rejected(self):
        port = self.server.server_address[1]
        connection = http.client.HTTPConnection("127.0.0.1", port, timeout=3)
        body = json.dumps({"roots": []}).encode("utf-8")
        connection.request("POST", "/api/scan", body=body, headers={"Content-Type": "application/json", "Content-Length": str(len(body)), "X-Art-Token": self.server.token, "Origin": "https://example.invalid"})
        response = connection.getresponse(); response.read(); self.assertEqual(403, response.status)
        connection.request("GET", "/api/file?id=..%2F..%2Fsecret&token={}".format(self.server.token))
        response = connection.getresponse(); response.read(); self.assertEqual(404, response.status); connection.close()

    def test_registered_gif_is_served_as_playable_image(self):
        self.fixture.character_manifest()
        port = self.server.server_address[1]
        connection = http.client.HTTPConnection("127.0.0.1", port, timeout=3)
        body = json.dumps({"roots": [str(self.fixture.root / "design/concepts")]}).encode("utf-8")
        connection.request("POST", "/api/scan", body=body, headers={"Content-Type": "application/json", "Content-Length": str(len(body)), "X-Art-Token": self.server.token})
        response = connection.getresponse(); payload = json.loads(response.read().decode("utf-8")); self.assertEqual(200, response.status)
        variant = next(item for item in payload["objects"][0]["variants"] if item["id"] == "asset_002")
        gif = next(item for item in variant["files"] if item["role"] == "preview_gif")
        connection.request("GET", "/api/file?id={}&token={}".format(gif["id"], self.server.token))
        response = connection.getresponse(); content = response.read()
        self.assertEqual(200, response.status); self.assertEqual("image/gif", response.getheader("Content-Type")); self.assertTrue(content.startswith(b"GIF89a")); connection.close()


if __name__ == "__main__":
    unittest.main()
