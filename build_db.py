"""Build dealflow.duckdb from the market map and tracker source files.

    python build_db.py
    python build_db.py --tracker ..\\vc-dealflow-tracker --market-map ..\\greek-deeptech-market-map

Tables:
    companies   market map dataset, one row per company (88)
    watchlist   tracker watchlist (69), with Greek fund tags and sources
    scores      weekly score history, one row per company per weekly run
    pipeline    hand-kept analyst pipeline
    backtest    GitHub commits before and after known rounds
    signals     every item in every weekly snapshot (repos, news, jobs, grants), flattened
"""

import argparse
import glob
import json
import os
import sys

import duckdb

HERE = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(HERE, "dealflow.duckdb")

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
    ("eu_contribution", "DOUBLE"),   # grants only, EUR
    ("grant_status", "VARCHAR"),
]


def day(value):
    return value[:10] if value else None


def flatten(snapshot):
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
                         "eu_contribution": g.get("eu_contribution"), "grant_status": g.get("status")})
        for row in rows:
            row.setdefault("snapshot_date", date)
            row.setdefault("company_id", cid)
    return rows


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--tracker", default=os.path.join(HERE, "..", "vc-dealflow-tracker"))
    ap.add_argument("--market-map", default=os.path.join(HERE, "..", "greek-deeptech-market-map"))
    args = ap.parse_args()

    tdata = os.path.join(args.tracker, "data")
    csvs = {
        "companies": os.path.join(args.market_map, "data", "greek_deeptech_dataset.csv"),
        "watchlist": os.path.join(tdata, "watchlist.csv"),
        "scores": os.path.join(tdata, "scores.csv"),
        "pipeline": os.path.join(tdata, "pipeline.csv"),
        "backtest": os.path.join(tdata, "backtest.csv"),
    }
    missing = [p for p in csvs.values() if not os.path.exists(p)]
    if missing:
        sys.exit("Missing source files:\n  " + "\n  ".join(missing))

    if os.path.exists(DB):
        os.remove(DB)
    con = duckdb.connect(DB)
    for table, path in csvs.items():
        con.execute(f"CREATE TABLE {table} AS SELECT * FROM read_csv(?, header = true)", [path])

    con.execute("CREATE TABLE signals (" + ", ".join(f"{c} {t}" for c, t in SIGNAL_COLUMNS) + ")")
    names = [c for c, _ in SIGNAL_COLUMNS]
    snapshots = sorted(glob.glob(os.path.join(tdata, "snapshots", "*.json")))
    for path in snapshots:
        with open(path, encoding="utf-8") as f:
            rows = flatten(json.load(f))
        con.executemany(f"INSERT INTO signals VALUES ({', '.join('?' * len(names))})",
                        [[r.get(c) for c in names] for r in rows])

    print(f"Built {DB}")
    for (table,) in con.execute("SELECT table_name FROM information_schema.tables ORDER BY 1").fetchall():
        n = con.execute(f"SELECT count(*) FROM {table}").fetchone()[0]
        print(f"  {table:<10} {n:>6} rows")
    print(f"  ({len(snapshots)} weekly snapshots in signals)")
    con.close()


if __name__ == "__main__":
    main()
