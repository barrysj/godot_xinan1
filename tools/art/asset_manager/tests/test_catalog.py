from __future__ import unicode_literals

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


class ProjectFixture(object):
    def __init__(self):
        self.temp = tempfile.TemporaryDirectory(prefix="art manager 中文 ")
        self.root = Path(self.temp.name)
        (self.root / "project.godot").write_text("[application]\n", encoding="utf-8")
        for relative in ("assets/art/manifests", "design/concepts", "resources/content/animations", "resources/content/characters", "game/content"):
            (self.root / relative).mkdir(parents=True, exist_ok=True)
        (self.root / "game/content/battle_animation_set.gd").write_text("extends Resource\n", encoding="utf-8")
        (self.root / "game/content/battle_projectile_style.gd").write_text("extends Resource\n", encoding="utf-8")
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
        lines = ["schema_version: 3", "objects:"]
        for object_id in objects:
            lines.append("  %s: manifests/%s.yaml" % (object_id, object_id))
        return self.text("assets/art/asset_manifest.yaml", "\n".join(lines) + "\n")

    def projectile_manifest(self):
        self.file("design/concepts/chalk/projectile/001/projectile.png")
        self.text(
            "design/concepts/chalk/projectile/001/projectile.tres",
            '[ext_resource type="Script" path="res://game/content/battle_projectile_style.gd" id="s"]\n',
        )
        self.text(
            "assets/art/manifests/chalk_projectile.yaml",
            """schema_version: 3
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
    root: design/concepts/chalk/projectile/001
    files:
      projectile: projectile.png
    resource: design/concepts/chalk/projectile/001/projectile.tres
""",
        )

    def character_manifest(self, selected="selected", approval="approved", integrated=True):
        self.file("design/concepts/chalk/chalk/001/concept.png")
        sheet = self.file("design/concepts/chalk/chalk/002/sheet.png")
        self.text("design/concepts/chalk/chalk/002/animation.frames.json", json.dumps({"clips": {"idle": {"poses": ["a", "b"], "fps": 6, "loop": True}}}))
        self.text(
            "design/concepts/chalk/chalk/002/animation.tres",
            '[ext_resource type="Script" path="res://game/content/battle_animation_set.gd" id="s"]\n'
            '[ext_resource type="Texture2D" path="res://design/concepts/chalk/chalk/002/sheet.png" id="t"]\n',
        )
        self.file("design/concepts/chalk/chalk/002/review/idle.gif", b"GIF89a fixture")
        formal = self.file("assets/art/characters/chalk/sheet.png", sheet.read_bytes())
        self.text(
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
  owner: resources/content/characters/chalk.tres
  root: assets/art/characters/chalk
  files:
    sheet: sheet.png
  resource: resources/content/animations/chalk.tres
"""
        self.text(
            "assets/art/manifests/chalk.yaml",
            """schema_version: 3
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
    root: design/concepts/chalk/chalk/001
    files:
      concept: concept.png
  asset_002:
    stage: asset
    version: 002
    selection: {selected}
    approval: {approval}
    root: design/concepts/chalk/chalk/002
    files:
      sheet: sheet.png
      frames: animation.frames.json
      gif_idle: review/idle.gif
    resource: design/concepts/chalk/chalk/002/animation.tres
    animation:
      frames: frames
    previews:
      gifs:
        idle: gif_idle
      godot:
        unit: res://resources/content/characters/chalk.tres
        animation: res://design/concepts/chalk/chalk/002/animation.tres
relationships:
  projectile: chalk_projectile
{integration}""".format(selected=selected, approval=approval, integration=integration),
        )
        return {"sheet": sheet, "formal": formal, "unit": unit}


class CatalogTests(unittest.TestCase):
    def setUp(self):
        self.fixture = ProjectFixture()

    def tearDown(self):
        self.fixture.close()

    def scan(self):
        return AssetCatalog(self.fixture.root).scan(self.fixture.root / "assets/art/asset_manifest.yaml")

    def test_manifest_is_only_discovery_source_and_loads_stage_files_gif_and_clips(self):
        self.fixture.character_manifest(); self.fixture.install_index(["chalk"])
        self.fixture.file("assets/art/characters/unregistered/stray.png")
        result = self.scan()
        self.assertEqual("manifest_only", result["discovery"])
        self.assertEqual(1, len(result["objects"]))
        obj = result["objects"][0]
        self.assertEqual({"concept", "asset"}, {variant["stage"] for variant in obj["variants"]})
        asset = next(item for item in obj["variants"] if item["id"] == "asset_002")
        self.assertEqual("序列帧动画", asset["animation"]["label"])
        self.assertEqual(["idle"], [clip["id"] for clip in asset["animation"]["clips"]])
        self.assertEqual(1, asset["summary"]["images"])
        self.assertEqual(1, asset["summary"]["animations"])
        self.assertEqual("matched", asset["summary"]["validation_status"])
        self.assertTrue(asset["summary"]["thumbnail_id"])
        self.assertEqual({"gif", "godot"}, {item["type"] for item in asset["previews"]})
        resource = next(item for item in asset["files"] if item["name"].endswith(".tres"))
        self.assertEqual("动画资源", resource["kind_label"])
        self.assertFalse(any("stray.png" in item["path"] for item in obj["assets"]))

    def test_relationship_resolves_target_thumbnail_and_navigation_identity(self):
        self.fixture.character_manifest(); self.fixture.projectile_manifest(); self.fixture.install_index(["chalk", "chalk_projectile"])
        result = self.scan(); chalk = next(item for item in result["objects"] if item["id"] == "chalk")
        relation = chalk["relationships"][0]
        self.assertEqual("matched", relation["status"])
        self.assertEqual("粉笔弹体", relation["target_name"])
        self.assertTrue(relation["thumbnail_id"])

    def test_dynamic_hash_comparison_uses_paths_without_manifest_baselines(self):
        paths = self.fixture.character_manifest(); self.fixture.install_index(["chalk"])
        result = self.scan(); obj = result["objects"][0]
        check = next(item for item in obj["integration"]["bindings"] if item["id"] == "sheet")
        self.assertEqual("matched", check["status"])
        paths["sheet"].write_bytes(b"changed")
        result = self.scan(); obj = result["objects"][0]
        self.assertEqual("mismatch", next(item for item in obj["integration"]["bindings"] if item["id"] == "sheet")["status"])
        self.assertNotIn("baseline", str(result))
        paths["formal"].unlink()
        self.assertGreater(self.scan()["summary"]["missing"], 0)

    def test_owner_reference_is_derived_from_tres_without_manifest_compare_rule(self):
        paths = self.fixture.character_manifest(); self.fixture.install_index(["chalk"])
        obj = self.scan()["objects"][0]
        reference = next(item for item in obj["integration"]["bindings"] if item["kind"] == "Godot 引用")
        self.assertEqual("matched", reference["status"])
        paths["unit"].write_text("[resource]\n", encoding="utf-8")
        obj = self.scan()["objects"][0]
        self.assertEqual("mismatch", next(item for item in obj["integration"]["bindings"] if item["kind"] == "Godot 引用")["status"])

    def test_unselected_and_not_integrated_are_not_promoted(self):
        self.fixture.character_manifest(selected="unselected", approval="review", integrated=False); self.fixture.install_index(["chalk"])
        obj = self.scan()["objects"][0]; variant = next(item for item in obj["variants"] if item["id"] == "asset_002")
        self.assertEqual("unselected", variant["selection"])
        self.assertEqual("review", variant["approval"])
        self.assertEqual("not_integrated", obj["integration"]["verified_status"])

    def test_variant_validation_is_missing_when_a_registered_file_is_missing(self):
        paths = self.fixture.character_manifest(); self.fixture.install_index(["chalk"]); paths["sheet"].unlink()
        obj = self.scan()["objects"][0]; variant = next(item for item in obj["variants"] if item["id"] == "asset_002")
        self.assertEqual("missing", variant["summary"]["validation_status"])
        self.assertEqual("文件缺失", variant["summary"]["validation_label"])

    def test_project_schema_v3_preserves_all_objects_and_has_no_stored_hashes(self):
        project_root = Path(__file__).resolve().parents[4]
        result = AssetCatalog(project_root).scan(project_root / "assets/art/asset_manifest.yaml")
        objects = {obj["id"] for obj in result["objects"]}
        self.assertTrue({"guard", "archer", "guard_shield", "battle_courtyard", "battle_lab", "battle_classroom", "chalk_spirit", "chalk_projectile"}.issubset(objects))
        chalk = next(obj for obj in result["objects"] if obj["id"] == "chalk_spirit")
        asset_006 = next(variant for variant in chalk["variants"] if variant["id"] == "asset_006")
        gif_previews = [preview for preview in asset_006["previews"] if preview["type"] == "gif"]
        self.assertEqual(["attack"], [preview["id"] for preview in gif_previews])
        self.assertTrue(gif_previews[0]["supported"])
        self.assertEqual(0, result["summary"]["mismatches"])
        self.assertEqual(0, result["summary"]["missing"])
        for manifest in (project_root / "assets/art/manifests").glob("*.yaml"):
            self.assertNotIn("sha256:", manifest.read_text(encoding="utf-8"))
            self.assertNotIn("resource_reference", manifest.read_text(encoding="utf-8"))

    def test_only_project_local_manifest_path_is_accepted(self):
        self.fixture.install_index([])
        result = AssetCatalog(self.fixture.root).scan(Path(self.fixture.temp.name).parent / "outside.yaml")
        self.assertEqual(0, len(result["objects"])); self.assertIn("越出当前项目", result["errors"][0]["message"])

    def test_wrong_schema_is_rejected(self):
        manifest = self.fixture.text("assets/art/old.yaml", "schema_version: 2\nobjects:\n")
        result = AssetCatalog(self.fixture.root).scan(manifest)
        self.assertIn("schema_version 3", result["errors"][0]["message"])

    def test_missing_godot_reference_is_reported(self):
        resource = self.fixture.text("resources/content/animations/broken.tres", '[ext_resource type="Texture2D" path="res://assets/art/characters/missing.png" id="t"]\n')
        info = godot_resource_info(resource, self.fixture.root)
        self.assertEqual(["res://assets/art/characters/missing.png"], info["missing_references"])


class PreviewTests(unittest.TestCase):
    def setUp(self):
        self.fixture = ProjectFixture(); self.engine = self.fixture.file("Godot.exe", b"")

    def tearDown(self):
        self.fixture.close()

    @mock.patch("server.subprocess.Popen")
    @mock.patch("server.shutil.which", return_value="C:/Program Files/PowerShell/7/pwsh.exe")
    def test_preview_uses_explicit_unit_animation_and_projectile_without_shell(self, which, popen):
        process = mock.Mock(); process.poll.return_value = None; popen.return_value = process
        manager = PreviewManager(self.fixture.root)
        resolved = {"script": self.fixture.root / "run-motion-preview.ps1", "unit_uri": "res://resources/content/characters/chalk.tres", "animation_uri": "res://resources/content/animations/chalk.tres", "projectile_uri": "res://resources/content/animations/projectile.tres"}
        ok, message = manager.start(resolved, str(self.engine))
        self.assertTrue(ok); self.assertIn("准备预览", message)
        command = popen.call_args[0][0]
        self.assertIn("-EnsureImport", command)
        self.assertEqual(["-Unit", resolved["unit_uri"], "-Animation", resolved["animation_uri"], "-Projectile", resolved["projectile_uri"]], command[-6:])
        self.assertFalse(popen.call_args[1]["shell"])

    def test_preview_rejects_untrusted_script(self):
        ok, message = PreviewManager(self.fixture.root).start({"script": self.fixture.root / "other.ps1", "unit_uri": "res://bad.tres"}, str(self.engine))
        self.assertFalse(ok); self.assertIn("不受信", message)


class ServerSecurityTests(unittest.TestCase):
    def setUp(self):
        self.fixture = ProjectFixture(); self.server = ArtManagerServer(("127.0.0.1", 0), Handler, self.fixture.root)
        self.thread = threading.Thread(target=self.server.serve_forever); self.thread.daemon = True; self.thread.start()

    def tearDown(self):
        self.server.shutdown(); self.server.server_close(); self.thread.join(timeout=2); self.fixture.close()

    def _scan(self):
        self.fixture.character_manifest(); manifest = self.fixture.install_index(["chalk"])
        port = self.server.server_address[1]; connection = http.client.HTTPConnection("127.0.0.1", port, timeout=3)
        body = json.dumps({"manifest": str(manifest)}).encode("utf-8")
        connection.request("POST", "/api/scan", body=body, headers={"Content-Type": "application/json", "Content-Length": str(len(body)), "X-Art-Token": self.server.token})
        response = connection.getresponse(); payload = json.loads(response.read().decode("utf-8")); return connection, response, payload

    def test_cross_site_launch_and_unknown_file_id_are_rejected(self):
        port = self.server.server_address[1]; connection = http.client.HTTPConnection("127.0.0.1", port, timeout=3)
        body = json.dumps({"manifest": self.server.default_manifest}).encode("utf-8")
        connection.request("POST", "/api/scan", body=body, headers={"Content-Type": "application/json", "Content-Length": str(len(body)), "X-Art-Token": self.server.token, "Origin": "https://example.invalid"})
        response = connection.getresponse(); response.read(); self.assertEqual(403, response.status)
        connection.request("GET", "/api/file?id=..%2F..%2Fsecret&token={}".format(self.server.token))
        response = connection.getresponse(); response.read(); self.assertEqual(404, response.status); connection.close()

    def test_registered_gif_is_served_as_playable_image(self):
        connection, response, payload = self._scan(); self.assertEqual(200, response.status)
        asset = next(item for item in payload["objects"][0]["variants"] if item["id"] == "asset_002")
        gif = next(item for item in asset["files"] if item["role"] == "preview_gif")
        connection.request("GET", "/api/file?id={}&token={}".format(gif["id"], self.server.token))
        response = connection.getresponse(); content = response.read()
        self.assertEqual(200, response.status); self.assertEqual("image/gif", response.getheader("Content-Type")); self.assertTrue(content.startswith(b"GIF89a")); connection.close()

    @mock.patch("server.pick_manifest_path")
    def test_manifest_picker_returns_project_file(self, picker):
        manifest = self.fixture.install_index([]); picker.return_value = str(manifest)
        port = self.server.server_address[1]; connection = http.client.HTTPConnection("127.0.0.1", port, timeout=3)
        body = json.dumps({"initial": str(manifest)}).encode("utf-8")
        connection.request("POST", "/api/pick-manifest", body=body, headers={"Content-Type": "application/json", "Content-Length": str(len(body)), "X-Art-Token": self.server.token})
        response = connection.getresponse(); payload = json.loads(response.read().decode("utf-8"))
        self.assertEqual(200, response.status); self.assertTrue(payload["selected"]); self.assertEqual(str(manifest), payload["path"]); connection.close()


if __name__ == "__main__":
    unittest.main()
