-- analytics.fct_signal is one row per snapshot, company, signal and item, and loses no item.
SELECT 'duplicate' AS problem, snapshot_date, company_id, signal, item_id
FROM analytics.fct_signal
GROUP BY snapshot_date, company_id, signal, item_id
HAVING count(*) > 1
UNION ALL
SELECT 'listings do not add up', NULL, NULL, NULL, NULL
WHERE (SELECT sum(listings) FROM analytics.fct_signal) <> (SELECT count(*) FROM signals);
