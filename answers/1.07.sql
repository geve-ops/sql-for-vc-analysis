-- check: ordered
-- Approach: sum() for the total, a filtered count for the active weeks, HAVING on the total.
-- Watch out: count(*) FILTER (WHERE ...) is the readable form; sum(CASE WHEN ... THEN 1 ELSE 0 END) works
--   in every dialect.
SELECT company, sum(week_score) AS total_score, count(*) FILTER (WHERE week_score > 0) AS active_weeks
FROM scores
GROUP BY company
HAVING sum(week_score) >= 5
ORDER BY total_score DESC, company;
