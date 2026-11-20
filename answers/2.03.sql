-- check: ordered
SELECT p.company, p.pipeline_stage, coalesce(sum(s.week_score), 0) AS total_score
FROM pipeline AS p
LEFT JOIN scores AS s ON s.company_id = p.company_id
GROUP BY p.company, p.pipeline_stage
ORDER BY total_score DESC, p.company;
