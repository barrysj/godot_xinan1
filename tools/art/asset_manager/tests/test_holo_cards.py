import json
import unittest
from unittest import mock
from pathlib import Path
from test_catalog import ProjectFixture, PNG_BYTES
from catalog import AssetCatalog
from server import PreviewManager


class HoloCardsTests(unittest.TestCase):
    def setUp(self):
        self.fixture = ProjectFixture()
        self.addCleanup(self.fixture.close)
        self.root = self.fixture.root
        self.fixture.text("game/art/holo_card_visual.gd", "extends Resource\n")
        self.fixture.text("run-holo-card.ps1", "param()\n")
        self.index = self.fixture.text("assets/art/asset_manifest.yaml",
            "schema_version: 3\nobjects:\n  holo_cards:\n    type: holo_card\n    root: assets/art/holo_cards\n")
        self.photo = self.fixture.file("assets/art/holo_cards/first/photo.jpg")
        self.review = self.fixture.file("assets/art/holo_cards/first/review.png")
        self.resource = self.fixture.text("assets/art/holo_cards/first/card.tres",
            '[gd_resource type="Resource" load_steps=3 format=3]\n'
            '[ext_resource type="Script" path="res://game/art/holo_card_visual.gd" id="s"]\n'
            '[ext_resource type="Texture2D" path="res://assets/art/holo_cards/first/photo.jpg" id="p"]\n'
            '[resource]\nscript = ExtResource("s")\nphoto = ExtResource("p")\n'
            'title = "我们的卡"\ncaption = "第一行\\n第二行"\n')
        self.catalog = AssetCatalog(self.root)

    def test_directory_discovers_card_and_uses_review_not_photo(self):
        result = self.catalog.scan()
        self.assertFalse(result["errors"])
        obj = result["objects"][0]
        self.assertEqual("holo_cards/first", obj["id"])
        self.assertEqual("我们的卡", obj["name"])
        self.assertEqual("闪卡", obj["category"])
        self.assertEqual(1, result["summary"]["categories"]["闪卡"])
        self.assertEqual(0, result["summary"]["categories"]["UI"])
        self.assertEqual("第一行\n第二行", obj["holo_card"]["caption"])
        thumbnail = next(a for a in obj["assets"] if a["id"] == obj["thumbnail_id"])
        self.assertEqual("review.png", thumbnail["name"])
        self.assertEqual("card", obj["variants"][0]["stage"])
        preview = obj["variants"][0]["previews"][0]
        self.assertTrue(preview["supported"])
        self.assertEqual("res://assets/art/holo_cards/first/card.tres", self.catalog.resolve_animation(preview["asset_id"])["card_uri"])

    def test_only_registered_directory_is_scanned(self):
        self.index.write_text("schema_version: 3\nobjects:\n", encoding="utf-8")
        self.assertEqual([], self.catalog.scan()["objects"])

    def test_missing_review_warns_without_generating_files(self):
        self.review.unlink()
        result = self.catalog.scan()
        self.assertEqual(1, result["summary"]["missing"])
        self.assertFalse(self.review.exists())
        self.assertIsNone(result["objects"][0]["thumbnail_id"])
        self.assertTrue(result["objects"][0]["variants"][0]["previews"][0]["supported"])

    def test_missing_photo_disables_preview(self):
        self.photo.unlink()
        obj = self.catalog.scan()["objects"][0]
        self.assertTrue(obj["warnings"])
        self.assertFalse(obj["variants"][0]["previews"][0]["supported"])

    def test_bad_card_does_not_break_other_assets(self):
        self.resource.write_text("[resource]\n", encoding="utf-8")
        result = self.catalog.scan()
        self.assertEqual(1, len(result["errors"]))
        self.assertEqual([], result["objects"])

    def test_collection_cannot_escape_allowed_root(self):
        self.index.write_text("schema_version: 3\nobjects:\n  cards:\n    type: holo_card\n    root: ../outside\n", encoding="utf-8")
        self.assertTrue(self.catalog.scan()["errors"])

    def test_photo_cannot_escape_card_directory(self):
        self.resource.write_text(self.resource.read_text(encoding="utf-8").replace("res://assets/art/holo_cards/first/photo.jpg", "res://../secret.jpg"), encoding="utf-8")
        self.assertTrue(self.catalog.scan()["errors"])

    def test_rescan_reads_changed_title_without_manifest_edit(self):
        self.catalog.scan()
        self.resource.write_text(self.resource.read_text(encoding="utf-8").replace("我们的卡", "另一张卡"), encoding="utf-8")
        self.assertEqual("另一张卡", self.catalog.scan()["objects"][0]["name"])

    def test_card_launch_uses_same_resource_and_no_render_flag(self):
        obj = self.catalog.scan()["objects"][0]
        resolved = self.catalog.resolve_animation(obj["variants"][0]["previews"][0]["asset_id"])
        engine = self.fixture.file("godot.exe", b"fixture")
        manager = PreviewManager(self.root)
        with mock.patch("server.shutil.which", return_value="pwsh.exe"), mock.patch("server.subprocess.Popen") as spawn:
            spawn.return_value.poll.return_value = None
            self.assertTrue(manager.start(resolved, str(engine))[0])
            args = spawn.call_args[0][0]
            self.assertIn("-Godot", args)
            self.assertEqual(resolved["card_uri"], args[args.index("-Card")+1])
            self.assertNotIn("-Mode", args)
            self.assertFalse(spawn.call_args[1]["shell"])
