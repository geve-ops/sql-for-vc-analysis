-- scores has exactly one row per watchlist company per weekly run.
WITH expected AS (
    SELECT r.date, w.company_id
    FROM (SELECT DISTINCT date FROM scores) AS r
    CROSS JOIN watchlist AS w
),
actual AS (
    SELECT date, company_id, count(*) AS n
    FROM scores
    GROUP BY date, company_id
)
SELECT coalesce(e.date, a.date) AS date, coalesce(e.company_id, a.company_id) AS company_id, a.n
FROM expected AS e
FULL OUTER JOIN actual AS a ON a.date = e.date AND a.company_id = e.company_id
WHERE a.n IS DISTINCT FROM 1;
