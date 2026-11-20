-- check: ordered
-- Approach: GROUP BY the column you count by; count(*) per group.
-- Watch out: ORDER BY can use the alias n. The second sort key makes ties deterministic.
SELECT map_status, count(*) AS n
FROM companies
GROUP BY map_status
ORDER BY n DESC, map_status;
