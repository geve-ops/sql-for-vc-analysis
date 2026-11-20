-- check: ordered
WITH weekly AS (
    SELECT snapshot_date, count(*) AS postings
    FROM signals
    WHERE signal = 'job'
    GROUP BY snapshot_date
)
SELECT snapshot_date, postings,
       postings - LAG(postings) OVER (ORDER BY snapshot_date) AS change
FROM weekly
ORDER BY snapshot_date;
