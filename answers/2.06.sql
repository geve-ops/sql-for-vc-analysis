-- check: ordered
-- Approach: Anti-join with the date condition inside ON.
-- Watch out: Putting the date filter in WHERE turns the LEFT JOIN back into an inner join and loses
--   exactly the rows you want.
SELECT w.company, w.category
FROM watchlist AS w
LEFT JOIN signals AS s
       ON s.company_id = w.company_id
      AND s.snapshot_date = DATE '2026-11-16'
WHERE s.company_id IS NULL
ORDER BY w.company;
