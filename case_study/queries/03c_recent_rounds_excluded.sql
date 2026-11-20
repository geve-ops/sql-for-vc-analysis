-- Q3c. Rounds dated January 2025 or later that the summary leaves out, and why.
SELECT
    d.company,
    r.amount_text   AS amount_as_recorded,
    r.date_text     AS date_as_recorded,
    CASE
        WHEN r.date_status = 'unverified'       THEN 'date unverified'
        WHEN r.amount_status = 'approximate'    THEN 'approximate amount'
        WHEN r.amount_status = 'lower_bound'    THEN 'lower bound only'
        WHEN r.amount_status = 'unverified'     THEN 'amount unverified'
        WHEN r.amount_status = 'grant'          THEN 'grant, not a round'
        WHEN r.amount_status = 'exit'           THEN 'exit, not a round'
        ELSE 'amount not disclosed'
    END             AS reason
FROM analytics.fct_last_round AS r
JOIN analytics.dim_company AS d ON d.company_id = r.company_id
WHERE d.on_watchlist
  AND NOT r.is_usable
  AND r.round_month >= DATE '2025-01-01'
ORDER BY reason, d.company;
