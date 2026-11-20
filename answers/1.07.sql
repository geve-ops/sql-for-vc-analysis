-- check: ordered
SELECT company, sum(week_score) AS total_score, count(*) FILTER (WHERE week_score > 0) AS active_weeks
FROM scores
GROUP BY company
HAVING sum(week_score) >= 5
ORDER BY total_score DESC, company;
