-- Part C: recent rounds left out of the summary, and why.
SELECT w.company,
       w.last_round_amount AS amount_as_recorded,
       w.last_round_date   AS date_as_recorded,
       CASE
         WHEN w.last_round_date ILIKE '%unverified%'          THEN 'date unverified'
         WHEN w.last_round_amount ILIKE '%grant%'             THEN 'grant, not a round'
         WHEN w.last_round_amount LIKE '~%'                    THEN 'approximate amount'
         WHEN w.last_round_amount ILIKE 'more than%'           THEN 'lower bound only'
         ELSE 'amount not disclosed'
       END                  AS reason
FROM watchlist AS w
WHERE regexp_matches(w.last_round_date, '^\d{4}-\d{2}')
  AND strptime(left(w.last_round_date, 7), '%Y-%m')::DATE >= DATE '2025-01-01'
  AND NOT (regexp_matches(w.last_round_amount, '^(USD|EUR|GBP) [0-9.]+[MK]')
           AND w.last_round_amount NOT ILIKE '%grant%'
           AND w.last_round_date NOT ILIKE '%unverified%')
ORDER BY reason, w.company;
