-- check: ordered
-- Approach: Filter one run, sort by score, LIMIT 5.
-- Watch out: Without the company tie-breaker, tied rows can come back in any order and the fifth row can
--   change between runs.
SELECT company, week_score, funding, press, hiring, github
FROM scores
WHERE date = DATE '2026-11-16'
ORDER BY week_score DESC, company
LIMIT 5;
