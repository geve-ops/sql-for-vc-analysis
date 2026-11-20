-- check: ordered
SELECT c.company, c.category, c.map_status
FROM companies AS c
LEFT JOIN watchlist AS w ON w.company_id = c.company_id
WHERE w.company_id IS NULL
ORDER BY c.company;
