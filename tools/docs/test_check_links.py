import tempfile
import unittest
from pathlib import Path

from check_links import anchors, check


class LinkChecks(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / 'docs/combat').mkdir(parents=True)
        (self.root / 'readme.md').write_text('[规则](docs/combat/rules.md)', encoding='utf-8')
        (self.root / 'docs/combat/rules.md').write_text('# 战斗规则\n\n## 行动时序\n', encoding='utf-8')

    def test_moved_document_with_unicode_anchor(self):
        (self.root / 'docs/combat/combat-01.md').write_text('# COMBAT-01 · 移动\n[规则](rules.md#行动时序)\n', encoding='utf-8')
        _, ids, _, errors = check(self.root)
        self.assertEqual(errors, [])
        self.assertEqual(set(ids), {'COMBAT-01'})

    def test_missing_migration_target_and_anchor_are_reported(self):
        (self.root / 'docs/combat/combat-01.md').write_text('# COMBAT-01\n[旧](gone.md)\n[规则](rules.md#不存在)\n', encoding='utf-8')
        errors = check(self.root)[3]
        self.assertEqual(len(errors), 2)
        self.assertIn('missing anchor', errors[1])

    def test_code_examples_and_external_urls_are_not_local_links(self):
        (self.root / 'docs/combat/rules.md').write_text('# 规则\n[网页](https://example.com/#missing)\n```markdown\n[示例](missing.md)\n```\n', encoding='utf-8')
        self.assertEqual(check(self.root)[3], [])

    def test_duplicate_ids_and_obsolete_directory_are_rejected(self):
        (self.root / 'docs/combat/one.md').write_text('# COMBAT-01\n', encoding='utf-8')
        (self.root / 'docs/implementation').mkdir()
        (self.root / 'docs/implementation/two.md').write_text('# COMBAT-01\n', encoding='utf-8')
        errors = check(self.root)[3]
        self.assertEqual(len(errors), 2)

    def test_spaced_filenames_and_repeated_headings(self):
        (self.root / 'docs/combat/My Guide.md').write_text('# Guide\n## Step\n## Step\n', encoding='utf-8')
        (self.root / 'docs/combat/rules.md').write_text('[说明](<My Guide.md#step-1>)\n', encoding='utf-8')
        self.assertEqual(check(self.root)[3], [])
        self.assertIn('step-1', anchors('## Step\n## Step\n'))


if __name__ == '__main__':
    unittest.main()
