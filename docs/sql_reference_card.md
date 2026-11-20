# SQL reference card

The patterns the exercises use, on one page. All examples run in DuckDB; notes say where other databases differ.

## Query order

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

## Filtering

| Pattern | Example |
|---|---|
| Missing value | `x IS NULL`, `x IS NOT NULL` (never `= NULL`) |
| List | `map_status IN ('Include', 'Borderline')` |
| Contains, any case | `verification_status ILIKE '%unverified%'` |
| Range | `months BETWEEN 15 AND 24` (both ends included) |
| Count matching rows | `count(*) FILTER (WHERE week_score > 0)` |

## Joins

| Join | Keeps |
|---|---|
| `JOIN` (inner) | only rows that match on both sides |
| `LEFT JOIN` | every row on the left; right-side columns are NULL when there is no match |
| Anti-join | `LEFT JOIN ... WHERE right.id IS NULL`, or `WHERE NOT EXISTS (SELECT 1 FROM ...)` |

Watch out: with a `LEFT JOIN`, a filter on the right-hand table in `WHERE` turns it back into an inner join. Put that filter in `ON`.

## CTEs and CASE

```sql
WITH step_one AS (SELECT ...),
     step_two AS (SELECT ... FROM step_one)
SELECT ... FROM step_two;

CASE WHEN x ILIKE '%series a%' THEN 'Series A'   -- the first match wins
     WHEN x ILIKE '%seed%'     THEN 'Seed'
     ELSE 'Other' END
```

## Text and dates (DuckDB)

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

## Window functions

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

## Data quality and modelling (level 5)

| Task | Pattern |
|---|---|
| Find duplicates | `GROUP BY key_cols HAVING count(*) > 1` |
| Compare two snapshots | `FULL OUTER JOIN` on the key; a `NULL` side means added or removed |
| Classify free text | one `CASE`, most specific rule first, catch-all `ELSE` last |
| Ordered list in one cell | `string_agg(name, ', ' ORDER BY name)` |
| Gaps and islands | `ROW_NUMBER()` over all rows minus `ROW_NUMBER()` over the matching rows is constant within a streak |
| Grain check | `count(*)` vs `count(DISTINCT key)`: if they differ, the table is not one row per key |

More DuckDB syntax: [duckdb.org/docs/sql](https://duckdb.org/docs/sql/introduction).
