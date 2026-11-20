-- check: ordered
SELECT map_status, count(*) AS n
FROM companies
GROUP BY map_status
ORDER BY n DESC, map_status;
