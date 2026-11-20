-- Q3a. How is recent capital spread? Usable rounds dated January 2025 or later, per currency.
-- "Usable" = confirmed amount and confirmed date (see models/03_fct_last_round.sql).
-- Currencies are never converted: no exchange rate is assumed.
SELECT
    r.currency,
    count(*)                                              AS rounds,
    round(sum(r.amount_m), 2)                             AS total_m,
    round(median(r.amount_m), 2)                          AS median_m,
    round(max(r.amount_m), 2)                             AS largest_m,
    round(100.0 * max(r.amount_m) / sum(r.amount_m), 1)   AS largest_pct_of_total,
    count(*) FILTER (WHERE r.amount_m < 5)                AS under_5m
FROM analytics.fct_last_round AS r
JOIN analytics.dim_company AS d ON d.company_id = r.company_id
WHERE d.on_watchlist
  AND r.is_usable
  AND r.round_month >= DATE '2025-01-01'
GROUP BY r.currency
ORDER BY rounds DESC, r.currency;
