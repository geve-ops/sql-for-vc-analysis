-- check: ordered
-- Approach: One CASE, branches in priority order, from the most specific rule to the catch-all.
-- Watch out: The order is the logic: 'UNVERIFIED (... USD 160K ...)' contains a currency amount, but it
--   must be classed as unverified first.
SELECT
    CASE
        WHEN last_round_amount ILIKE 'acquisition%' OR stage ILIKE 'exited%'   THEN 'exit'
        WHEN last_round_amount ILIKE '%grant%'                                THEN 'grant'
        WHEN last_round_amount ILIKE 'unverified%'                            THEN 'unverified'
        WHEN last_round_amount LIKE '~%'                                      THEN 'approximate'
        WHEN last_round_amount ILIKE 'more than%'                             THEN 'lower_bound'
        WHEN regexp_matches(last_round_amount, '^(USD|EUR|GBP) [0-9.]+[MK]')  THEN 'confirmed'
        ELSE 'not_disclosed'
    END AS amount_status,
    count(*) AS companies
FROM watchlist
GROUP BY amount_status
ORDER BY companies DESC, amount_status;
