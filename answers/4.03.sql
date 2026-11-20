-- check: ordered
SELECT s.company, s.date, s.week_score,
       sum(s.week_score) OVER (PARTITION BY s.company_id ORDER BY s.date) AS running_total
FROM scores AS s
JOIN pipeline AS p ON p.company_id = s.company_id
ORDER BY s.company, s.date;
