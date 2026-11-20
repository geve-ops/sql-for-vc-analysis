-- check: ordered
SELECT company, verification_status
FROM companies
WHERE map_status IN ('Include', 'Borderline')
  AND verification_status ILIKE '%unverified%'
ORDER BY company;
