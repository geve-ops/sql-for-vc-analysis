-- analytics.dim_company has every market-map company exactly once and flags the watchlist correctly.
SELECT 'row count' AS problem, NULL AS company_id
WHERE (SELECT count(*) FROM analytics.dim_company) <> (SELECT count(*) FROM companies)
   OR (SELECT count(DISTINCT company_id) FROM analytics.dim_company) <> (SELECT count(*) FROM companies)
UNION ALL
SELECT 'watchlist flag', d.company_id
FROM analytics.dim_company AS d
WHERE d.on_watchlist <> (d.company_id IN (SELECT w.company_id FROM watchlist AS w))
UNION ALL
SELECT 'founded year out of range', d.company_id
FROM analytics.dim_company AS d
WHERE d.founded_year NOT BETWEEN 1950 AND 2026;
