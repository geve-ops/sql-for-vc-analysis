-- check: ordered
-- Approach: Group, then filter the groups with HAVING.
-- Watch out: WHERE runs before grouping, so it cannot see count(*). Conditions on aggregates go in HAVING.
SELECT category, count(*) AS n
FROM watchlist
GROUP BY category
HAVING count(*) >= 10
ORDER BY n DESC, category;
