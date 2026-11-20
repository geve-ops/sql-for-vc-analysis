-- check: ordered
SELECT w.company, w.category, count(*) AS open_roles
FROM signals AS s
JOIN watchlist AS w ON w.company_id = s.company_id
WHERE s.signal = 'job'
  AND s.snapshot_date = (SELECT max(snapshot_date) FROM signals)
GROUP BY w.company, w.category
ORDER BY open_roles DESC, w.company;
