-- check: ordered
-- Approach: Inner join pipeline to watchlist on company_id.
-- Watch out: Join on the ID, never the name: names get rebranded, IDs do not.
SELECT p.company, p.pipeline_stage, p.recommendation, w.category, w.stage
FROM pipeline AS p
JOIN watchlist AS w ON w.company_id = p.company_id
ORDER BY p.company;
