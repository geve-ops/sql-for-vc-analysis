-- check: ordered
-- Approach: Two NULL tests: has a GitHub org, has no fund tag.
-- Watch out: '= NULL' is never true. Empty CSV cells load as NULL, so IS NULL / IS NOT NULL is the only test.
SELECT company, github_org
FROM watchlist
WHERE greek_funds IS NULL
  AND github_org IS NOT NULL
ORDER BY company;
