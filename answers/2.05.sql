-- check: ordered
-- Approach: Filter to the latest snapshot with a scalar subquery; count distinct postings per company.
-- Watch out: count(*) counts rows. A posting listed in six cities is six rows, so count(DISTINCT item_id).
SELECT w.company, w.category, count(DISTINCT s.item_id) AS open_roles
FROM signals AS s
JOIN watchlist AS w ON w.company_id = s.company_id
WHERE s.signal = 'job'
  AND s.snapshot_date = (SELECT max(l.snapshot_date) FROM signals AS l)
GROUP BY w.company, w.category
ORDER BY open_roles DESC, w.company;
