-- check: ordered
-- Approach: LAG over all runs in a CTE, then filter to the latest run.
-- Watch out: Filtering to one date first leaves LAG nothing to look back at, so every prev_week is NULL.
WITH wow AS (
    SELECT date, company, week_score,
           LAG(week_score) OVER (PARTITION BY company_id ORDER BY date) AS prev_week
    FROM scores
)
SELECT company, week_score, prev_week, week_score - prev_week AS change
FROM wow
WHERE date = DATE '2026-11-16'
  AND week_score <> prev_week
ORDER BY change DESC, company;
