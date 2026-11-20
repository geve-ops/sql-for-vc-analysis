-- company_momentum: the tracker's Top Movers ranking, rebuilt in SQL (see exercise 4.07).
-- Grain: company_id (watchlist, 69 rows).
-- momentum_ex_funding drops funding-headline points, to test how much the ranking depends on them.
CREATE OR REPLACE TABLE analytics.company_momentum AS
WITH movers AS (
    SELECT
        company_id,
        round(sum(momentum_weight * week_score), 2)                    AS momentum,
        round(sum(momentum_weight * (week_score - funding)), 2)        AS momentum_ex_funding,
        max(week_score) FILTER (WHERE weeks_back = 1)                  AS this_week,
        max(week_score) FILTER (WHERE weeks_back = 2)                  AS last_week,
        (sum(week_score) FILTER (WHERE weeks_back <= 4))::BIGINT       AS score_4_runs
    FROM analytics.fct_weekly_score
    GROUP BY company_id
)
SELECT
    m.company_id,
    d.company,
    m.momentum,
    m.momentum_ex_funding,
    m.this_week,
    m.last_week,
    m.score_4_runs,
    CASE WHEN m.momentum > 0 THEN
        ROW_NUMBER() OVER (ORDER BY m.momentum DESC, m.this_week DESC, d.company)
    END                                                                AS momentum_rank,
    CASE WHEN m.momentum_ex_funding > 0 THEN
        ROW_NUMBER() OVER (ORDER BY m.momentum_ex_funding DESC, m.this_week DESC, d.company)
    END                                                                AS rank_ex_funding
FROM movers AS m
JOIN analytics.dim_company AS d ON d.company_id = m.company_id;
