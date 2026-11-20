-- check: ordered
SELECT w.company, w.category
FROM watchlist AS w
LEFT JOIN signals AS s
       ON s.company_id = w.company_id
      AND s.snapshot_date = DATE '2026-11-16'
WHERE s.company_id IS NULL
ORDER BY w.company;
