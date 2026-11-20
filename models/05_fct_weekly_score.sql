-- fct_weekly_score: the tracker's weekly score with each run's position and momentum weight.
-- Grain: run_date, company_id. Source: scores.
-- weeks_back = 1 for the latest run. Momentum weights: 1, 0.5, 0.25, 0.125 for the last four runs.
CREATE OR REPLACE TABLE analytics.fct_weekly_score AS
WITH runs AS (
    SELECT
        date,
        DENSE_RANK() OVER (ORDER BY date DESC) AS weeks_back
    FROM (SELECT DISTINCT date FROM scores)
)
SELECT
    s.date                                                     AS run_date,
    s.company_id,
    r.weeks_back,
    CASE WHEN r.weeks_back <= 4 THEN power(0.5, r.weeks_back - 1) ELSE 0 END AS momentum_weight,
    s.week_score,
    s.funding,
    s.grants,
    s.press,
    s.hiring,
    s.github
FROM scores AS s
JOIN runs AS r ON r.date = s.date;
