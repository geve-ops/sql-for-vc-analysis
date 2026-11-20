-- check: ordered
-- Momentum = this week's score + 0.5 x last week + 0.25 x two weeks ago + 0.125 x three weeks ago.
WITH runs AS (
    SELECT date, DENSE_RANK() OVER (ORDER BY date DESC) AS weeks_back   -- 1 = latest run
    FROM (SELECT DISTINCT date FROM scores)
),
weighted AS (
    SELECT s.company_id, s.company, s.date, s.week_score, r.weeks_back,
           s.week_score * CASE r.weeks_back WHEN 1 THEN 1.0 WHEN 2 THEN 0.5
                                            WHEN 3 THEN 0.25 WHEN 4 THEN 0.125 END AS weighted_score
    FROM scores AS s
    JOIN runs AS r USING (date)
    WHERE r.weeks_back <= 4
),
movers AS (
    SELECT company_id, company,
           round(sum(weighted_score), 2)                    AS momentum,
           max(week_score) FILTER (WHERE weeks_back = 1)    AS week_score,
           max(week_score) FILTER (WHERE weeks_back = 2)    AS last_week
    FROM weighted
    GROUP BY company_id, company
)
SELECT ROW_NUMBER() OVER (ORDER BY momentum DESC, week_score DESC, company) AS rank,
       company, momentum, week_score, last_week
FROM movers
WHERE momentum > 0
ORDER BY rank
LIMIT 10;
