-- check: ordered
-- Approach: Count distinct postings per snapshot, then LAG over the whole series.
-- Watch out: No PARTITION BY: the whole watchlist is one series. The first week has no previous value, so
--   change is NULL.
WITH weekly AS (
    SELECT snapshot_date, count(DISTINCT item_id) AS postings
    FROM signals
    WHERE signal = 'job'
    GROUP BY snapshot_date
)
SELECT snapshot_date, postings,
       postings - LAG(postings) OVER (ORDER BY snapshot_date) AS change
FROM weekly
ORDER BY snapshot_date;
