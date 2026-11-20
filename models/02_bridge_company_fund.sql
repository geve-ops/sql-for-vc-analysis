-- bridge_company_fund: one row per company and Greek fund.
-- Grain: company_id, fund. Source: watchlist.greek_funds, a ' | '-separated list.
CREATE OR REPLACE TABLE analytics.bridge_company_fund AS
SELECT
    w.company_id,
    trim(f.fund)                                AS fund,
    w.greek_fund_status                         AS holding_status,
    w.greek_fund_status = 'current'             AS is_current,
    t.fund IS NOT NULL                          AS is_target_fund
FROM watchlist AS w
CROSS JOIN unnest(string_split(w.greek_funds, '|')) AS f (fund)
LEFT JOIN analytics.ref_target_fund AS t ON t.fund = trim(f.fund)
WHERE w.greek_funds IS NOT NULL;
