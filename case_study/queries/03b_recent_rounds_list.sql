-- Q3b. The rounds behind the summary, each with its first source link from the market map.
SELECT
    strftime(r.round_month, '%Y-%m')    AS month,
    d.company,
    d.sector,
    r.amount_text                       AS amount_as_recorded,
    r.source_url                        AS source
FROM analytics.fct_last_round AS r
JOIN analytics.dim_company AS d ON d.company_id = r.company_id
WHERE d.on_watchlist
  AND r.is_usable
  AND r.round_month >= DATE '2025-01-01'
ORDER BY month DESC, d.company;
