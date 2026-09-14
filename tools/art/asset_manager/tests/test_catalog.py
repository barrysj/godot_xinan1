from __future__ import unicode_literals

import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import sys

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from catalog import AssetCatalog, godot_resource_info  # noqa: E402
from server import PreviewManager  # noqa: E402


PNG_BYTES = b"\x89PNG\r\n\x1a\n"


class ProjectFixture(object):
    def __init__(self):
        self.temp = tempfile.TemporaryDirectory(prefix="art manager 中文 ")
        self.root = Path(self.temp.name)
        (self.root / "project.godot").write_text("[application]\n", encoding="utf-8")
        for relative in (
            "assets/art",
            "design/concepts",
            "resources/content/animations",
            "resources/content/characters",
            "game/content",
        ):
            (self.root / relative).mkdir(parents=True, exist_ok=True)
        (self.root / "game/content/battle_animation_set.gd").write_text("extends Resource\n", encoding="utf-8")
        (self.root / "game/content/battle_effect_set.gd").write_text("extends Resource\n", encoding="utf-8")
        (self.root / "run-motion-preview.ps1").write_text("param()\n", encoding="utf-8")

    def close(self):
        self.temp.cleanup()

    def image(self, relative):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(PNG_BYTES)
        return path

    def animation(self, relative, texture_relative, effect=False):
        path = self.root / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        script = "battle_effect_set.gd" if effect else "battle_animation_set.gd"
        clip = "burst" if effect else "idle"
        path.write_text(
            "\n".join(
                [
                    '[gd_resource type="Resource" format=3]',
                    '[ext_resource type="Script" path="res://game/content/%s" id="script"]' % script,
                    '[ext_resource type="Texture2D" path="res://%s" id="sheet"]' % texture_relative,
                    '[sub_resource type="SpriteFrames" id="frames"]',
                    'animations = [{"frames": [{"duration": 1.0}], "loop": true, "name": &"%s", "speed": 4.0}]' % clip,
                    '[resource]',
                    'script = ExtResource("script")',
                ]
            ),
            encoding="utf-8",
        )
        return path


class CatalogTests(unittest.TestCase):
    def setUp(self):
        self.fixture = ProjectFixture()

    def tearDown(self):
        self.fixture.close()

    def test_multiple_art_and_animation_versions_stay_on_one_object(self):
        first = self.fixture.image("assets/art/characters/chalk/concept_a.png")
        second = self.fixture.image("assets/art/characters/chalk/concept_b.png")
        self.fixture.animation("resources/content/animations/chalk_a.tres", first.relative_to(self.fixture.root).as_posix())
        self.fixture.animation("resources/content/animations/chalk_b.tres", second.relative_to(self.fixture.root).as_posix())
        manifest = self.fixture.root / "assets/art/asset_manifest.yaml"
        manifest.write_text(
            """version: 1
assets:
  characters:
    chalk:
      concept_a:
        file: assets/art/characters/chalk/concept_a.png
        type: character_concept
        status: concept
        animation_resource: resources/content/animations/chalk_a.tres
      concept_b:
        file: assets/art/characters/chalk/concept_b.png
        type: battle_sprite_sheet
        status: review
        animation_resource: resources/content/animations/chalk_b.tres
""",
            encoding="utf-8",
        )
        result = AssetCatalog(self.fixture.root).scan([self.fixture.root / "assets/art"])
        self.assertEqual(1, len(result["objects"]))
        obj = result["objects"][0]
        self.assertEqual("chalk", obj["id"])
        self.assertEqual(2, obj["counts"]["animations"])
        self.assertEqual(4, obj["counts"]["files"])
        animation_items = [item for item in obj["assets"] if item["kind"] == "animation"]
        self.assertEqual({"concept_a", "concept_b"}, {item["version"] for item in animation_items})
        self.assertEqual(["idle"], [clip["id"] for clip in animation_items[0]["clips"]])

    def test_concept_directory_object_id_joins_manifest_object(self):
        final = self.fixture.image("assets/art/characters/chalk/battle.png")
        self.fixture.image("design/concepts/chalk-task/chalk/001/concept.png")
        (self.fixture.root / "assets/art/asset_manifest.yaml").write_text(
            """version: 1
assets:
  characters:
    chalk:
      battle:
        file: assets/art/characters/chalk/battle.png
        type: battle_sprite_sheet
        status: review
""",
            encoding="utf-8",
        )
        result = AssetCatalog(self.fixture.root).scan(
            [self.fixture.root / "assets/art", self.fixture.root / "design/concepts"]
        )
        self.assertEqual(1, len(result["objects"]))
        obj = result["objects"][0]
        self.assertEqual("chalk", obj["id"])
        self.assertEqual("人物", obj["category"])
        self.assertEqual(1, obj["counts"]["concepts"])
        self.assertEqual(1, obj["counts"]["atlases"])

    def test_chinese_space_path_and_unclassified_asset_are_discoverable(self):
        self.fixture.image("assets/art/characters/粉笔 精灵/portrait.png")
        self.fixture.image("assets/art/misc/stray.png")
        result = AssetCatalog(self.fixture.root).scan([self.fixture.root / "assets/art"])
        by_id = {item["id"]: item for item in result["objects"]}
        self.assertEqual("人物", by_id["粉笔 精灵"]["category"])
        self.assertEqual("未归类", by_id["misc"]["category"])

    def test_empty_missing_overlapping_and_external_roots(self):
        empty = self.fixture.root / "design/concepts"
        missing = empty / "不存在"
        outside = Path(self.fixture.temp.name).parent
        result = AssetCatalog(self.fixture.root).scan(
            [empty, missing, self.fixture.root / "assets/art", self.fixture.root / "assets/art", outside]
        )
        messages = [item["message"] for item in result["errors"]]
        self.assertIn("目录不存在", messages)
        self.assertIn("仅支持本项目的 assets/art 与 design/concepts", messages)
        self.assertEqual(2, len(result["roots"]))

    def test_effect_resource_is_kept_but_preview_is_disabled(self):
        sheet = self.fixture.image("assets/art/effects/shield/burst.png")
        effect = self.fixture.animation(
            "assets/art/effects/shield/burst.tres",
            sheet.relative_to(self.fixture.root).as_posix(),
            effect=True,
        )
        result = AssetCatalog(self.fixture.root).scan([self.fixture.root / "assets/art"])
        obj = result["objects"][0]
        resource = next(item for item in obj["assets"] if item["path"] == str(effect))
        self.assertEqual("特效", obj["category"])
        self.assertEqual("BattleEffectSet", resource["resource_type"])
        self.assertFalse(resource["preview_supported"])
        self.assertIn("暂不支持", resource["preview_reason"])

    def test_missing_godot_reference_blocks_preview(self):
        resource = self.fixture.root / "resources/content/animations/broken.tres"
        resource.write_text(
            '[ext_resource type="Script" path="res://game/content/battle_animation_set.gd" id="s"]\n'
            '[ext_resource type="Texture2D" path="res://assets/art/characters/missing.png" id="t"]\n',
            encoding="utf-8",
        )
        info = godot_resource_info(resource, self.fixture.root)
        self.assertFalse(info["preview_supported"])
        self.assertIn("资源引用缺失", info["preview_reason"])


class PreviewTests(unittest.TestCase):
    def setUp(self):
        self.fixture = ProjectFixture()
        self.engine = self.fixture.root / "Godot.exe"
        self.engine.write_bytes(b"")

    def tearDown(self):
        self.fixture.close()

    @mock.patch("server.subprocess.Popen")
    @mock.patch("server.shutil.which", return_value="C:/Program Files/PowerShell/7/pwsh.exe")
    def test_preview_uses_fixed_script_and_resource_arguments_without_shell(self, which, popen):
        process = mock.Mock()
        process.poll.return_value = None
        popen.return_value = process
        manager = PreviewManager(self.fixture.root)
        resolved = {
            "script": self.fixture.root / "run-motion-preview.ps1",
            "resource_uri": "res://resources/content/animations/chalk.tres",
        }
        ok, message = manager.start(resolved, str(self.engine))
        self.assertTrue(ok)
        self.assertIn("已启动", message)
        args, kwargs = popen.call_args
        self.assertEqual("C:/Program Files/PowerShell/7/pwsh.exe", args[0][0])
        self.assertEqual("-File", args[0][2])
        self.assertEqual("-Animation", args[0][-2])
        self.assertEqual("res://resources/content/animations/chalk.tres", args[0][-1])
        self.assertFalse(kwargs["shell"])

    def test_preview_rejects_untrusted_script(self):
        manager = PreviewManager(self.fixture.root)
        ok, message = manager.start(
            {"script": self.fixture.root / "other.ps1", "resource_uri": "res://bad.tres"},
            str(self.engine),
        )
        self.assertFalse(ok)
        self.assertIn("不受信", message)


if __name__ == "__main__":
    unittest.main()
