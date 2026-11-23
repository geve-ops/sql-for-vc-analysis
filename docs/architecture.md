# Architecture

How data moves from the two source projects to the exercises and the case study, and why it is built this way.

## System overview

```mermaid
flowchart TB
    subgraph sources["Source projects"]
        MM["greek-deeptech-market-map<br/>greek_deeptech_dataset.csv"]
        TR["vc-dealflow-tracker<br/>watchlist, scores, pipeline, backtest<br/>weekly snapshots (JSON)"]
    end
    subgraph repo["This repository"]
        DATA["data/*.csv<br/>frozen copy + manifest.json"]
        SEEDS["seeds/*.csv<br/>hand-kept reference data"]
        subgraph db["dealflow.duckdb (built, not committed)"]
            MAIN["main schema<br/>6 source tables, as delivered"]
            ANA["analytics schema<br/>7 models + 2 reference tables"]
        end
        DQ["tests/data_quality<br/>17 rules: zero rows = pass"]
        EX["exercises/ + answers/<br/>35 graded exercises"]
        CS["case_study/<br/>queries → report + charts"]
    end
    MM -- "build_db.py --refresh" --> DATA
    TR -- "build_db.py --refresh<br/>(snapshots flattened)" --> DATA
    DATA -- "build_db.py" --> MAIN
    SEEDS --> ANA
    MAIN -- "models/*.sql" --> ANA
    MAIN --> DQ
    ANA --> DQ
    MAIN --> EX
    ANA --> CS
```

## Layers

| Layer | Where | What it holds | Who reads it |
|---|---|---|---|
| Sources | `data/*.csv` | A frozen copy of the two source projects. `signals.csv` is the weekly JSON snapshots flattened to one row per item. | `build_db.py` |
| Source tables | `main` schema | The CSVs loaded as delivered, free text and all. | The exercises, which teach how to clean them. |
| Reference data | `seeds/*.csv` → `analytics.ref_*` | Hand-kept lists: the target funds, and the tracker's scores as first published. | Models, data-quality rules |
| Models | `models/*.sql` → `analytics` schema | Cleaned, typed tables with a stated grain: one parse of each messy field, used everywhere. | The case study |
| Tests | `tests/` | Data-quality rules, the reviewed result of every exercise, the checker's own rules, and checks that the docs match the repository. | `run_all.py`, CI |
| Outputs | `case_study/README.md`, `case_study/charts/`, the findings on `README.md` | Generated from the queries. Nothing typed by hand. | Readers |

## Model lineage

Which source tables each model reads, and which models each case study question uses. Read left to right.

```mermaid
flowchart LR
    classDef src fill:#eef2f7,stroke:#8a98ab,color:#1c1d1f
    classDef ref fill:#f6f0e4,stroke:#b39661,color:#1c1d1f
    classDef mdl fill:#e3f1ea,stroke:#4f9a76,color:#1c1d1f
    classDef out fill:#fdf0e8,stroke:#d0703e,color:#1c1d1f

    companies[(companies)]:::src
    watchlist[(watchlist)]:::src
    scores[(scores)]:::src
    signals[(signals)]:::src
    ref_target_fund[/ref_target_fund/]:::ref
    ref_pub[/ref_scores_first_published/]:::ref

    dim_company[dim_company]:::mdl
    bridge[bridge_company_fund]:::mdl
    last_round[fct_last_round]:::mdl
    fct_signal[fct_signal]:::mdl
    weekly[fct_weekly_score]:::mdl
    momentum[company_momentum]:::mdl
    original[fct_weekly_score_original_rule]:::mdl

    q1["Q1 Universe"]:::out
    q2["Q2 Funds"]:::out
    q3["Q3 Capital"]:::out
    q4["Q4 EU grants"]:::out
    q5["Q5 Momentum audit"]:::out
    q6["Q6 Call list"]:::out

    companies --> dim_company
    watchlist --> dim_company
    watchlist --> bridge
    ref_target_fund --> bridge
    companies --> last_round
    signals --> fct_signal
    scores --> weekly
    weekly --> momentum
    dim_company --> momentum
    weekly --> original
    fct_signal --> original
    ref_pub -. "checked by a data-quality rule" .-> original

    dim_company --> q1
    last_round --> q1
    momentum --> q1
    bridge --> q2
    last_round --> q3
    fct_signal --> q4
    bridge --> q4
    weekly --> q5
    fct_signal --> q5
    original --> q5
    last_round --> q6
    bridge --> q6
    momentum --> q6
    fct_signal --> q6
```

## Models

Each model is one SQL file that creates one table. Files run in name order, so a model can read the models before it. The naming follows common analytics-engineering practice: `dim_` for entities, `fct_` for events or measurements, `bridge_` for many-to-many links, `ref_` for seeds.

| Model | Grain | Built from | Purpose |
|---|---|---|---|
| `ref_target_fund` | fund | `seeds/target_fund.csv` | The funds the analysis is for. |
| `ref_scores_first_published` | run × company | `seeds/scores_first_published.csv` | The tracker's weekly scores as first published, before its scoring fix. |
| `dim_company` | company (88) | `companies`, `watchlist` | One clean row per company: sector, founding year, watchlist flag, first source link, fund status. |
| `bridge_company_fund` | company × fund | `watchlist.greek_funds` | The multi-fund text cell split into rows, with current and target flags. |
| `fct_last_round` | company (88) | `companies` | The last round parsed into currency, amount and month, with an amount status and a date status. `is_usable` is the single rule for which rounds count. |
| `fct_signal` | snapshot × company × signal × item | `signals` | One row per item. Job postings that boards repeat once per city are collapsed, with the cities listed. |
| `fct_weekly_score` | run × company | `scores` | Scores with each run's position and momentum weight. |
| `company_momentum` | company (69) | `fct_weekly_score` | The tracker's Top Movers ranking, plus the same ranking without funding points. |
| `fct_weekly_score_original_rule` | run × company | `fct_weekly_score`, `fct_signal` | Each weekly score as the tracker's original rules gave it, rebuilt from the raw signals and checked row for row against `ref_scores_first_published`. |

## Design decisions

- **Parse once, in SQL.** Free-text round amounts, dates and fund lists are parsed in one model each. Every query that needs a round size uses `fct_last_round.is_usable`, so the rule for what counts cannot drift between queries.
- **Never estimate.** A model fills an amount only when the source gives an exact one. Approximate, lower-bound and unverified values keep their text and get a status instead of a number. Currencies stay separate.
- **Keep the source layer untouched.** The exercises run on the source tables, so a learner meets the real mess, and the models show one way to clean it.
- **Test the data, not only the code.** The data-quality rules check keys, references between tables, accepted values, score arithmetic, the grain of each model, and a schema contract for the source tables. Each rule is a query that returns the rows breaking it. Breaking the data on purpose (a duplicate company, a wrong score, an unknown signal type, a future date, an orphan row, an approximate amount given a number, a changed column type, a fund name with spaces) makes the matching rule fail.
- **Audit upstream, not only here.** Section 5 of the case study found two errors in the tracker's scoring. The fix went to the tracker, and the tracker rescored its history. This repository keeps the scores as first published, as a seed, and a model that rebuilds them from the raw signals, so the audit stays reproducible after the fix.
- **Generated reports.** Tables, charts and every number in the case study text come from queries (`{{table:…}}`, `{{fact:…}}`, `{{cell:…}}` placeholders). If the data changes, the report changes with it, and CI fails if the committed report no longer matches the data.
- **Docs are tested too.** The counts the front page states (exercises, models, data-quality rules) are checked against the repository, so the description cannot drift from the code.
- **Commit the data, build the database.** The CSVs are small and diff well. The DuckDB file is binary, changes with every build and depends on the DuckDB version, so it is built in about a second instead.
- **Freeze, then refresh on purpose.** The data is a snapshot (see `data/manifest.json`). `python run_all.py --refresh` pulls new data; the reviewed exercise results then fail until a person checks them and accepts them with `--update-expected`.

## Quality gates

`python run_all.py` runs these in order and stops at the first failure. CI runs the same command on every push.

```mermaid
flowchart LR
    A["1. Lint<br/>sqlfluff + ruff"] --> B["2. Build<br/>sources, seeds, models"]
    B --> C["3. Run every<br/>reference answer"]
    C --> D["4. Test<br/>17 data-quality rules,<br/>35 reviewed results,<br/>capstone vs digest,<br/>checker + docs"]
    D --> E["5. Regenerate<br/>case study + findings"]
    E --> F{"CI only:<br/>committed report<br/>matches?"}
    F -- yes --> G([pass])
    F -- no --> H([fail])
```

1. SQL lint (`sqlfluff`, rules in `.sqlfluff`) and Python lint and format checks (`ruff`, rules in `pyproject.toml`).
2. Build: source tables, seeds, models. A model that fails to run stops the build with its file name.
3. Every reference answer runs.
4. Tests: the data-quality rules, each exercise against its reviewed result, the capstone against the published tracker digest, the checker's comparison rules, and the counts stated in the docs.
5. The case study and the front-page findings are regenerated. In CI, `git diff --exit-code` then checks that the committed report matches.
