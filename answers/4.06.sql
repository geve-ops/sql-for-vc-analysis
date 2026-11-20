-- check: ordered
-- Approach: ROW_NUMBER per company by date descending, keep row 1: the top-1-per-group pattern.
-- Watch out: Add a unique tie-breaker (item_id) or two headlines on the same day can swap between runs.
WITH ranked AS (
    SELECT s.company_id, s.title, s.source, s.event_date,
           ROW_NUMBER() OVER (PARTITION BY s.company_id ORDER BY s.event_date DESC, s.item_id) AS rn
    FROM signals AS s
    WHERE s.signal = 'news' AND s.snapshot_date = DATE '2026-11-16'
)
SELECT w.company, r.event_date AS published, r.source, r.title
FROM ranked AS r
JOIN watchlist AS w ON w.company_id = r.company_id
WHERE r.rn = 1
ORDER BY published DESC, w.company;
