# Level 4: Window functions

A window function computes over a set of rows related to the current row and keeps every row. `GROUP BY` collapses the rows instead.

```sql
function(...) OVER (PARTITION BY <group> ORDER BY <order>)
```

`PARTITION BY` is like `GROUP BY` but keeps the rows. `ORDER BY` inside `OVER` decides what "previous" and "running" mean.

`scores` has one row per company per weekly run (26 Oct, 2, 9 and 16 Nov 2026). It is the main table for this level.

---

### 4.01 Sector leaders

**Question.** In each sector, which company has the highest total score across all runs? If two companies tie, show both. Leave out companies that never scored.

**Return:** `category`, `company`, `total_score`. **Sort:** category, then company.

<details><summary>Hint</summary>

Total per company in a CTE (join `watchlist` for `category`). Then `RANK() OVER (PARTITION BY category ORDER BY total_score DESC)`, and keep rank 1. You cannot filter on a window function in `WHERE`, so either wrap it in another CTE or use DuckDB's `QUALIFY rnk = 1`.
</details>

---

### 4.02 Week-over-week movers

**Question.** In the 16 November 2026 run, whose week score changed compared with the week before, and by how much?

**Return:** `company`, `week_score`, `prev_week`, `change` (this week minus last week). Only rows where the score changed. **Sort:** `change` highest first, then company.

<details><summary>Hint</summary>

`LAG(week_score) OVER (PARTITION BY company_id ORDER BY date)` returns the same company's score from the previous run. Compute it over all dates in a CTE, then filter to 16 November. If you filter first, there is no previous week left to look at.
</details>

---

### 4.03 Running totals for the pipeline

**Question.** For each pipeline company, show its score each week and its cumulative score so far.

**Return:** `company`, `date`, `week_score`, `running_total`. **Sort:** company, then date.

<details><summary>Hint</summary>

`sum(week_score) OVER (PARTITION BY company_id ORDER BY date)`. With an `ORDER BY` inside `OVER`, `sum` adds up from the first row to the current one.
</details>

---

### 4.04 Is hiring across the watchlist going up?

**Question.** How many job postings are open across the whole watchlist in each weekly snapshot, and how did that change from the week before?

**Return:** `snapshot_date`, `postings`, `change` (NULL for the first week). **Sort:** date.

<details><summary>Hint</summary>

Count per `snapshot_date` in a CTE, then `postings - LAG(postings) OVER (ORDER BY snapshot_date)`. There is no `PARTITION BY` here, because the whole table is one series.
</details>

---

### 4.05 Share of hiring by sector

**Question.** In the 16 November 2026 snapshot, what share of all open job postings does each sector have?

**Return:** `category`, `postings`, `pct_of_all` (percent, rounded to 1 decimal). **Sort:** `postings` highest first, then category.

<details><summary>Hint</summary>

You can wrap an aggregate in a window function: `sum(count(*)) OVER ()` is the total across all groups. `OVER ()` with nothing inside means "all rows". Multiply by `100.0`, not `100`, so the division is not integer division.
</details>

---

### 4.06 Latest headline per company

**Question.** In the 16 November 2026 snapshot, what is the most recent news item for each company?

**Return:** `company`, `published` (the item's `event_date`), `source`, `title`. **Sort:** `published` newest first, then company.

<details><summary>Hint</summary>

`ROW_NUMBER() OVER (PARTITION BY company_id ORDER BY event_date DESC, item_id)`, and keep `rn = 1`. This "top 1 per group" pattern comes up all the time. The `item_id` tie-breaker makes the choice the same on every run when two items share a date.
</details>

---

### 4.07 Capstone: rebuild the tracker's Top Movers in SQL

**Question.** The weekly digest opens with a Top Movers table, computed in Python (`tracker/score.py`). Rebuild it in pure SQL from `scores`:

- **Momentum** = this week's score + 0.5 × last week + 0.25 × two weeks ago + 0.125 × three weeks ago, using the 4 most recent runs. Round to 2 decimals.
- **This week** = the score in the latest run. **Last week** = the score in the run before it.
- Keep companies with momentum above 0.
- **Rank** by momentum (highest first), then this week's score (highest first), then company name. Ties get different numbers.
- Return the top 10.

**Return:** `rank`, `company`, `momentum`, `week_score`, `last_week`. **Sort:** rank.

Check your result against the table at the top of `digests/2026-11-16.md` in the tracker. The two should be identical.

<details><summary>Hint</summary>

1. List the distinct run dates and number them with `DENSE_RANK() OVER (ORDER BY date DESC)`, so 1 is the latest run.
2. Join that to `scores`, and turn the number into a weight with `CASE weeks_back WHEN 1 THEN 1.0 WHEN 2 THEN 0.5 ...`.
3. Group by company: `sum(week_score * weight)` gives momentum, and `max(week_score) FILTER (WHERE weeks_back = 1)` gives this week.
4. Rank with `ROW_NUMBER() OVER (ORDER BY momentum DESC, week_score DESC, company)`, because ties must get different numbers.

Do not hard-code the dates. When next Monday's run lands and you rebuild the database, your query should still be right.
</details>
