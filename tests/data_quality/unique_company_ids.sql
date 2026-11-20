-- Every source table that is one row per company has each company_id once.
SELECT 'companies' AS source_table, company_id, count(*) AS n FROM companies GROUP BY company_id HAVING count(*) > 1
UNION ALL
SELECT 'watchlist', company_id, count(*) FROM watchlist GROUP BY company_id HAVING count(*) > 1
UNION ALL
SELECT 'pipeline', company_id, count(*) FROM pipeline GROUP BY company_id HAVING count(*) > 1
UNION ALL
SELECT 'backtest', company_id, count(*) FROM backtest GROUP BY company_id HAVING count(*) > 1;
