-- check: ordered
-- Approach: Filtered distinct counts per company: recent, older, all.
-- Watch out: Postings with no publish date (NULL) count in total but in neither bucket; a NULL comparison
--   is never true.
SELECT w.company,
       count(DISTINCT s.item_id) FILTER (WHERE s.event_date >= s.snapshot_date - INTERVAL 30 DAY) AS fresh_30d,
       count(DISTINCT s.item_id) FILTER (WHERE s.event_date <  s.snapshot_date - INTERVAL 30 DAY) AS older,
       count(DISTINCT s.item_id)                                                                AS total
FROM signals AS s
JOIN watchlist AS w ON w.company_id = s.company_id
WHERE s.signal = 'job'
  AND s.snapshot_date = DATE '2026-11-16'
GROUP BY w.company
ORDER BY fresh_30d DESC, w.company;
