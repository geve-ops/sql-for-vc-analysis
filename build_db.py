"""Build dealflow.duckdb from the CSV files in data/.

    python build_db.py              build the database from data/ (works from a fresh clone)
    python build_db.py --refresh    first copy the latest data from the two source repos into data/

The source repos are only needed for --refresh. Their location comes from, in order:
    --tracker PATH / --market-map PATH
    the DEALFLOW_TRACKER_DIR / MARKET_MAP_DIR environment variables
    ../vc-dealflow-tracker and ../greek-deeptech-market-map next to this folder

Tables:
    companies   market map dataset, one row per company (88)
    watchlist   tracker watchlist (69), with Greek fund tags
    scores      weekly score history, one row per company per weekly run
    pipeline    hand-kept analyst pipeline
    backtest    GitHub commits before and after known rounds
    signals     every item in every weekly snapshot (repos, news, jobs, grants), flattened
"""

import argparse
import csv
import glob
import json
import os
import shutil
import subprocess
import sys

import duckdb

HERE = os.path.dirname(os.path.abspath(__file__))
DATA = os.path.join(HERE, "data")
DB = os.path.join(HERE, "dealflow.duckdb")

TABLES = ["companies", "watchlist", "scores", "pipeline", "backtest", "signals"]

SIGNAL_COLUMNS = [
    ("snapshot_date", "DATE"),       # date of the weekly run
    ("company_id", "VARCHAR"),
    ("signal", "VARCHAR"),           # github_repo, news, job, grant
    ("item_id", "VARCHAR"),
    ("title", "VARCHAR"),            # repo name, headline, job title or grant title
    ("url", "VARCHAR"),
    ("event_date", "DATE"),          # repo last push, news published, job published, grant signed
    ("source", "VARCHAR"),           # GitHub org, news outlet, job board, CORDIS
    ("news_kind", "VARCHAR"),        # news only: funding or press
    ("lang", "VARCHAR"),             # news only
    ("location", "VARCHAR"),         # jobs only
    ("stars", "INTEGER"),            # repos only
    ("window_commits", "INTEGER"),   # repos only: commits in that week's window
    ("window_commits_bot", "INTEGER"),
    ("is_fork", "BOOLEAN"),
    ("grant_acronym", "VARCHAR"),    # grants only
    ("eu_contribution", "DOUBLE"),   # grants only: EU contribution to the whole project, EUR
    ("grant_status", "VARCHAR"),
]


# --- refresh: source repos -> data/ -------------------------------------------------------------

def day(value):
    return value[:10] if value else None


def flatten(snapshot):
    """One row per item in one weekly snapshot JSON."""
    date = day(snapshot["generated_at"])
    rows = []
    for cid, sig in snapshot["companies"].items():
        gh = sig.get("github") or {}
        for r in gh.get("repos") or []:
            rows.append({"signal": "github_repo", "item_id": f"{gh.get('org')}/{r['name']}", "title": r["name"],
                         "url": r.get("url"), "event_date": day(r.get("pushed_at")), "source": gh.get("org"),
                         "stars": r.get("stars"), "window_commits": r.get("window_commits", 0),
                         "window_commits_bot": r.get("window_commits_bot", 0), "is_fork": r.get("fork")})
        for n in (sig.get("news") or {}).get("items") or []:
            rows.append({"signal": "news", "item_id": n.get("id"), "title": n.get("title"), "url": n.get("url"),
                         "event_date": day(n.get("published")), "source": n.get("source"),
                         "news_kind": n.get("kind"), "lang": n.get("lang")})
        jobs = sig.get("jobs") or {}
        for j in jobs.get("postings") or []:
            rows.append({"signal": "job", "item_id": j.get("id"), "title": j.get("title"), "url": j.get("url"),
                         "event_date": day(j.get("published")), "source": jobs.get("source"),
                         "location": j.get("location")})
        for g in (sig.get("grants") or {}).get("items") or []:
            rows.append({"signal": "grant", "item_id": g.get("id"), "title": g.get("title"), "url": g.get("url"),
                         "event_date": day(g.get("signed")), "source": "CORDIS",
                         "grant_acronym": g.get("acronym"), "eu_contribution": g.get("eu_contribution"),
                         "grant_status": g.get("status")})
        for row in rows:
            row.setdefault("snapshot_date", date)
            row.setdefault("company_id", cid)
    return rows


def cell(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    return "" if value is None else value


def git_commit(path):
    try:
        out = subprocess.run(["git", "-C", path, "log", "-1", "--format=%h %cs"], capture_output=True, text=True)
        return out.stdout.strip() or None
    except OSError:
        return None


def refresh(tracker, market_map):
    tdata = os.path.join(tracker, "data")
    sources = {
        "companies": os.path.join(market_map, "data", "greek_deeptech_dataset.csv"),
        "watchlist": os.path.join(tdata, "watchlist.csv"),
        "scores": os.path.join(tdata, "scores.csv"),
        "pipeline": os.path.join(tdata, "pipeline.csv"),
        "backtest": os.path.join(tdata, "backtest.csv"),
    }
    snapshots = sorted(glob.glob(os.path.join(tdata, "snapshots", "*.json")))
    missing = [p for p in sources.values() if not os.path.exists(p)]
    if missing or not snapshots:
        sys.exit("Source files not found:\n  " + "\n  ".join(missing or [os.path.join(tdata, "snapshots")]) +
                 "\nSet --tracker / --market-map, or DEALFLOW_TRACKER_DIR / MARKET_MAP_DIR.")

    os.makedirs(DATA, exist_ok=True)
    for table, path in sources.items():
        shutil.copyfile(path, os.path.join(DATA, f"{table}.csv"))
    names = [c for c, _ in SIGNAL_COLUMNS]
    n = 0
    with open(os.path.join(DATA, "signals.csv"), "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(names)
        for path in snapshots:
            with open(path, encoding="utf-8") as s:
                for row in flatten(json.load(s)):
                    w.writerow([cell(row.get(c)) for c in names])
                    n += 1
    manifest = {
        "market_map_commit": git_commit(market_map),
        "tracker_commit": git_commit(tracker),
        "snapshots": [os.path.basename(p)[:-5] for p in snapshots],
    }
    with open(os.path.join(DATA, "manifest.json"), "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
        f.write("\n")
    print(f"Refreshed data/ from {len(snapshots)} snapshots ({n} signal rows)")
    print(f"  market map {manifest['market_map_commit']}, tracker {manifest['tracker_commit']}")


# --- build: data/ -> dealflow.duckdb -------------------------------------------------------------

def build(db=DB):
    missing = [t for t in TABLES if not os.path.exists(os.path.join(DATA, f"{t}.csv"))]
    if missing:
        sys.exit(f"Missing data/{missing[0]}.csv. Run: python build_db.py --refresh")
    for suffix in ("", ".wal"):
        if os.path.exists(db + suffix):
            os.remove(db + suffix)
    con = duckdb.connect(db)
    for table in TABLES[:-1]:
        con.execute(f"CREATE TABLE {table} AS SELECT * FROM read_csv(?, header = true)",
                    [os.path.join(DATA, f"{table}.csv")])
    types = "{" + ", ".join(f"'{c}': '{t}'" for c, t in SIGNAL_COLUMNS) + "}"
    con.execute(f"CREATE TABLE signals AS SELECT * FROM read_csv(?, header = true, columns = {types})",
                [os.path.join(DATA, "signals.csv")])

    print(f"Built {os.path.relpath(db, HERE)}")
    for table in TABLES:
        n = con.execute(f"SELECT count(*) FROM {table}").fetchall()[0][0]
        print(f"  {table:<10} {n:>6} rows")
    weeks = con.execute("SELECT count(DISTINCT snapshot_date), min(snapshot_date), max(snapshot_date) "
                        "FROM signals").fetchall()[0]
    print(f"  {weeks[0]} weekly snapshots, {weeks[1]} to {weeks[2]}")
    con.close()


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--refresh", action="store_true", help="copy the latest data from the source repos first")
    ap.add_argument("--tracker", default=os.environ.get("DEALFLOW_TRACKER_DIR",
                                                        os.path.join(HERE, "..", "vc-dealflow-tracker")))
    ap.add_argument("--market-map", default=os.environ.get("MARKET_MAP_DIR",
                                                           os.path.join(HERE, "..", "greek-deeptech-market-map")))
    args = ap.parse_args()
    if args.refresh:
        refresh(os.path.abspath(args.tracker), os.path.abspath(args.market_map))
    build()


if __name__ == "__main__":
    main()
