-- check: ordered
-- Approach: FULL OUTER JOIN this week to last week: a NULL on one side means opened or closed.
-- Watch out: Use DISTINCT in both CTEs, or a multi-city posting multiplies the join. coalesce the key,
--   since one side is always NULL.
WITH this_week AS (
    SELECT DISTINCT company_id, item_id
    FROM signals
    WHERE signal = 'job' AND snapshot_date = DATE '2026-11-16'
),
last_week AS (
    SELECT DISTINCT company_id, item_id
    FROM signals
    WHERE signal = 'job' AND snapshot_date = DATE '2026-11-09'
),
changes AS (
    SELECT coalesce(t.company_id, l.company_id) AS company_id,
           count(*) FILTER (WHERE l.item_id IS NULL) AS opened,
           count(*) FILTER (WHERE t.item_id IS NULL) AS closed
    FROM this_week AS t
    FULL OUTER JOIN last_week AS l ON l.company_id = t.company_id AND l.item_id = t.item_id
    GROUP BY coalesce(t.company_id, l.company_id)
)
SELECT w.company, c.opened, c.closed, c.opened - c.closed AS net
FROM changes AS c
JOIN watchlist AS w ON w.company_id = c.company_id
WHERE c.opened > 0 OR c.closed > 0
ORDER BY net DESC, w.company;
