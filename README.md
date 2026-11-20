# SQL Learning Kit: Greek Deep Tech Deal Flow

30 SQL exercises on my own data: the [Greek Deep Tech Market Map](https://github.com/geve-ops/greek-deeptech-market-map) and the weekly [deal-flow tracker](https://github.com/geve-ops/vc-dealflow-tracker). Each one asks a question a VC analyst would ask: who is hiring, which fund's portfolio is moving, who is in the raising window. The capstone rebuilds the tracker's Top Movers ranking in pure SQL.

It uses [DuckDB](https://duckdb.org/), a SQL database that runs inside Python. There is no server to set up, and its SQL is close to PostgreSQL and Snowflake.

## Setup

1. Keep the three folders side by side:

   ```
   Documents\
     greek-deeptech-market-map\
     vc-dealflow-tracker\
     sql-learning-kit\        <- this folder
   ```

2. Install DuckDB (Python 3.10 or newer):

   ```
   pip install duckdb
   ```

3. Build the database from the source files:

   ```
   python build_db.py
   ```

   This creates `dealflow.duckdb` with 6 tables. Run it again after each weekly tracker run (`git pull` in `vc-dealflow-tracker` first), and the exercises pick up the new week. If the folders are somewhere else, use `python build_db.py --tracker PATH --market-map PATH`.

## How to use it

1. Open an exercise sheet: [level 1](exercises/level1.md), [level 2](exercises/level2.md), [level 3](exercises/level3.md), [level 4](exercises/level4.md). Each exercise has a question, the columns to return, and a hint you can expand.
2. Write your query in `my_answers/<id>.sql`. Each file already holds the question as comments.
3. Check it:

   ```
   python check.py 1.03
   ```

   This prints your result and either `PASS` or the first thing that differs (column count, row count, a wrong row, or the right rows in the wrong order).

Other commands:

```
python check.py 1.03 --expected       show the expected result (not the SQL)
python check.py --list                progress: which exercises you have passed
python check.py --run "SELECT ..."    run any query (or a .sql file) and print the result
python check.py --all                 run every reference answer (checks the kit after a rebuild)
```

Reference answers are in [answers/](answers/). Open one only after you pass, or once you are really stuck. There is usually more than one correct query, and the checker compares results, not SQL text.

Checking rules: the number of columns and the values must match, and column names do not have to. Numbers match within 0.01. Every exercise states its sort order, and order is checked.

## Levels

| Level | Topics | Exercises |
|---|---|---|
| 1 | SELECT, WHERE, ORDER BY, GROUP BY, HAVING, NULL | 1.01 to 1.08 |
| 2 | INNER and LEFT JOIN, anti-joins, filters in ON vs WHERE | 2.01 to 2.07 |
| 3 | CTEs, CASE, dates, regex parsing, splitting `greek_funds` | 3.01 to 3.08 |
| 4 | RANK, ROW_NUMBER, LAG, running totals, share of total, capstone | 4.01 to 4.07 |

## Tables

| Table | Rows | One row per | Key columns |
|---|---|---|---|
| `companies` | 88 | market map company | `company_id`, `category`, `map_status`, `stage`, `last_round_amount`, `last_round_date`, `founded`, `verification_status` |
| `watchlist` | 69 | tracked company (Include and Borderline) | `company_id`, `category`, `github_org`, `greek_funds` (pipe-separated), `greek_fund_status`, `stage`, `last_round_date` |
| `scores` | 69 per week | company per weekly run | `date`, `company_id`, `week_score`, `funding`, `grants`, `press`, `hiring`, `github` |
| `pipeline` | 8 | company in the analyst pipeline | `company_id`, `pipeline_stage`, `recommendation`, `next_action`, `updated` |
| `backtest` | 15 | company with a known round and a GitHub org | `company_id`, `round_month`, `commits_baseline`, `commits_before`, `change` |
| `signals` | ~650 per week | item in a weekly snapshot | `snapshot_date`, `company_id`, `signal`, `item_id`, `title`, `event_date`, `source` |

`signals` flattens `data/snapshots/*.json`. `signal` is one of `github_repo`, `news`, `job` or `grant`, and `event_date` is the repo's last push, the news or job publish date, or the grant signature date. Type-specific columns: `news_kind` and `lang` (news), `location` (jobs), `stars`, `window_commits`, `window_commits_bot` and `is_fork` (repos), `eu_contribution` and `grant_status` (grants). Each snapshot lists everything visible that week, so filter to one `snapshot_date` unless you are comparing weeks.

Join on `company_id`, not on `company`. To see a table's columns, run `python check.py --run "DESCRIBE watchlist"`.

## Reference card

```sql
-- Order a query is written in             -- Order it runs in
SELECT    col, agg(col) AS name             -- 1 FROM / JOIN
FROM      table AS t                        -- 2 WHERE    (filters rows)
JOIN      other AS o ON o.id = t.id         -- 3 GROUP BY
WHERE     condition                         -- 4 HAVING   (filters groups)
GROUP BY  col                               -- 5 window functions, then QUALIFY
HAVING    agg_condition                     -- 6 SELECT
ORDER BY  name DESC, col                    -- 7 ORDER BY, LIMIT
LIMIT     10;
```

**Filtering**

| Pattern | Example |
|---|---|
| Missing value | `x IS NULL`, `x IS NOT NULL` (never `= NULL`) |
| List | `map_status IN ('Include', 'Borderline')` |
| Contains, any case | `verification_status ILIKE '%unverified%'` |
| Range | `months BETWEEN 15 AND 24` (both ends included) |
| Count matching rows | `count(*) FILTER (WHERE week_score > 0)` |

**Joins**

| Join | Keeps |
|---|---|
| `JOIN` (inner) | only rows that match on both sides |
| `LEFT JOIN` | every row on the left; right-side columns are NULL when there is no match |
| Anti-join | `LEFT JOIN ... WHERE right.id IS NULL`, or `WHERE NOT EXISTS (SELECT 1 FROM ...)` |

Watch out: with a `LEFT JOIN`, a filter on the right-hand table in `WHERE` turns it back into an inner join. Put that filter in `ON`.

**CTEs and CASE**

```sql
WITH step_one AS (SELECT ...),
     step_two AS (SELECT ... FROM step_one)
SELECT ... FROM step_two;

CASE WHEN x ILIKE '%series a%' THEN 'Series A'   -- the first match wins
     WHEN x ILIKE '%seed%'     THEN 'Seed'
     ELSE 'Other' END
```

**Text and dates (DuckDB)**

| Task | Expression |
|---|---|
| Split `A \| B` into rows | `trim(unnest(string_split(greek_funds, '\|')))` |
| Regex test / extract | `regexp_matches(s, '^\d{4}-\d{2}')`, `regexp_extract(s, '(\d{4})', 1)` |
| Safe conversion | `TRY_CAST(x AS INTEGER)` gives NULL instead of an error |
| Date literal | `DATE '2026-11-16'` |
| Text to date | `strptime('2025-03', '%Y-%m')::DATE` |
| Difference | `date_diff('month', start, end)`, `date_diff('day', start, end)` |
| Shift | `d - INTERVAL 30 DAY` |
| Truncate | `date_trunc('month', d)` |

**Window functions**

```sql
fn(...) OVER (PARTITION BY group_col ORDER BY order_col)
```

| Function | Use |
|---|---|
| `ROW_NUMBER()` | 1, 2, 3 with no ties. Use it for top 1 per group. |
| `RANK()` / `DENSE_RANK()` | Ties share a rank. RANK skips numbers after a tie (1, 1, 3) and DENSE_RANK does not (1, 1, 2). |
| `LAG(x)` / `LEAD(x)` | Value from the previous / next row. Use it for week-over-week change. |
| `sum(x) OVER (... ORDER BY d)` | Running total |
| `sum(x) OVER ()` | Total over all rows. Use it for share of total. |
| `QUALIFY rn = 1` | Filter on a window result. In other databases, wrap the query in a CTE. |

## Optional tools

- [DuckDB CLI](https://duckdb.org/docs/installation/): `duckdb dealflow.duckdb` gives an interactive SQL prompt.
- [DBeaver](https://dbeaver.io/) or the VS Code SQLTools extension with its DuckDB driver can browse the tables in a GUI.

## Files

| File | Purpose |
|---|---|
| `build_db.py` | builds `dealflow.duckdb` from the source CSVs and snapshots |
| `check.py` | runs your answer and compares it with the reference |
| `exercises/` | the four exercise sheets |
| `my_answers/` | your queries, one file per exercise |
| `answers/` | reference answers |
