-- Q2a. Which Greek funds hold the most watchlist companies, and how often do they co-invest?
-- One row per fund with a current holding, plus any target fund with none.
WITH holdings AS (
    SELECT company_id, fund, is_target_fund
    FROM analytics.bridge_company_fund
    WHERE is_current
),
co_investment AS (
    SELECT
        h.fund,
        count(DISTINCT o.fund)          AS greek_co_investors,
        count(DISTINCT o.company_id)    AS shared_companies
    FROM holdings AS h
    JOIN holdings AS o ON o.company_id = h.company_id AND o.fund <> h.fund
    GROUP BY h.fund
),
funds AS (
    SELECT fund, count(*) AS current_holdings, bool_or(is_target_fund) AS target_fund
    FROM holdings
    GROUP BY fund
    UNION ALL
    SELECT t.fund, 0, TRUE
    FROM analytics.ref_target_fund AS t
    WHERE t.fund NOT IN (SELECT h.fund FROM holdings AS h)
)
SELECT
    f.fund,
    f.current_holdings,
    coalesce(c.shared_companies, 0)     AS shared_with_another_greek_fund,
    coalesce(c.greek_co_investors, 0)   AS greek_co_investors,
    f.target_fund
FROM funds AS f
LEFT JOIN co_investment AS c ON c.fund = f.fund
ORDER BY f.current_holdings DESC, f.fund;
