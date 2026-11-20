# Level 3: CTEs, CASE, dates and splitting `greek_funds`

A CTE (`WITH name AS (...)`) is a named step. It lets you write a query top to bottom, like a recipe, instead of nesting subqueries inside each other. From this level on, most answers have two or three steps.

---

### 3.01 Stage funnel

**Question.** The watchlist's `stage` column is free text ("Seed (registry label); DIANA grant", "Venture debt (after Series A)", ...). Put each company into a bucket and count them:

- `Series B+`: the text mentions series b, series c, late stage or growth
- `Series A`: it mentions series a
- `Pre-seed / Seed`: it mentions seed
- `Other`: everything else

**Return:** `stage_bucket`, `companies`. **Sort:** `companies` highest first, then bucket.

<details><summary>Hint</summary>

`CASE WHEN ... THEN ... END` returns the first branch that matches, so the order of the branches matters. "Venture debt (after Series A)" has to land in Series A, and nothing that mentions Series B may fall through to Seed. Test with `ILIKE '%series a%'`. You can `GROUP BY stage_bucket`, the alias.
</details>

---

### 3.02 The raising window

**Question.** Early-stage companies often raise again 15 to 24 months after their last round. Which watchlist companies (any stage) had their last round 15 to 24 months before 16 November 2026?

`last_round_date` is text: some values are `2026-06-24`, some are `2026-07`, and some are `UNVERIFIED` or `Not found`. Use only the rows that start with a year and a month, and take that month.

**Return:** `company`, `round_month` (a DATE, the first of the month), `months_since`. Only rows with 15 to 24 months. **Sort:** `months_since` highest first, then company.

<details><summary>Hint</summary>

- `regexp_matches(last_round_date, '^\d{4}-\d{2}')` keeps the rows that start with YYYY-MM.
- `strptime(left(last_round_date, 7), '%Y-%m')::DATE` turns `2025-03` into `2025-03-01`.
- `date_diff('month', round_month, DATE '2026-11-16')` counts the months between the two dates.

Do the cleaning in a CTE, then filter in the main query.
</details>

---

### 3.03 Fund footprint

**Question.** `greek_funds` holds several funds in one cell, for example `Big Pi Ventures | Evercurious VC | Starttech Ventures`. How many watchlist companies is each Greek fund linked to, and how many of those holdings are still current?

**Return:** `fund`, `companies`, `current_holdings` (where `greek_fund_status = 'current'`). **Sort:** `companies` highest first, then fund.

<details><summary>Hint</summary>

`string_split(greek_funds, '|')` turns the cell into a list. `unnest(...)` turns the list into one row per fund. `trim(...)` removes the spaces around each name. Do this in a CTE, then `GROUP BY fund`.
</details>

---

### 3.04 Which fund's portfolio is moving

**Question.** For each Greek fund, add up the weekly scores (all runs) of the companies where its holding is current. Which fund's portfolio is producing the most signal?

**Return:** `fund`, `companies`, `portfolio_score`. **Sort:** `portfolio_score` highest first, then fund.

<details><summary>Hint</summary>

Use two CTEs. In the first, split the funds as in 3.03, keeping only `greek_fund_status = 'current'`. In the second, total the score per company from `scores`. Then join the two. Total first and join second, or each company's score is counted once for every weekly row.
</details>

---

### 3.05 Fresh roles or stale listings?

**Question.** A company with many job posts may just have old listings it never took down. In the 16 November 2026 snapshot, how many of each company's postings were published in the 30 days before the snapshot, and how many are older? Count each posting once (distinct `item_id`, as in 2.05).

**Return:** `company`, `fresh_30d`, `older`, `total`. **Sort:** `fresh_30d` highest first, then company.

<details><summary>Hint</summary>

`count(DISTINCT item_id) FILTER (WHERE event_date >= snapshot_date - INTERVAL 30 DAY)`. The `FILTER` clause works with `DISTINCT` too. Some boards give no publish date (`event_date` is NULL). Those rows count in `total` but in neither `fresh_30d` nor `older`. Look at Corsmed and Intryc in the result.
</details>

---

### 3.06 New roles this week

**Question.** Which job postings are in the 16 November 2026 snapshot but were not in the 9 November one? One row per posting.

**Return:** `company`, `item_id`, `title`. **Sort:** company, then title, then `item_id`.

<details><summary>Hint</summary>

Make one CTE for this week's jobs and one for last week's. Keep the rows of this week where `NOT EXISTS (SELECT 1 FROM last_week AS l WHERE l.company_id = t.company_id AND l.item_id = t.item_id)`. Match on `item_id`, not on `title`: two different postings can share a title. Use `SELECT DISTINCT` in the first CTE so a posting listed in several cities gives one row.
</details>

---

### 3.07 How old are the companies?

**Question.** `companies.founded` is messy text ("2021 (CB Insights, Endeavor...)", "2015 or 2019 (sources conflict)", "UNVERIFIED"). For each sector, how many companies have a founding year you can read, how many do not, and what is the average age in 2026?

Take the first four-digit number in the text as the year.

**Return:** `category`, `with_year`, `unknown`, `avg_age_years` (rounded to 1 decimal). **Sort:** category.

<details><summary>Hint</summary>

`TRY_CAST(regexp_extract(founded, '(\d{4})', 1) AS INTEGER)` returns the year, or NULL when there is none. `count(column)` skips NULLs and `count(*)` does not, so `count(*) - count(founded_year)` is the unknown count.
</details>

---

### 3.08 Cheque sizes

**Question.** `last_round_amount` is free text: `USD 11.7M`, `EUR 1.55M (USD 1.6M)`, `~GBP 4M (~USD 5.3M)`, `UNVERIFIED (an aggregator lists USD 160K total; ...)`, `Acquisition, enterprise value USD 110M`. Only some of these are a clean, confirmed round size.

Keep the values that **start** with `USD` or `EUR`, a number and `M` or `K` (so `~` approximations, `UNVERIFIED` figures, `More than ...` and acquisition prices are left out), and that do not mention a `grant`. Put each of those rounds into a size bucket and count:

`1: under 1M`, `2: 1-5M`, `3: 5-20M`, `4: 20M+` (in millions of the stated currency).

**Return:** `currency`, `size_bucket`, `rounds`. **Sort:** currency, then bucket.

<details><summary>Hint</summary>

`regexp_extract(last_round_amount, '^(USD|EUR) ([0-9.]+)([MK])', 2)` returns the number, and groups 1 and 3 return the currency and the unit. The `^` ties the match to the start of the text. Values that do not match give an empty string for the currency, so `WHERE currency IN ('USD', 'EUR')` drops them. Divide K values by 1000. Starting each bucket name with a number makes the buckets sort in size order.

Do not convert EUR to USD with a rate you pick yourself. The two currencies stay separate.
</details>
