# Level 5: Data quality and modelling

An analyst who only queries clean tables is at the mercy of whoever cleaned them. This level is about checking and shaping the data yourself: finding duplicates, comparing snapshots, turning free text into categories, spotting records that belong to more than one company, and the "gaps and islands" pattern for streaks. These are the queries behind the kit's own [models](../models/) and [data-quality rules](../tests/data_quality/).

Use the source tables (`signals`, `scores`, `watchlist`), not the `analytics` schema: the point is to build what the models do.

---

### 5.01 Find the duplicate rows

**Question.** Before counting anything, check the grain. In the 16 November 2026 snapshot, which job postings appear more than once in `signals`, and how many times?

**Return:** `company`, `item_id`, `title`, `copies`. Only postings with more than one row. **Sort:** `copies` highest first, then company, then `item_id`.

<details><summary>Hint</summary>

`GROUP BY` the columns that should be unique, then `HAVING count(*) > 1`. Every non-grouped column needs an aggregate; `any_value(title)` takes one value when you know they are all the same. Look at the locations of the posting with six copies: some copies are not even different cities. That is why the kit's `fct_signal` model keeps one row per posting.
</details>

---

### 5.02 Opened and closed roles

**Question.** Between the 9 and 16 November 2026 snapshots, how many job postings did each company open (new this week) and close (gone this week)?

**Return:** `company`, `opened`, `closed`, `net` (opened minus closed). Only companies with at least one change. **Sort:** `net` highest first, then company.

<details><summary>Hint</summary>

Make one CTE per week with `SELECT DISTINCT company_id, item_id`, so each posting counts once. A `FULL OUTER JOIN` on company and item keeps the rows that exist on either side: where last week's side is `NULL` the posting is new, and where this week's side is `NULL` it closed. Use `coalesce(t.company_id, l.company_id)` for the company, because one of the two is always `NULL`.
</details>

---

### 5.03 Classify free text into a clean status

**Question.** Turn `watchlist.last_round_amount` into a status a model can rely on, and count the companies in each status. Test the rules in this order, and take the first that matches:

1. `exit`: the text starts with "acquisition", or `stage` starts with "exited"
2. `grant`: the text mentions "grant"
3. `unverified`: the text starts with "UNVERIFIED"
4. `approximate`: the text starts with `~`
5. `lower_bound`: the text starts with "more than"
6. `confirmed`: the text starts with USD, EUR or GBP, a number and M or K
7. `not_disclosed`: everything else

**Return:** `amount_status`, `companies`. **Sort:** `companies` highest first, then status.

<details><summary>Hint</summary>

A `CASE` with the branches in exactly this order. `ILIKE 'acquisition%'` matches any case; `LIKE '~%'` needs no case rule. For `confirmed`, use `regexp_matches(last_round_amount, '^(USD|EUR|GBP) [0-9.]+[MK]')`. Compare your rules with [models/03_fct_last_round.sql](../models/03_fct_last_round.sql), which builds the same status for every company.
</details>

---

### 5.04 One record, two companies

**Question.** A CORDIS project can be matched to more than one watchlist company when both are partners in it. Adding up EU money by company would then count that project twice. In the 16 November 2026 snapshot, which projects are linked to more than one company?

**Return:** `project_id` (the `item_id`), `acronym`, `companies` (how many), `partners` (company names, comma-separated, A to Z). **Sort:** `project_id`.

<details><summary>Hint</summary>

Group by `item_id`, keep groups with `count(DISTINCT company_id) > 1`. `string_agg(w.company, ', ' ORDER BY w.company)` builds the list in a fixed order, so the result is the same on every run.
</details>

---

### 5.05 Longest scoring streak (gaps and islands)

**Question.** For each company, what is the longest run of consecutive weekly runs with a score above 0? Show companies whose longest streak is at least 2 runs.

**Return:** `company`, `longest_streak`. **Sort:** `longest_streak` highest first, then company.

<details><summary>Hint</summary>

The classic trick: number every run per company (`ROW_NUMBER() OVER (PARTITION BY company_id ORDER BY date)`), keep only the scoring runs, and number those again. Within an unbroken streak both numbers rise by one each week, so their difference stays the same; it changes after every gap. Group by company and that difference to get each streak's length, then take the maximum per company.
</details>
