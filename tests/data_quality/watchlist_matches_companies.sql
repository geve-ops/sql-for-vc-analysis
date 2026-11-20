-- Columns the watchlist copies from the market map hold the same values.
SELECT w.company_id
FROM watchlist AS w
JOIN companies AS c ON c.company_id = w.company_id
WHERE w.company IS DISTINCT FROM c.company
   OR w.category IS DISTINCT FROM c.category
   OR w.map_status IS DISTINCT FROM c.map_status
   OR w.stage IS DISTINCT FROM c.stage
   OR w.last_round_amount IS DISTINCT FROM c.last_round_amount
   OR w.last_round_date IS DISTINCT FROM c.last_round_date;
