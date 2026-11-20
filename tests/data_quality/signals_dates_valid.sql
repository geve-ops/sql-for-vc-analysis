-- No item is dated after the snapshot that saw it, and the four snapshots match the score runs.
SELECT 'event after snapshot' AS problem, snapshot_date, company_id, item_id
FROM signals
WHERE event_date > snapshot_date
UNION ALL
SELECT 'snapshot without a score run', snapshot_date, NULL, NULL
FROM (SELECT DISTINCT snapshot_date FROM signals)
WHERE snapshot_date NOT IN (SELECT DISTINCT s.date FROM scores AS s);
