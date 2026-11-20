# Level 1: SELECT, WHERE, ORDER BY, GROUP BY, HAVING

One table at a time. Write each answer in `my_answers/<id>.sql`, then run `python check.py <id>`.

Every exercise lists the columns to return and the sort order. The checker compares values and order, not column names.

---

### 1.01 Robotics companies on the map

**Question.** A partner wants a quick list of every Robotics & Drones company in the market map, so they can see what each one does and how far along it is.

**Return:** `company`, `sub_sector`, `stage` from `companies`. **Sort:** company name A to Z.

<details><summary>Hint</summary>

`WHERE category = 'Robotics & Drones'`. Text in SQL goes in single quotes and must match exactly, including the `&`.
</details>

---

### 1.02 How the map is split

**Question.** How many companies in the market map are Include, Borderline, Exclude and Hold?

**Return:** `map_status`, `n` (number of companies). **Sort:** largest `n` first, then `map_status` A to Z.

<details><summary>Hint</summary>

`GROUP BY map_status` with `count(*) AS n`. You can sort by an alias: `ORDER BY n DESC, map_status`.
</details>

---

### 1.03 The crowded sectors

**Question.** Which sectors have at least 10 companies on the watchlist? These are the sectors where a fund needs a view on who leads.

**Return:** `category`, `n`. **Sort:** `n` largest first, then `category`.

<details><summary>Hint</summary>

`WHERE` filters rows before grouping. `HAVING` filters groups after grouping. A condition on `count(*)` belongs in `HAVING`.
</details>

---

### 1.04 Code-visible companies no Greek fund has backed

**Question.** Which watchlist companies have a GitHub organisation but no Greek fund tag? They are possible sourcing gaps where you can still watch the engineering activity.

**Return:** `company`, `github_org`. **Sort:** company.

<details><summary>Hint</summary>

An empty cell in the CSV becomes `NULL`. `= NULL` never matches anything. Use `IS NULL` and `IS NOT NULL`.
</details>

---

### 1.05 Diligence red flags

**Question.** Which Include or Borderline companies have something still UNVERIFIED in their `verification_status`? This is the to-do list before any of them goes in a memo.

**Return:** `company`, `verification_status` from `companies`. **Sort:** company.

<details><summary>Hint</summary>

`map_status IN ('Include', 'Borderline')`. For "contains", use `ILIKE '%unverified%'`: `%` means any text, and `ILIKE` ignores upper and lower case.
</details>

---

### 1.06 This week's top 5

**Question.** In the 16 November 2026 run, which 5 companies scored highest this week, and which signals drove the score?

**Return:** `company`, `week_score`, `funding`, `press`, `hiring`, `github` from `scores`. **Sort:** `week_score` highest first, ties by company. Return 5 rows.

<details><summary>Hint</summary>

Write a date as `DATE '2026-11-16'`. `LIMIT 5` goes last. Without the tie-breaker on company, the order of tied rows can change from run to run.
</details>

---

### 1.07 Who keeps showing up

**Question.** Across all weekly runs, which companies have a total score of 5 or more? How many weeks did each one score at all?

**Return:** `company`, `total_score` (sum of `week_score`), `active_weeks` (weeks with `week_score > 0`). **Sort:** `total_score` highest first, then company.

<details><summary>Hint</summary>

`count(*) FILTER (WHERE week_score > 0)` counts only the rows that match. `sum(CASE WHEN week_score > 0 THEN 1 ELSE 0 END)` does the same in any SQL dialect.
</details>

---

### 1.08 Does GitHub activity move before a round?

**Question.** In the backtest, group companies by what their commits did before the round (`change`: rose, fell, flat, no activity). How many companies are in each group, and what were the average commits in the baseline and pre-round windows?

**Return:** `change`, `companies`, `avg_baseline`, `avg_before` (averages rounded to 1 decimal). **Sort:** `companies` largest first, then `change`.

<details><summary>Hint</summary>

`round(avg(commits_baseline), 1)`. Fifteen rows is a tiny sample. In an interview, say that before you draw any conclusion from it.
</details>
