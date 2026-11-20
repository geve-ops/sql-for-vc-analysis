-- check: ordered
SELECT company, github_org
FROM watchlist
WHERE greek_funds IS NULL
  AND github_org IS NOT NULL
ORDER BY company;
