"""Tests for the kit itself: reference answers, the checker's rules, and the files that go with each exercise.

Run them with `python run_all.py`, or on their own with `python -m unittest discover tests`.
After a data refresh, `python run_all.py --update-expected` rewrites tests/expected/ from the reference answers.
"""

import json
import os
import re
import sys
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, ROOT)

import check  # noqa: E402

EXPECTED = os.path.join(HERE, "expected")


def snapshot(con, ex):
    sql, _ = check.reference(ex)
    cols, rows = check.run(con, sql)
    return {"columns": list(cols), "rows": [[check.norm(v) for v in r] for r in rows]}


def write_snapshots():
    os.makedirs(EXPECTED, exist_ok=True)
    con = check.connect()
    for ex in check.exercises():
        with open(os.path.join(EXPECTED, f"{ex}.json"), "w", encoding="utf-8", newline="\n") as f:
            json.dump(snapshot(con, ex), f, ensure_ascii=False, indent=1)
            f.write("\n")
    print(f"Wrote {len(check.exercises())} expected results to tests/expected/")


class ReferenceAnswers(unittest.TestCase):
    """Every reference answer runs and still returns the result that was reviewed by hand."""

    @classmethod
    def setUpClass(cls):
        cls.con = check.connect()

    def test_each_answer_matches_its_reviewed_result(self):
        for ex in check.exercises():
            with self.subTest(exercise=ex):
                path = os.path.join(EXPECTED, f"{ex}.json")
                self.assertTrue(os.path.exists(path), f"no tests/expected/{ex}.json")
                with open(path, encoding="utf-8") as f:
                    want = json.load(f)
                got = snapshot(self.con, ex)
                _, ordered = check.reference(ex)
                problem = check.difference(got["columns"], got["rows"], want["columns"], want["rows"], ordered)
                self.assertIsNone(problem, f"{ex}: {problem}")

    def test_capstone_matches_the_published_digest(self):
        # Top movers table in vc-dealflow-tracker/digests/2026-11-16.md (rank, company, momentum, this week),
        # as republished on 23 November 2026 after the tracker's scoring fix (tracker commit 683eb30).
        digest = [
            (1, "Axelera AI", 10, 6),
            (2, "Hack The Box", 5.75, 4),
            (3, "SolidKosmos", 4, 4),
            (4, "WeatherXM", 3.88, 2),
            (5, "Causaly", 2.75, 1),
            (6, "Bota Systems", 2.5, 0),
            (7, "TileDB (rebranded Tile.ai)", 2, 1),
            (8, "Satori Analytics", 1.88, 1),
            (9, "Open Cosmos (Open Cosmos Aegean)", 1.75, 1),
            (10, "OQ Technology", 1.5, 0),
        ]
        latest = self.con.sql("SELECT max(date) FROM scores").fetchall()[0][0].isoformat()
        if latest != "2026-11-16":
            self.skipTest(f"data runs to {latest}; the digest check applies to the 2026-11-16 data")
        sql, _ = check.reference("4.07")
        _, rows = check.run(self.con, sql)
        got = [(r[0], r[1], float(r[2]), r[3]) for r in rows]
        self.assertEqual(got, [(a, b, float(c), d) for a, b, c, d in digest])


class CheckerRules(unittest.TestCase):
    cols = ("company", "score")
    rows = (("A", 3), ("B", 2.0), ("C", None))

    def diff(self, my_cols, my_rows, ordered=True):
        return check.difference(my_cols, my_rows, self.cols, self.rows, ordered)

    def test_identical_result_passes(self):
        self.assertIsNone(self.diff(self.cols, self.rows))

    def test_column_names_do_not_matter(self):
        self.assertIsNone(self.diff(["name", "total"], self.rows))

    def test_numbers_match_within_tolerance(self):
        self.assertIsNone(self.diff(self.cols, [("A", 3.004), ("B", 2), ("C", None)]))
        self.assertIn("row 1", self.diff(self.cols, [("A", 3.05), ("B", 2), ("C", None)]))

    def test_wrong_order_fails_with_a_hint(self):
        msg = self.diff(self.cols, list(reversed(self.rows)))
        self.assertIn("order is not", msg)

    def test_order_ignored_when_not_asked_for(self):
        self.assertIsNone(self.diff(self.cols, list(reversed(self.rows)), ordered=False))

    def test_missing_row_fails(self):
        self.assertIn("expected 3 rows", self.diff(self.cols, self.rows[:2]))

    def test_extra_column_fails(self):
        self.assertIn("expected 2 columns", self.diff([*self.cols, "x"], [(*r, 1) for r in self.rows]))

    def test_null_is_not_zero(self):
        self.assertIsNotNone(self.diff(self.cols, [("A", 3), ("B", 2), ("C", 0)]))


class ExerciseFiles(unittest.TestCase):
    def test_sheets_stubs_and_answers_line_up(self):
        answers = check.exercises()
        titles = check.titles()
        self.assertEqual(sorted(titles), answers, "exercise sheets and answers/ list different ids")
        for ex in answers:
            with self.subTest(exercise=ex):
                stub = os.path.join(ROOT, "my_answers", f"{ex}.sql")
                self.assertTrue(os.path.exists(stub), f"no my_answers/{ex}.sql")
                with open(stub, encoding="utf-8") as f:
                    first = f.readline().strip()
                self.assertEqual(first, f"-- {ex} {titles[ex]}", f"my_answers/{ex}.sql title differs from the sheet")
                _, ordered = check.reference(ex)
                self.assertTrue(ordered, f"{ex}: every exercise states a sort order, so mark it '-- check: ordered'")

    def test_stubs_hold_no_answer(self):
        for ex in check.exercises():
            with open(os.path.join(ROOT, "my_answers", f"{ex}.sql"), encoding="utf-8") as f:
                code = re.sub(r"--[^\n]*", "", f.read()).strip()
            self.assertEqual(code, "", f"my_answers/{ex}.sql contains SQL; the committed stubs should be empty")


class DocsMatchTheRepository(unittest.TestCase):
    """The counts the README and the architecture page state must match the files."""

    DOCS = ("README.md", os.path.join("docs", "architecture.md"))

    def counts(self):
        def n(pattern):
            return len([f for f in os.listdir(os.path.join(ROOT, pattern[0])) if f.endswith(pattern[1])])

        return {
            r"(\d+) (?:graded )?exercises": len(check.exercises()),
            r"(\d+) data-quality(?:<br/>)?\s?rules": n(("tests/data_quality", ".sql")),
            r"(\d+) rules: zero rows": n(("tests/data_quality", ".sql")),
            r"(\d+) (?:clean, tested tables|tested models|models\b)": n(("models", ".sql")),
            r"(\d+) source tables": 6,
        }

    def test_stated_counts_are_true(self):
        for doc in self.DOCS:
            with open(os.path.join(ROOT, doc), encoding="utf-8") as f:
                text = f.read()
            for pattern, actual in self.counts().items():
                for stated in re.findall(pattern, text):
                    with self.subTest(doc=doc, claim=pattern):
                        self.assertEqual(int(stated), actual, f"{doc} states {stated}, the repository has {actual}")


if __name__ == "__main__":
    unittest.main()
