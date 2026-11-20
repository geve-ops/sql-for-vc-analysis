# SQL for VC analysis: Greek deep tech deal flow

SQL on real venture data: 88 Greek deep-tech companies, their investors and rounds, and four weeks of hiring, GitHub, news and EU-grant signals. The project has two parts:

- **[Case study](case_study/README.md):** six questions a Greek VC fund would ask, answered in SQL with the queries, the results, four charts and a "so what" for each.
- **Learning kit:** 30 graded exercises in four levels, from `SELECT` to window functions, with a checker that tells you whether your answer is right.

The data comes from two of my other projects, the [Greek Deep Tech Market Map](https://github.com/geve-ops/greek-deeptech-market-map) and the weekly [deal-flow tracker](https://github.com/geve-ops/vc-dealflow-tracker). Everything runs on [DuckDB](https://duckdb.org/), an in-process SQL database: no server, and SQL close to PostgreSQL and Snowflake.

## Findings from the case study

Data as of the tracker's weekly run of 16 November 2026. Each line links to its section.

| Question | Finding |
|---|---|
| [Do the target funds co-invest?](case_study/README.md#2-which-greek-funds-lead-and-do-the-target-funds-co-invest) | Big Pi, Marathon, Metavallon and Velocity share exactly one company between them (Anodyne Nanotech). Their Greek co-investors are smaller early-stage funds such as Evercurious VC and Genesis Ventures. |
| [How is recent capital spread?](case_study/README.md#3-how-is-recent-capital-spread) | Since January 2025 the median confirmed round is EUR 1.18M in euros and USD 6.75M in dollars. One company, Open Cosmos, is 89.6% of the euro total. |
| [Who brings in EU money?](case_study/README.md#4-who-brings-in-eu-research-money) | The five companies with the most CORDIS projects have no Greek fund behind them: a sourcing list. |
| [What drives momentum?](case_study/README.md#5-what-drives-week-over-week-momentum) | None of the headlines that earned funding points announced a round. Without them, the third-ranked mover falls to 18th. |
| [Who to call this month?](case_study/README.md#6-who-should-a-fund-call-this-month) | 12 companies are 15 to 24 months past their last round; 7 of them have no Greek investor. |

## Quick start

Python 3.10 or newer.

```
git clone https://github.com/geve-ops/sql-learning-kit.git
cd sql-learning-kit
pip install -r requirements.txt
python run_all.py
```

`run_all.py` builds the database from the CSV files in [data/](data/), runs all 30 reference answers, tests the kit (every answer against its reviewed result, the capstone against the published tracker digest, and the checker's own rules), and rebuilds the case study. It takes a few seconds and ends with `All steps passed.`

## Learning path

Work through the levels in order. Each exercise is a question an analyst would be asked, with the columns to return, the sort order, and a hint you can expand.

| Level | You learn | Exercises | Example question |
|---|---|---|---|
| [1](exercises/level1.md) | `SELECT`, `WHERE`, `ORDER BY`, `GROUP BY`, `HAVING`, `NULL` | 1.01 to 1.08 | Which companies with a GitHub organisation have no Greek investor? |
| [2](exercises/level2.md) | inner and left joins, anti-joins, filters in `ON` vs `WHERE` | 2.01 to 2.07 | Which companies showed no activity at all this week? |
| [3](exercises/level3.md) | CTEs, `CASE`, dates, regex parsing of messy text, splitting lists | 3.01 to 3.08 | Which companies are in the 15 to 24 month raising window? |
| [4](exercises/level4.md) | `RANK`, `ROW_NUMBER`, `LAG`, running totals, share of total | 4.01 to 4.07 | Capstone: rebuild the tracker's Top Movers ranking in SQL. |

For each exercise:

1. Write your query in `my_answers/<id>.sql`. The file already holds the question.
2. Check it with `python check.py 1.03`. You see your result and either `PASS` or the first difference (column count, row count, a wrong row, or the right rows in the wrong order).
3. Once you pass, compare with the reference answer in [answers/](answers/). There is usually more than one correct query; the checker compares results, not SQL text.

| Command | Does |
|---|---|
| `python check.py 1.03` | check your answer |
| `python check.py 1.03 --expected` | show the expected result (not the SQL) |
| `python check.py --list` | show your progress |
| `python check.py --run "SELECT ..."` | run any query, or a `.sql` file |

Checking rules: the number of columns and the values must match; column names do not have to. Numbers match within 0.01. Every exercise states its sort order, and order is checked.

Keep the [SQL reference card](docs/sql_reference_card.md) open while you work. To see a table's columns, run `python check.py --run "DESCRIBE watchlist"`, or open `dealflow.duckdb` in the [DuckDB CLI](https://duckdb.org/docs/installation/), DBeaver, or VS Code with a DuckDB extension.

## The data

Six tables, joined on `company_id`. Columns, types and meanings are in the **[data dictionary](docs/data_dictionary.md)**, with a schema diagram.

| Table | Rows | One row per |
|---|---:|---|
| `companies` | 88 | company on the market map, with stage, last round, investors and source links |
| `watchlist` | 69 | company the tracker follows, with GitHub, job board and Greek fund tags |
| `scores` | 276 | company per weekly run: points for funding news, grants, press, hiring and GitHub |
| `signals` | 2,623 | item seen in a weekly snapshot: repo, headline, job posting or CORDIS project |
| `pipeline` | 8 | company in the analyst pipeline |
| `backtest` | 15 | company with a known round: GitHub commits before it |

**Sources.** Company facts and round figures come from the market map, which keeps a source link for every company. Signals come from GitHub, Google News, the companies' job boards and the EU's [CORDIS](https://cordis.europa.eu/) database, collected weekly by the tracker. No figure in the data or the case study is estimated: where a source gives only an approximation or an unverified number, the queries leave it out.

**Limits.** 69 companies and four weekly runs: enough to learn SQL and to describe this watchlist, not to show trends. Round sizes are free text, last round only, in the source's currency. Fund tags miss holdings no source mentions. EU grant amounts are whole-project budgets, not the company's share. Funding headlines are tagged by keyword. The full list is in the [data dictionary](docs/data_dictionary.md#limits-of-the-data).

## Design choices

- **The data is in the repository; the database is not.** `data/` holds the six source CSVs (about 0.9 MB), so a fresh clone builds without the other two repositories. `dealflow.duckdb` is built from them in about a second and is in `.gitignore`: it is a binary file that would change with every rebuild, and its storage format is tied to the DuckDB version.
- **The data is frozen at 16 November 2026**, so the exercises, the reviewed results and the case study text stay consistent. [data/manifest.json](data/manifest.json) records which commits of the source repositories it came from.
- **Refreshing is one command.** With the two source repositories next to this folder, `python run_all.py --refresh` copies their latest data into `data/`. If they live elsewhere, set `DEALFLOW_TRACKER_DIR` and `MARKET_MAP_DIR`, or pass `--tracker` and `--market-map` to `build_db.py --refresh`. After a refresh, review the changed results, accept them with `python run_all.py --update-expected`, and re-read the case study text against its new tables.
- **The case study is generated.** [case_study/build_report.py](case_study/build_report.py) runs each query in [case_study/queries/](case_study/queries/) and writes the results into [case_study/template.md](case_study/template.md), so no table is typed in by hand.

## Files

```
README.md               this page
requirements.txt        duckdb, matplotlib
run_all.py              build, test and rebuild everything
build_db.py             data/*.csv -> dealflow.duckdb (--refresh pulls from the source repos)
check.py                checks your answers
data/                   source CSVs and manifest.json
exercises/              the four exercise sheets
my_answers/             your queries, one file per exercise
answers/                reference answers
case_study/             the report (README.md), its queries, charts, template and build script
docs/                   data dictionary with schema diagram, SQL reference card
tests/                  kit tests and the reviewed result of every exercise
```
