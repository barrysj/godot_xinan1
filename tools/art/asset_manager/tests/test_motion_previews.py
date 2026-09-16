"""Production path guards are independent from the read-only catalog/server."""
import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest

ART = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ART))
from animation.motion_previews import inside, write_yaml
from asset_manager.catalog import parse_simple_yaml


class ProductionPathsTest(unittest.TestCase):
    def test_parent_and_sibling_escape_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory) / 'cache'
            for path in [root, root / '../outside', Path(str(root) + '-sibling') / 'frame.png']:
                with self.assertRaises(ValueError):
                    inside(path, root)
            self.assertEqual(inside(root / 'job/frame.png', root), (root / 'job/frame.png').resolve())

    def test_manifest_round_trip_preserves_versions_and_approval(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'object.yaml'
            data = {'version': '006', 'approval': 'approved', 'metadata': {'size': [352, 352]},
                    'previews': {'gifs': {'ranged': 'gif_ranged'}}}
            write_yaml(path, data)
            self.assertEqual(parse_simple_yaml(path), data)


if __name__ == '__main__':
    unittest.main()
