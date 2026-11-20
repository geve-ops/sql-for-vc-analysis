"""Data-quality tests: every query in tests/data_quality/ returns the rows that break a rule.

A test passes when its query returns no rows. The first line of each file says what the rule is.
"""

import glob
import os
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

import check  # noqa: E402

RULES = sorted(glob.glob(os.path.join(HERE, "data_quality", "*.sql")))


class DataQuality(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.con = check.connect()

    def test_rules_exist(self):
        self.assertGreater(len(RULES), 0)

    def test_every_rule_holds(self):
        for path in RULES:
            name = os.path.basename(path)[:-4]
            with self.subTest(rule=name):
                with open(path, encoding="utf-8") as f:
                    sql = f.read()
                rule = sql.splitlines()[0].lstrip("- ").strip()
                cols, rows = check.run(self.con, sql)
                self.assertEqual(rows, [], f"{name}: {rule}\n{check.table(cols, rows, limit=10)}")


if __name__ == "__main__":
    unittest.main()
