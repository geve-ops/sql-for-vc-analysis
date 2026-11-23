-- Q5c. How far did the original scoring rules move the Top Movers ranking?
-- The same momentum ranking (exercise 4.07) on today's scores and on the scores as first published.
WITH momentum AS (
    SELECT
        company_id,
        round(sum(momentum_weight * week_score_now), 2)                AS momentum_now,
        round(sum(momentum_weight * week_score), 2)                    AS momentum_original,
        max(week_score_now) FILTER (WHERE weeks_back = 1)              AS this_week_now,
        max(week_score) FILTER (WHERE weeks_back = 1)                  AS this_week_original
    FROM analytics.fct_weekly_score_original_rule
    GROUP BY company_id
),

ranked AS (
    SELECT
        d.company,
        m.momentum_now,
        m.momentum_original,
        CASE WHEN m.momentum_now > 0 THEN
            ROW_NUMBER() OVER (ORDER BY m.momentum_now DESC, m.this_week_now DESC, d.company)
        END                                                            AS rank_now,
        CASE WHEN m.momentum_original > 0 THEN
            ROW_NUMBER() OVER (ORDER BY m.momentum_original DESC, m.this_week_original DESC, d.company)
        END                                                            AS rank_original
    FROM momentum AS m
    JOIN analytics.dim_company AS d ON d.company_id = m.company_id
)

SELECT
    rank_now            AS rank,
    company,
    momentum_now        AS momentum,
    momentum_original   AS momentum_as_published,
    rank_original       AS rank_as_published
FROM ranked
WHERE rank_now <= 10 OR rank_original <= 10
ORDER BY rank_now NULLS LAST, rank_original;
