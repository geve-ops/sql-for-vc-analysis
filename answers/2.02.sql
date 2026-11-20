-- check: ordered
-- Approach: Anti-join: LEFT JOIN, then keep the rows with no match.
-- Watch out: Test the right table's join key for NULL (w.company_id), not a column that could be NULL anyway.
SELECT c.company, c.category, c.map_status
FROM companies AS c
LEFT JOIN watchlist AS w ON w.company_id = c.company_id
WHERE w.company_id IS NULL
ORDER BY c.company;
