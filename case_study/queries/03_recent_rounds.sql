-- How is recent capital spread? Rounds dated January 2025 or later, with a confirmed size.
-- Part A: summary per currency. Currencies are never converted: no exchange rate is assumed.
WITH rounds AS (
    SELECT w.company_id, w.company, w.category,
           regexp_extract(w.last_round_amount, '^(USD|EUR|GBP) ([0-9.]+)([MK])', 1) AS currency,
           TRY_CAST(regexp_extract(w.last_round_amount, '^(USD|EUR|GBP) ([0-9.]+)([MK])', 2) AS DOUBLE)
             / CASE regexp_extract(w.last_round_amount, '^(USD|EUR|GBP) ([0-9.]+)([MK])', 3)
                 WHEN 'K' THEN 1000 ELSE 1 END                                     AS amount_m,
           strptime(left(w.last_round_date, 7), '%Y-%m')::DATE                     AS round_month
    FROM watchlist AS w
    WHERE regexp_matches(w.last_round_date, '^\d{4}-\d{2}')
      AND w.last_round_date NOT ILIKE '%unverified%'
      AND w.last_round_amount NOT ILIKE '%grant%'
)
SELECT currency,
       count(*)                                           AS rounds,
       round(sum(amount_m), 2)                            AS total_m,
       round(median(amount_m), 2)                         AS median_m,
       round(max(amount_m), 2)                            AS largest_m,
       round(100.0 * max(amount_m) / sum(amount_m), 1)    AS largest_pct_of_total,
       count(*) FILTER (WHERE amount_m < 5)               AS under_5m
FROM rounds
WHERE currency <> '' AND round_month >= DATE '2025-01-01'
GROUP BY currency
ORDER BY rounds DESC, currency;
