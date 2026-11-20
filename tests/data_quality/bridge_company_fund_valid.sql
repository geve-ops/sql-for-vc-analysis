-- Fund names are clean, each company-fund pair appears once, and every target fund is known.
SELECT 'bad fund name' AS problem, company_id, fund
FROM analytics.bridge_company_fund
WHERE fund = '' OR fund <> trim(fund)
UNION ALL
SELECT 'duplicate pair', company_id, fund
FROM analytics.bridge_company_fund
GROUP BY company_id, fund
HAVING count(*) > 1
UNION ALL
SELECT 'holding status', company_id, fund
FROM analytics.bridge_company_fund
WHERE holding_status IS NULL;
