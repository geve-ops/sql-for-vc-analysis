"""Rebuild everything and check it, in one command.

    python run_all.py                    build the database, test the kit, rebuild the case study
    python run_all.py --refresh          first pull the latest data from the source repos (see build_db.py)
    python run_all.py --update-expected  after a refresh: accept the new reference results as reviewed

Exit code 0 means every step passed.
"""

import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))


def step(title, args):
    print(f"\n== {title}", flush=True)
    result = subprocess.run([sys.executable, *args], cwd=HERE)
    if result.returncode != 0:
        sys.exit(f"\nFAILED: {title}")


def main():
    flags = sys.argv[1:]
    unknown = [f for f in flags if f not in ("--refresh", "--update-expected")]
    if unknown:
        sys.exit(__doc__)
    step("Build the database", ["build_db.py"] + (["--refresh"] if "--refresh" in flags else []))
    if "--update-expected" in flags:
        step("Update expected results", ["-c", "import sys; sys.path.insert(0, 'tests'); "
                                               "import test_kit; test_kit.write_snapshots()"])
    step("Run every reference answer", ["check.py", "--all"])
    step("Test the kit", ["-m", "unittest", "discover", "-s", "tests", "-v"])
    step("Rebuild the case study", [os.path.join("case_study", "build_report.py")])
    print("\nAll steps passed.")


if __name__ == "__main__":
    main()
