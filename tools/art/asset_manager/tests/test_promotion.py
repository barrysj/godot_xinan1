import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2]))
from promotion.promote_animation import runtime_name, plan, promote
from animation.motion_previews import prepare, write_yaml
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
        write_yaml(root / 'assets/art/asset_manifest.yaml', {'schema_version': 3, 'objects': {'sample': 'manifests/sample.yaml'}})
        names = ['presentation.tscn', 'animations.tres', 'battle_animation.tres', 'battle_animation.frames.json', 'rig_manifest.json']
        rig = {'runtime_files': names, 'skeleton_actions': ['idle'], 'frame_actions': ['idle', 'death'], 'attack_modes': []}
        (candidate / 'rig_manifest.json').write_text(json.dumps(rig))
        (candidate / 'battle_animation.frames.json').write_text(json.dumps({'clips': {'idle': {}, 'death': {}}}))
        (candidate / 'animations.tres').write_text('&"idle": SubResource("a")')
        (candidate / 'presentation.tscn').write_text('[ext_resource path="res://design/concepts/sample/001/animations.tres"]')
        (candidate / 'battle_animation.tres').write_text('"name": &"idle"\n"name": &"death"')
        (root / 'resources/unit.tres').write_text('path="res://resources/old.tres"')
        manifest = {'schema_version': 3, 'object': {'id': 'sample'}, 'variants': {'v': {'approval': 'approved', 'selection': 'selected', 'root': 'design/concepts/sample/001', 'files': {}}},
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

    def test_nested_collection_supports_promotion_and_preview_job(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.fixture(root)
            folder = root / 'assets/art/manifests'
            (folder / 'characters').mkdir()
            nested = folder / 'characters/sample.yaml'
            (folder / 'sample.yaml').rename(nested)
            write_yaml(root / 'assets/art/asset_manifest.yaml', {'schema_version': 3, 'objects': {'characters': 'manifests/characters.yaml'}})
            write_yaml(folder / 'characters.yaml', {'schema_version': 3, 'objects': {'sample': 'characters/sample.yaml'}})
            manifest = parse_simple_yaml(nested)
            manifest['variants']['v'].update(stage='asset', animation={'frames': 'frame_metadata'},
                resource='design/concepts/sample/001/battle_animation.tres',
                previews={'godot': {'unit': 'res://resources/unit.tres', 'animation': 'res://design/concepts/sample/001/battle_animation.tres'}})
            write_yaml(nested, manifest)
            promote('sample', root=root)
            promote('sample', check=True, root=root)
            job_path = prepare('', 'res://resources/unit.tres', 'Idle', root=root)
            job = json.loads(job_path.read_text())
            self.assertEqual(job['object_manifest'], 'assets/art/manifests/characters/sample.yaml')

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

    def test_frame_only_package_keeps_frames_but_not_source_provenance(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            candidate = self.fixture(root)
            (candidate / 'frames').mkdir()
            (candidate / 'frames/idle.png').write_bytes(b'frame')
            rig_path = candidate / 'rig_manifest.json'
            rig = json.loads(rig_path.read_text())
            rig['skeleton_actions'] = []
            rig['playback_metadata_only'] = True
            rig['runtime_files'] = [n for n in rig['runtime_files'] if n not in ('presentation.tscn', 'animations.tres')]
            rig['runtime_files'].append('frames/idle.png')
            rig_path.write_text(json.dumps(rig))
            metadata = candidate / 'battle_animation.frames.json'
            metadata.write_text(json.dumps({'source': 'design/concepts/private/video.mp4', 'clips': {'idle': {}, 'death': {}}}))
            with (candidate / 'battle_animation.tres').open('a') as output:
                output.write('\n[ext_resource path="res://design/concepts/sample/001/frames/idle.png"]')
            promote('sample', root=root)
            promote('sample', check=True, root=root)
            deployed = root / 'assets/art/sample'
            self.assertEqual((deployed / 'frames/idle.png').read_bytes(), b'frame')
            self.assertNotIn('source', json.loads((deployed / 'battle_animation.frames.json').read_text()))
            self.assertFalse((deployed / 'presentation.tscn').exists())

    def test_partial_hybrid_is_rejected_before_writing(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            candidate = self.fixture(root)
            rig_path = candidate / 'rig_manifest.json'
            rig = json.loads(rig_path.read_text())
            rig['runtime_files'].remove('animations.tres')
            rig_path.write_text(json.dumps(rig))
            with self.assertRaises(ValueError):
                promote('sample', root=root)
            self.assertFalse((root / 'assets/art/sample').exists())

    def test_over_budget_animation_fails_before_promotion(self):
        for text, budget in [('x' * 128, {'max_bytes': 64, 'max_keys': 8, 'max_cycle_seconds': 4}),
                             ('"times": PackedFloat32Array(0, 1, 2)', {'max_bytes': 1024, 'max_keys': 2, 'max_cycle_seconds': 4}),
                             ('length = 96', {'max_bytes': 1024, 'max_keys': 8, 'max_cycle_seconds': 4})]:
            with tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                candidate = self.fixture(root)
                rig_path = candidate / 'rig_manifest.json'
                rig = json.loads(rig_path.read_text())
                rig['animation_budget'] = budget
                rig_path.write_text(json.dumps(rig))
                with (candidate / 'animations.tres').open('a') as output:
                    output.write('\n' + text)
                with self.assertRaisesRegex(ValueError, 'budget'):
                    promote('sample', root=root)
                self.assertFalse((root / 'assets/art/sample').exists())


if __name__ == '__main__':
    unittest.main()
