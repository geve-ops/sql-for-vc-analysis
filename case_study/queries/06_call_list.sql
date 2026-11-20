-- Q6. Who should a Greek fund call this month?
-- Companies whose last dated round was 15 to 24 months before the latest run (the usual gap to the
-- next round), with their Greek investors, open postings and four-week score. Exits are left out.
WITH latest AS (
    SELECT max(run_date) AS run_date FROM analytics.fct_weekly_score
),
open_roles AS (
    SELECT company_id, count(*) AS open_roles
    FROM analytics.fct_signal
    WHERE signal = 'job'
      AND snapshot_date = (SELECT max(l.snapshot_date) FROM analytics.fct_signal AS l)
    GROUP BY company_id
),
current_funds AS (
    SELECT company_id, string_agg(fund, ', ' ORDER BY fund) AS funds
    FROM analytics.bridge_company_fund
    WHERE is_current
    GROUP BY company_id
)
SELECT
    d.company,
    d.sector,
    date_diff('month', r.round_month, l.run_date)   AS months_since_round,
    r.amount_text                                   AS last_round,
    coalesce(f.funds, '-')                          AS greek_funds,
    coalesce(o.open_roles, 0)                       AS open_roles,
    m.score_4_runs                                  AS score_4w,
    d.has_unverified_fact                           AS has_unverified_fact,
    r.source_url                                    AS round_source
FROM analytics.fct_last_round AS r
CROSS JOIN latest AS l
JOIN analytics.dim_company AS d ON d.company_id = r.company_id
JOIN analytics.company_momentum AS m ON m.company_id = r.company_id
LEFT JOIN open_roles AS o ON o.company_id = r.company_id
LEFT JOIN current_funds AS f ON f.company_id = r.company_id
WHERE d.on_watchlist
  AND r.date_status <> 'missing'
  AND r.amount_status <> 'exit'
  AND date_diff('month', r.round_month, l.run_date) BETWEEN 15 AND 24
ORDER BY score_4w DESC, open_roles DESC, d.company;
