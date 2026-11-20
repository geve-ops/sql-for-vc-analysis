-- check: ordered
-- Approach: IN for the status list, ILIKE with % for 'contains, any case'.
-- Watch out: LIKE is case-sensitive in DuckDB and PostgreSQL; ILIKE is not. Without both % signs you only
--   match exact text.
SELECT company, verification_status
FROM companies
WHERE map_status IN ('Include', 'Borderline')
  AND verification_status ILIKE '%unverified%'
ORDER BY company;
