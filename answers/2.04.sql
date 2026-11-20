-- check: ordered
-- Approach: Join the backtest to the market map for the sector; filter on change.
-- Watch out: Both tables carry a company column; prefix with the alias so it is clear which one you mean.
SELECT b.company, c.category, b.round_month, b.round, b.commits_baseline, b.commits_before
FROM backtest AS b
JOIN companies AS c ON c.company_id = b.company_id
WHERE b.change = 'rose'
ORDER BY b.company;
