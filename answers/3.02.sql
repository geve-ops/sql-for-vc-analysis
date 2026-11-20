-- check: ordered
WITH rounds AS (
    SELECT company,
           strptime(left(last_round_date, 7), '%Y-%m')::DATE AS round_month
    FROM watchlist
    WHERE regexp_matches(last_round_date, '^\d{4}-\d{2}')
)
SELECT company,
       round_month,
       date_diff('month', round_month, DATE '2026-11-16') AS months_since
FROM rounds
WHERE date_diff('month', round_month, DATE '2026-11-16') BETWEEN 15 AND 24
ORDER BY months_since DESC, company;
