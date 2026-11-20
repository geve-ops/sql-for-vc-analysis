"""Check your SQL answers against the reference answers.

    python check.py 1.03             run my_answers/1.03.sql and compare it with the reference result
    python check.py 1.03 --expected  show the expected result (not the SQL)
    python check.py --list           list exercises and which ones you have passed
    python check.py --all            run every reference answer (checks the kit itself)
    python check.py --run FILE.sql   run any .sql file, or a quoted query, and print the result

Rules: the number of columns and the values must match. Column names do not have to.
Row order matters only when the exercise asks for an order. Numbers match within 0.01.
"""

import datetime
import decimal
import glob
import os
import re
import sys

import duckdb

HERE = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(HERE, "dealflow.duckdb")
ANSWERS = os.path.join(HERE, "answers")
MINE = os.path.join(HERE, "my_answers")
TOLERANCE = 0.01
SHOW_ROWS = 15


def connect():
    if not os.path.exists(DB):
        sys.exit("dealflow.duckdb not found. Build it first:  python build_db.py")
    return duckdb.connect(DB, read_only=True)


def run(con, sql):
    """Return (column names, rows) for the last statement in sql."""
    rel = con.sql(sql)
    if rel is None:
        return [], []
    return rel.columns, rel.fetchall()


def norm(value):
    if isinstance(value, (decimal.Decimal, float)):
        return float(value)
    if isinstance(value, (datetime.date, datetime.datetime)):
        return value.isoformat()
    if isinstance(value, bool) or value is None:
        return value
    if isinstance(value, int):
        return float(value)
    return str(value)


def sort_key(row):
    return tuple((v is None, type(v).__name__, round(v, 2) if isinstance(v, float) else v) for v in row)


def same(a, b):
    if isinstance(a, float) and isinstance(b, float):
        return abs(a - b) <= TOLERANCE
    return a == b


def rows_match(r1, r2):
    return len(r1) == len(r2) and all(same(a, b) for a, b in zip(r1, r2))


def all_match(rows1, rows2):
    return len(rows1) == len(rows2) and all(rows_match(a, b) for a, b in zip(rows1, rows2))


def difference(my_cols, my_rows, ref_cols, ref_rows, ordered):
    """None when the two results match under the checking rules, else what differs first."""
    if len(my_cols) != len(ref_cols):
        return f"expected {len(ref_cols)} columns ({', '.join(ref_cols)}), you returned {len(my_cols)}."
    mine = [tuple(norm(v) for v in r) for r in my_rows]
    ref = [tuple(norm(v) for v in r) for r in ref_rows]
    if len(mine) != len(ref):
        return f"expected {len(ref)} rows, you returned {len(mine)}."
    if not ordered:
        mine, ref = sorted(mine, key=sort_key), sorted(ref, key=sort_key)
    for i, (a, b) in enumerate(zip(mine, ref), 1):
        if not rows_match(a, b):
            where = f"row {i}" if ordered else f"row {i} (after sorting both results)"
            msg = f"{where} differs.\n  yours:    {a}\n  expected: {b}"
            if ordered and all_match(sorted(mine, key=sort_key), sorted(ref, key=sort_key)):
                msg += "\n  The rows are right but the order is not. Check your ORDER BY."
            return msg
    return None


def table(cols, rows, limit=SHOW_ROWS):
    shown = [[("NULL" if v is None else str(v)) for v in r] for r in rows[:limit]]
    widths = [min(40, max([len(str(c))] + [len(r[i]) for r in shown])) for i, c in enumerate(cols)]
    fmt = lambda vals: "  ".join(str(v)[:40].ljust(w) for v, w in zip(vals, widths))
    out = [fmt(cols), fmt(["-" * w for w in widths])] + [fmt(r) for r in shown]
    if len(rows) > limit:
        out.append(f"... {len(rows) - limit} more rows ({len(rows)} in total)")
    else:
        out.append(f"({len(rows)} rows)")
    return "\n".join("  " + line for line in out)


def ex_id(arg):
    m = re.fullmatch(r"(\d)\.?(\d{1,2})", arg.strip())
    if not m:
        sys.exit(f"Exercise ids look like 1.03 or 4.07, not {arg!r}")
    return f"{m.group(1)}.{int(m.group(2)):02d}"


def reference(ex):
    path = os.path.join(ANSWERS, f"{ex}.sql")
    if not os.path.exists(path):
        sys.exit(f"No exercise {ex}. See: python check.py --list")
    with open(path, encoding="utf-8") as f:
        sql = f.read()
    return sql, "-- check: ordered" in sql


def compare(con, ex, quiet=False):
    ref_sql, ordered = reference(ex)
    mine_path = os.path.join(MINE, f"{ex}.sql")
    if not os.path.exists(mine_path):
        print(f"No answer yet. Write your query in my_answers/{ex}.sql")
        return False
    with open(mine_path, encoding="utf-8") as f:
        my_sql = f.read()
    if not re.sub(r"--[^\n]*", "", my_sql).strip():
        print(f"my_answers/{ex}.sql has no query yet.")
        return False

    try:
        my_cols, my_rows = run(con, my_sql)
    except duckdb.Error as e:
        print(f"Your query failed:\n  {str(e).strip()}")
        return False
    ref_cols, ref_rows = run(con, ref_sql)

    if not quiet:
        print(f"Your result:\n{table(my_cols, my_rows)}\n")

    problem = difference(my_cols, my_rows, ref_cols, ref_rows, ordered)
    if problem:
        print(f"NOT YET: {problem}")
        return False

    note = ""
    if [c.lower() for c in my_cols] != [c.lower() for c in ref_cols]:
        note = f"\n  (Column names differ, which is fine. Reference names: {', '.join(ref_cols)})"
    print(f"PASS {ex}{note}")
    with open(os.path.join(MINE, ".passed"), "a", encoding="utf-8") as f:
        f.write(ex + "\n")
    return True


def exercises():
    return sorted(os.path.basename(p)[:-4] for p in glob.glob(os.path.join(ANSWERS, "*.sql")))


def titles():
    found = {}
    for path in sorted(glob.glob(os.path.join(HERE, "exercises", "level*.md"))):
        with open(path, encoding="utf-8") as f:
            for m in re.finditer(r"^### (\d\.\d\d) (.+)$", f.read(), re.M):
                found[m.group(1)] = m.group(2).strip()
    return found


def main():
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")  # Greek headlines on a Windows console
    args = sys.argv[1:]
    if not args or args[0] in ("-h", "--help"):
        print(__doc__)
        return
    con = connect()

    if args[0] == "--run":
        if len(args) < 2:
            sys.exit("Usage: python check.py --run FILE.sql   or   python check.py --run \"SELECT ...\"")
        sql = args[1]
        if os.path.exists(sql):
            with open(sql, encoding="utf-8") as f:
                sql = f.read()
        try:
            cols, rows = run(con, sql)
        except duckdb.Error as e:
            sys.exit(f"Query failed:\n  {str(e).strip()}")
        print(table(cols, rows, limit=50))
        return

    if args[0] == "--list":
        passed_file = os.path.join(MINE, ".passed")
        passed = set(open(passed_file, encoding="utf-8").read().split()) if os.path.exists(passed_file) else set()
        names = titles()
        for ex in exercises():
            print(f"  [{'x' if ex in passed else ' '}] {ex}  {names.get(ex, '')}")
        print(f"\n  {len(passed & set(exercises()))} of {len(exercises())} passed")
        return

    if args[0] == "--all":
        failed = 0
        for ex in exercises():
            sql, ordered = reference(ex)
            try:
                cols, rows = run(con, sql)
                print(f"  ok    {ex}  {len(rows):>4} rows  {'ordered' if ordered else 'any order'}")
            except duckdb.Error as e:
                failed += 1
                print(f"  FAIL  {ex}  {str(e).strip()}")
        print(f"\n{len(exercises()) - failed} of {len(exercises())} reference answers ran.")
        sys.exit(1 if failed else 0)

    ex = ex_id(args[0])
    if "--expected" in args:
        sql, ordered = reference(ex)
        cols, rows = run(con, sql)
        print(f"Expected result for {ex} ({'order matters' if ordered else 'any order'}):\n{table(cols, rows, 50)}")
        return
    ok = compare(con, ex)
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
