-- Which Greek funds hold the most watchlist companies, and where do they co-invest?
-- Part A: one row per fund (current holdings only).
WITH holdings AS (
    SELECT company_id, company, trim(unnest(string_split(greek_funds, '|'))) AS fund
    FROM watchlist
    WHERE greek_fund_status = 'current'
),
co AS (
    SELECT h.fund, count(DISTINCT o.fund) AS co_investors,
           count(DISTINCT o.company_id)  AS shared_companies
    FROM holdings AS h
    JOIN holdings AS o ON o.company_id = h.company_id AND o.fund <> h.fund
    GROUP BY h.fund
)
SELECT h.fund,
       count(*)                          AS current_holdings,
       coalesce(c.shared_companies, 0)   AS shared_with_another_greek_fund,
       coalesce(c.co_investors, 0)       AS greek_co_investors,
       h.fund IN ('Big Pi Ventures', 'Marathon VC', 'Metavallon VC', 'Velocity Partners') AS target_fund
FROM holdings AS h
LEFT JOIN co AS c USING (fund)
GROUP BY h.fund, c.shared_companies, c.co_investors
ORDER BY current_holdings DESC, h.fund;
