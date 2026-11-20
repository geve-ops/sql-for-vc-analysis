-- Q1. Where is the investable universe, and how much of it can a fund actually see?
-- One row per sector of the watchlist (the market map's Include and Borderline companies).
SELECT
    d.sector,
    count(*)                                                        AS companies,
    count(*) FILTER (WHERE d.map_status = 'Include')                AS include,
    count(*) FILTER (WHERE d.greek_fund_status = 'current')         AS greek_fund_backed,
    count(*) FILTER (WHERE r.amount_status = 'confirmed')           AS confirmed_round_size,
    count(*) FILTER (WHERE m.score_4_runs > 0)                      AS scored_in_4_weeks,
    round(100.0 * count(*) / sum(count(*)) OVER (), 1)              AS pct_of_watchlist
FROM analytics.dim_company AS d
JOIN analytics.fct_last_round AS r ON r.company_id = d.company_id
JOIN analytics.company_momentum AS m ON m.company_id = d.company_id
WHERE d.on_watchlist
GROUP BY d.sector
ORDER BY companies DESC, d.sector;
