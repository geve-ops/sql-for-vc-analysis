-- check: ordered
WITH totals AS (
    SELECT w.category, w.company, sum(s.week_score) AS total_score
    FROM scores AS s
    JOIN watchlist AS w ON w.company_id = s.company_id
    GROUP BY w.category, w.company
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY category ORDER BY total_score DESC) AS rnk
    FROM totals
    WHERE total_score > 0
)
SELECT category, company, total_score
FROM ranked
WHERE rnk = 1
ORDER BY category, company;
