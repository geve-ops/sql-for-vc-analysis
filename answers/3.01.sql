-- check: ordered
-- Approach: CASE in priority order: Series B+ first, then Series A, then seed.
-- Watch out: The first matching branch wins. 'Venture debt (after Series A)' must hit Series A before
--   anything else matches.
SELECT CASE
         WHEN stage ILIKE '%series b%' OR stage ILIKE '%series c%'
           OR stage ILIKE '%late stage%' OR stage ILIKE '%growth%' THEN 'Series B+'
         WHEN stage ILIKE '%series a%'                              THEN 'Series A'
         WHEN stage ILIKE '%seed%'                                  THEN 'Pre-seed / Seed'
         ELSE 'Other'
       END AS stage_bucket,
       count(*) AS companies
FROM watchlist
GROUP BY stage_bucket
ORDER BY companies DESC, stage_bucket;
