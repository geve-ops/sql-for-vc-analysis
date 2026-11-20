-- check: ordered
SELECT b.company, c.category, b.round_month, b.round, b.commits_baseline, b.commits_before
FROM backtest AS b
JOIN companies AS c ON c.company_id = b.company_id
WHERE b.change = 'rose'
ORDER BY b.company;
