-- check: ordered
-- Approach: Start from pipeline so every pipeline company stays; LEFT JOIN the scores; coalesce the empty
--   total to 0.
-- Watch out: Every selected column that is not aggregated must be in GROUP BY.
SELECT p.company, p.pipeline_stage, coalesce(sum(s.week_score), 0) AS total_score
FROM pipeline AS p
LEFT JOIN scores AS s ON s.company_id = p.company_id
GROUP BY p.company, p.pipeline_stage
ORDER BY total_score DESC, p.company;
