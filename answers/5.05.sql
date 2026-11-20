-- check: ordered
-- Approach: Gaps and islands: row number over all runs minus row number over scoring runs is constant
--   within a streak.
-- Watch out: Filter to scoring runs before the second ROW_NUMBER, not after, or the difference never changes.
WITH flagged AS (
    SELECT company_id, date, week_score > 0 AS scored,
           ROW_NUMBER() OVER (PARTITION BY company_id ORDER BY date) AS run_no
    FROM scores
),
islands AS (
    SELECT company_id,
           run_no - ROW_NUMBER() OVER (PARTITION BY company_id ORDER BY date) AS island
    FROM flagged
    WHERE scored
),
streaks AS (
    SELECT company_id, island, count(*) AS streak
    FROM islands
    GROUP BY company_id, island
)
SELECT w.company, max(s.streak) AS longest_streak
FROM streaks AS s
JOIN watchlist AS w ON w.company_id = s.company_id
GROUP BY w.company
HAVING max(s.streak) >= 2
ORDER BY longest_streak DESC, w.company;
