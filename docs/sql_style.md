# SQL style guide

The conventions every query in this repository follows. `sqlfluff` checks the ones marked *(lint)*; the others are kept by review.

## Casing and names

- Keywords, literals (`NULL`, `TRUE`) and types (`DATE`, `DOUBLE`) in upper case. *(lint)*
- Window functions in upper case (`ROW_NUMBER`, `RANK`, `DENSE_RANK`, `LAG`), so the window logic stands out. All other functions in lower case (`count`, `sum`, `coalesce`, `regexp_extract`).
- Tables and columns in `snake_case`. Counts are plural nouns (`companies`, `rounds`); flags start with `is_`, `has_` or `on_`; amounts carry their unit (`amount_m`, `project_eu_eur_m`, `pct_backed`).
- Model names start with `dim_`, `fct_`, `bridge_` or `ref_` (see [architecture.md](architecture.md)).

## Structure

- One CTE per step, named for what it holds (`holdings`, `latest`, `open_roles`), read top to bottom. No nested subqueries beyond a one-line scalar lookup.
- Every table gets a short alias with `AS`, and every column in a multi-table query is qualified with its alias. *(lint)*
- Join on IDs (`company_id`), never on names.
- Put the filter for the right-hand table of a `LEFT JOIN` in `ON`, not in `WHERE`.
- `<>` for not-equal and `IS NULL` for missing values. *(lint)*
- Every query that returns rows in an order ends with an `ORDER BY` that fully decides that order: add tie-breakers until no two rows can swap.
- End every statement with a semicolon. *(lint)*

## Content

- No hard-coded dates where the latest run is meant: use `(SELECT max(...) FROM ...)` or a `latest` CTE, so the query stays right when new data arrives. Exercises that ask about a named week use a date literal on purpose.
- Never estimate or convert. Use the parsed, confirmed fields (`fct_last_round.is_usable`) and keep currencies apart.
- Count what the question means: `count(DISTINCT item_id)` for postings, `count(*)` for rows. Check a table's grain before counting.
- Each file starts with a comment saying what the query answers and, for models, the grain and the sources.

## Layout

Layout is not linted. Align `AS` aliases in long `SELECT` lists when it helps reading, indent CTE bodies by four spaces, and keep lines under 130 characters. *(lint: line length)*
