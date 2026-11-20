-- check: ordered
SELECT w.category,
       count(DISTINCT s.item_id)                                                AS postings,
       round(100.0 * count(DISTINCT s.item_id) / sum(count(DISTINCT s.item_id)) OVER (), 1) AS pct_of_all
FROM signals AS s
JOIN watchlist AS w ON w.company_id = s.company_id
WHERE s.signal = 'job' AND s.snapshot_date = DATE '2026-11-16'
GROUP BY w.category
ORDER BY postings DESC, w.category;
