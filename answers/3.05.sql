-- check: ordered
SELECT w.company,
       sum(CASE WHEN s.event_date >= s.snapshot_date - INTERVAL 30 DAY THEN 1 ELSE 0 END) AS fresh_30d,
       sum(CASE WHEN s.event_date <  s.snapshot_date - INTERVAL 30 DAY THEN 1 ELSE 0 END) AS older,
       count(*) AS total
FROM signals AS s
JOIN watchlist AS w ON w.company_id = s.company_id
WHERE s.signal = 'job'
  AND s.snapshot_date = DATE '2026-11-16'
GROUP BY w.company
ORDER BY fresh_30d DESC, w.company;
