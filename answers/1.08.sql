-- check: ordered
SELECT change,
       count(*)                         AS companies,
       round(avg(commits_baseline), 1)  AS avg_baseline,
       round(avg(commits_before), 1)    AS avg_before
FROM backtest
GROUP BY change
ORDER BY companies DESC, change;
