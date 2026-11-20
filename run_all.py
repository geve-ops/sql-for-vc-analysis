"""Rebuild everything and check it, in one command.

    python run_all.py                    lint, build the database, test it, rebuild the case study
    python run_all.py --refresh          first pull the latest data from the source repos (see build_db.py)
    python run_all.py --update-expected  after a refresh: accept the new reference results as reviewed

Steps, in order (the first failure stops the run):
    1. Lint SQL and Python          sqlfluff and ruff, if installed (pip install -r requirements-dev.txt)
    2. Build the database           data/*.csv -> source tables -> analytics models
    3. Run every reference answer   all exercises execute
    4. Test the kit                 data-quality rules, reviewed results, capstone vs digest, checker rules
    5. Rebuild the case study       case_study/README.md, its charts, and the findings on README.md

Exit code 0 means every step passed.
"""

import importlib.util
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
SQL_DIRS = ["answers", "models", os.path.join("case_study", "queries"), os.path.join("tests", "data_quality")]


def step(title, args):
    print(f"\n== {title}", flush=True)
    result = subprocess.run([sys.executable, *args], cwd=HERE, check=False)
    if result.returncode != 0:
        sys.exit(f"\nFAILED: {title}")


def main():
    flags = sys.argv[1:]
    unknown = [f for f in flags if f not in ("--refresh", "--update-expected")]
    if unknown:
        sys.exit(__doc__)

    if importlib.util.find_spec("sqlfluff") and importlib.util.find_spec("ruff"):
        step("Lint SQL", ["-m", "sqlfluff", "lint", *SQL_DIRS])
        step("Lint Python", ["-m", "ruff", "check", "."])
        step("Check Python formatting", ["-m", "ruff", "format", "--check", "."])
    else:
        print("\n== Lint skipped (pip install -r requirements-dev.txt to enable)", flush=True)

    step("Build the database", ["build_db.py"] + (["--refresh"] if "--refresh" in flags else []))
    if "--update-expected" in flags:
        step(
            "Update expected results",
            ["-c", "import sys; sys.path.insert(0, 'tests'); import test_kit; test_kit.write_snapshots()"],
        )
    step("Run every reference answer", ["check.py", "--all"])
    step("Test the kit", ["-m", "unittest", "discover", "-s", "tests", "-v"])
    step("Rebuild the case study", [os.path.join("case_study", "build_report.py")])
    print("\nAll steps passed.")


if __name__ == "__main__":
    main()
