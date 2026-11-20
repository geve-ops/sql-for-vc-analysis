-- check: ordered
-- Approach: GROUP BY the columns that should be unique; HAVING count(*) > 1 shows where they are not.
-- Watch out: Check the grain before every count. Here one posting is six rows, some with identical locations.
SELECT w.company, s.item_id, any_value(s.title) AS title, count(*) AS copies
FROM signals AS s
JOIN watchlist AS w ON w.company_id = s.company_id
WHERE s.signal = 'job'
  AND s.snapshot_date = DATE '2026-11-16'
GROUP BY w.company, s.item_id
HAVING count(*) > 1
ORDER BY copies DESC, w.company, s.item_id;
