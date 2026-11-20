-- check: ordered
SELECT company, week_score, funding, press, hiring, github
FROM scores
WHERE date = DATE '2026-11-16'
ORDER BY week_score DESC, company
LIMIT 5;
