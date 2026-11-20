-- signals repeats a job once per city. The copies must agree on everything but the city;
-- no other signal may repeat an item for the same company in one snapshot.
SELECT snapshot_date, company_id, signal, item_id, count(*) AS copies
FROM signals
GROUP BY snapshot_date, company_id, signal, item_id
HAVING (signal <> 'job' AND count(*) > 1)
    OR count(DISTINCT title) > 1
    OR count(DISTINCT url) > 1
    OR count(DISTINCT coalesce(event_date, DATE '1900-01-01')) > 1;
