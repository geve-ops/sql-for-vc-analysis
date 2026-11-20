-- week_score is the sum of its parts, and each part stays within the tracker's caps.
SELECT date, company_id, week_score, funding, grants, press, hiring, github
FROM scores
WHERE week_score <> funding + grants + press + hiring + github
   OR NOT funding BETWEEN 0 AND 10
   OR NOT grants  BETWEEN 0 AND 6
   OR NOT press   BETWEEN 0 AND 3
   OR NOT hiring  BETWEEN 0 AND 5
   OR github < 0;
