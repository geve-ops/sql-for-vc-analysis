-- check: ordered
-- Approach: Split the multi-fund cell into rows with unnest(string_split()), trim, then count per fund.
-- Watch out: Without trim(), ' Evercurious VC' and 'Evercurious VC' count as two funds.
WITH fund_rows AS (
    SELECT company_id,
           greek_fund_status,
           trim(unnest(string_split(greek_funds, '|'))) AS fund
    FROM watchlist
    WHERE greek_funds IS NOT NULL
)
SELECT fund,
       count(*)                                           AS companies,
       count(*) FILTER (WHERE greek_fund_status = 'current') AS current_holdings
FROM fund_rows
GROUP BY fund
ORDER BY companies DESC, fund;
