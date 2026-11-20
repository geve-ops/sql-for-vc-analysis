-- How much of the Top Movers ranking rests on funding points?
-- The tracker's momentum (as in exercise 4.07), next to the same score with funding points removed.
WITH runs AS (
    SELECT date, DENSE_RANK() OVER (ORDER BY date DESC) AS weeks_back
    FROM (SELECT DISTINCT date FROM scores)
),
weighted AS (
    SELECT s.company_id, s.company, r.weeks_back, s.week_score, s.funding,
           CASE r.weeks_back WHEN 1 THEN 1.0 WHEN 2 THEN 0.5 WHEN 3 THEN 0.25 WHEN 4 THEN 0.125 END AS w
    FROM scores AS s
    JOIN runs AS r USING (date)
    WHERE r.weeks_back <= 4
),
movers AS (
    SELECT company,
           round(sum(w * week_score), 2)                  AS momentum,
           round(sum(w * (week_score - funding)), 2)      AS without_funding,
           max(week_score) FILTER (WHERE weeks_back = 1)  AS this_week
    FROM weighted
    GROUP BY company_id, company
),
ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (ORDER BY momentum DESC, this_week DESC, company)        AS rank,
           ROW_NUMBER() OVER (ORDER BY without_funding DESC, this_week DESC, company) AS rank_without
    FROM movers
    WHERE momentum > 0
)
SELECT rank, company, momentum, without_funding, rank_without AS rank_without_funding
FROM ranked
WHERE rank <= 10
ORDER BY rank;
