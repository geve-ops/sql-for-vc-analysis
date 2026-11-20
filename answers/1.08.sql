-- check: ordered
-- Approach: Group by the backtest outcome; round the averages.
-- Watch out: Fifteen rows is far too few to claim that commits predict rounds. Say so before anyone else
--   does.
SELECT change,
       count(*)                         AS companies,
       round(avg(commits_baseline), 1)  AS avg_baseline,
       round(avg(commits_before), 1)    AS avg_before
FROM backtest
GROUP BY change
ORDER BY companies DESC, change;
