-- check: ordered
SELECT p.company, p.pipeline_stage, p.recommendation, w.category, w.stage
FROM pipeline AS p
JOIN watchlist AS w ON w.company_id = p.company_id
ORDER BY p.company;
