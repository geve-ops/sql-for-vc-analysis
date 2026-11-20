-- check: ordered
SELECT category, count(*) AS n
FROM watchlist
GROUP BY category
HAVING count(*) >= 10
ORDER BY n DESC, category;
