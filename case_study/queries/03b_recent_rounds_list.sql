-- Part B: the rounds behind the summary, each with its first source link from the market map.
WITH rounds AS (
    SELECT w.company_id, w.company, w.category, w.last_round_amount, w.last_round_date,
           regexp_extract(w.last_round_amount, '^(USD|EUR|GBP) ([0-9.]+)([MK])', 1) AS currency,
           strptime(left(w.last_round_date, 7), '%Y-%m')::DATE                     AS round_month
    FROM watchlist AS w
    WHERE regexp_matches(w.last_round_date, '^\d{4}-\d{2}')
      AND w.last_round_date NOT ILIKE '%unverified%'
      AND w.last_round_amount NOT ILIKE '%grant%'
)
SELECT strftime(r.round_month, '%Y-%m')                AS month,
       r.company,
       r.category                                      AS sector,
       r.last_round_amount                             AS amount_as_recorded,
       split_part(c.source_link, ' | ', 1)             AS source
FROM rounds AS r
JOIN companies AS c USING (company_id)
WHERE r.currency <> '' AND r.round_month >= DATE '2025-01-01'
ORDER BY month DESC, r.company;
