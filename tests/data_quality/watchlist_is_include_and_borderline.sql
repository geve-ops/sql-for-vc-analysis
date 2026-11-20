-- The watchlist is exactly the market map's Include and Borderline companies.
SELECT coalesce(w.company_id, c.company_id) AS company_id,
       CASE WHEN c.company_id IS NULL THEN 'on watchlist, not on map'
            WHEN w.company_id IS NULL THEN 'Include/Borderline, not on watchlist'
            ELSE 'on watchlist with map_status ' || c.map_status END AS problem
FROM watchlist AS w
FULL OUTER JOIN (SELECT * FROM companies WHERE map_status IN ('Include', 'Borderline')) AS c
    ON c.company_id = w.company_id
WHERE w.company_id IS NULL OR c.company_id IS NULL;
