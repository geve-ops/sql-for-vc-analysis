-- Part B: every pair of Greek funds that currently share a watchlist company.
WITH holdings AS (
    SELECT company_id, company, trim(unnest(string_split(greek_funds, '|'))) AS fund
    FROM watchlist
    WHERE greek_fund_status = 'current'
)
SELECT a.fund                                    AS fund_a,
       b.fund                                    AS fund_b,
       count(*)                                  AS shared,
       string_agg(a.company, ', ' ORDER BY a.company) AS companies
FROM holdings AS a
JOIN holdings AS b ON b.company_id = a.company_id AND a.fund < b.fund
GROUP BY a.fund, b.fund
ORDER BY shared DESC, fund_a, fund_b;
