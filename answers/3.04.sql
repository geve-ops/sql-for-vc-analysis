-- check: ordered
-- Approach: Two CTEs: fund holdings, and one total per company. Join them, then sum per fund.
-- Watch out: Total the scores before joining. Joining first repeats each company once per weekly row and
--   inflates the sums.
WITH fund_companies AS (
    SELECT company_id, trim(unnest(string_split(greek_funds, '|'))) AS fund
    FROM watchlist
    WHERE greek_fund_status = 'current'
),
company_totals AS (
    SELECT company_id, sum(week_score) AS total_score
    FROM scores
    GROUP BY company_id
)
SELECT f.fund,
       count(*)           AS companies,
       sum(t.total_score) AS portfolio_score
FROM fund_companies AS f
JOIN company_totals AS t ON t.company_id = f.company_id
GROUP BY f.fund
ORDER BY portfolio_score DESC, f.fund;
