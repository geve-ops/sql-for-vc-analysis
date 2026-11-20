-- check: ordered
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
