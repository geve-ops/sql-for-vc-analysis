-- check: ordered
WITH this_week AS (
    SELECT DISTINCT company_id, item_id, title
    FROM signals
    WHERE signal = 'job' AND snapshot_date = DATE '2026-11-16'
),
last_week AS (
    SELECT company_id, item_id
    FROM signals
    WHERE signal = 'job' AND snapshot_date = DATE '2026-11-09'
)
SELECT w.company, t.item_id, t.title
FROM this_week AS t
JOIN watchlist AS w ON w.company_id = t.company_id
WHERE NOT EXISTS (
    SELECT 1 FROM last_week AS l
    WHERE l.company_id = t.company_id AND l.item_id = t.item_id
)
ORDER BY w.company, t.title, t.item_id;
