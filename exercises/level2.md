# Level 2: JOINs across tables

Most tables share `company_id` (for example `GRDT-030`). Join on it, not on `company`: names can change ("TileDB (rebranded Tile.ai)"), and IDs do not.

Give each table a short alias (`FROM pipeline AS p JOIN watchlist AS w ON ...`), and prefix columns with it (`w.category`) so it is always clear which table a column comes from.

---

### 2.01 Pipeline with context

**Question.** For each company in the analyst pipeline, show its pipeline stage and recommendation next to its sector and funding stage from the watchlist.

**Return:** `company`, `pipeline_stage`, `recommendation`, `category`, `stage`. **Sort:** company.

<details><summary>Hint</summary>

`pipeline` has the stage and recommendation. `watchlist` has `category` and `stage`. Use an inner `JOIN ... ON w.company_id = p.company_id`.
</details>

---

### 2.02 Off the watchlist

**Question.** Which market-map companies are not on the watchlist, and why (their `map_status`)?

**Return:** `company`, `category`, `map_status`. **Sort:** company.

<details><summary>Hint</summary>

This is an anti-join. `LEFT JOIN watchlist` keeps every company. Where there is no match, the watchlist columns are `NULL`, so filter with `WHERE w.company_id IS NULL`.
</details>

---

### 2.03 Is the pipeline where the signals are?

**Question.** For each pipeline company, what is its total score across all weekly runs? Include companies that never scored and show them as 0.

**Return:** `company`, `pipeline_stage`, `total_score`. **Sort:** `total_score` highest first, then company.

<details><summary>Hint</summary>

Start from `pipeline` and `LEFT JOIN scores`. `coalesce(sum(...), 0)` turns a missing total into 0. Every column you select that is not aggregated must be in `GROUP BY`.
</details>

---

### 2.04 Commits that rose before the round

**Question.** For the backtest companies whose GitHub commits rose before the round, which sector is each in, and how big was the round?

**Return:** `company`, `category` (from `companies`), `round_month`, `round`, `commits_baseline`, `commits_before`. **Sort:** company.

<details><summary>Hint</summary>

Join `backtest` to `companies` on `company_id`, and filter `change = 'rose'`.
</details>

---

### 2.05 Who is hiring right now

**Question.** In the latest weekly snapshot, how many open job postings does each company have?

Count postings, not rows: a job board lists a job open in several cities once per city, and each copy has the same `item_id`. Hack The Box's "Senior Product Manager" appears six times.

**Return:** `company`, `category`, `open_roles`. **Sort:** `open_roles` highest first, then company.

<details><summary>Hint</summary>

Job postings are the rows in `signals` with `signal = 'job'`. Every snapshot lists every posting that is still open, so filter to one `snapshot_date`. To avoid typing the date, use a subquery: `snapshot_date = (SELECT max(snapshot_date) FROM signals)`.

`count(*)` counts rows. `count(DISTINCT s.item_id)` counts different postings. Run both and compare the Hack The Box row.
</details>

---

### 2.06 Companies with no visible activity

**Question.** Which watchlist companies had no signal of any kind (repo, news, job or grant) in the 16 November 2026 snapshot? They are the ones you can only cover by talking to people.

**Return:** `company`, `category`. **Sort:** company.

<details><summary>Hint</summary>

This is a classic trap. If you `LEFT JOIN signals` and then put the date filter in `WHERE`, the rows you wanted (the ones where the signal columns are `NULL`) get thrown away. Put the date condition in the `ON` clause, and keep only `WHERE s.company_id IS NULL` in `WHERE`.
</details>

---

### 2.07 EU grant money by sector

**Question.** In the 16 November 2026 snapshot, how many EU grants (CORDIS projects) are linked to watchlist companies in each sector, and how much EU money do they add up to?

**Return:** `category`, `grants`, `eu_eur_m` (sum of `eu_contribution` in EUR millions, rounded to 2 decimals). **Sort:** `eu_eur_m` highest first, then category.

<details><summary>Hint</summary>

Filter `signal = 'grant'`, join to `watchlist` for the sector, and use `round(sum(eu_contribution) / 1e6, 2)`. The amount is the whole project's EU contribution, not the company's own share, so do not quote it as company funding.
</details>
