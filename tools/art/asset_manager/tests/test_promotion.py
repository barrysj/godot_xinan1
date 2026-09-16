import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from promotion.promote_animation import runtime_name, plan, promote
from animation.motion_previews import write_yaml
from asset_manager.catalog import parse_simple_yaml


class PromotionTest(unittest.TestCase):
    def test_allowlist_rejects_tools_reviews_and_escape(self):
        for name in ['../x.png', '/x.png', 'parts/../../x.png', 'review/idle.png',
                     'generation.md', 'player.gd', 'cache/frame.png']:
            try:
                accepted = runtime_name(name)
            except ValueError:
                accepted = False
            self.assertFalse(accepted, name)
        for name in ['presentation.tscn', 'animations.tres', 'parts/body.png', 'atlas.png']:
            self.assertTrue(runtime_name(name))

    def fixture(self, root):
        candidate = root / 'design/concepts/sample/001'
        candidate.mkdir(parents=True)
        (root / 'assets/art/manifests').mkdir(parents=True)
        (root / 'resources').mkdir()
        write_yaml(root / 'assets/art/asset_manifest.yaml', {'objects': {'sample': 'manifests/sample.yaml'}})
        names = ['presentation.tscn', 'animations.tres', 'battle_animation.tres', 'battle_animation.frames.json', 'rig_manifest.json']
        rig = {'runtime_files': names, 'skeleton_actions': ['idle'], 'frame_actions': ['idle', 'death'], 'attack_modes': []}
        (candidate / 'rig_manifest.json').write_text(json.dumps(rig))
        (candidate / 'battle_animation.frames.json').write_text(json.dumps({'clips': {'idle': {}, 'death': {}}}))
        (candidate / 'animations.tres').write_text('&"idle": SubResource("a")')
        (candidate / 'presentation.tscn').write_text('[ext_resource path="res://design/concepts/sample/001/animations.tres"]')
        (candidate / 'battle_animation.tres').write_text('"name": &"idle"\n"name": &"death"')
        (root / 'resources/unit.tres').write_text('path="res://resources/old.tres"')
        manifest = {'variants': {'v': {'approval': 'approved', 'selection': 'selected', 'root': 'design/concepts/sample/001', 'files': {}}},
                    'integration': {'active_variant': 'v', 'root': 'assets/art/sample', 'owner': 'resources/unit.tres', 'resource': 'resources/old.tres'}}
        write_yaml(root / 'assets/art/manifests/sample.yaml', manifest)
        return candidate

    def test_repeat_promotion_is_identical_and_rewrites_dependencies(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.fixture(root)
            promote('sample', root=root)
            first = {p.relative_to(root): p.read_bytes() for p in (root / 'assets').rglob('*') if p.is_file()}
            promote('sample', root=root)
            second = {p.relative_to(root): p.read_bytes() for p in (root / 'assets').rglob('*') if p.is_file()}
            self.assertEqual(first, second)
            promote('sample', check=True, root=root)
            self.assertNotIn('design/concepts', (root / 'assets/art/sample/presentation.tscn').read_text())

    def test_invalid_dependency_fails_before_writes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            candidate = self.fixture(root)
            (candidate / 'presentation.tscn').write_text('[ext_resource path="res://design/concepts/sample/001/missing.png"]')
            with self.assertRaises(ValueError):
                promote('sample', root=root)
            self.assertFalse((root / 'assets/art/sample').exists())

    def test_unapproved_candidate_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.fixture(root)
            path = root / 'assets/art/manifests/sample.yaml'
            manifest = parse_simple_yaml(path)
            manifest['variants']['v']['approval'] = 'pending'
            write_yaml(path, manifest)
            with self.assertRaises(ValueError):
                plan('sample', root=root)


if __name__ == '__main__':
    unittest.main()
