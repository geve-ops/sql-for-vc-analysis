-- Key figures quoted in the case study text. Each row is one named number, computed here so that
-- no figure in the text is typed by hand. build_report.py fills {{fact:metric}} from this table.
WITH
watch AS (SELECT * FROM analytics.dim_company WHERE on_watchlist),
sectors AS (
    SELECT sector, count(*) AS n, ROW_NUMBER() OVER (ORDER BY count(*) DESC, sector) AS rk
    FROM watch GROUP BY sector
),
holdings AS (SELECT * FROM analytics.bridge_company_fund WHERE is_current),
pairs AS (
    SELECT a.fund AS fund_a, b.fund AS fund_b, a.company_id, a.is_target_fund AND b.is_target_fund AS both_target
    FROM holdings AS a JOIN holdings AS b ON b.company_id = a.company_id AND a.fund < b.fund
),
recent AS (
    SELECT r.*
    FROM analytics.fct_last_round AS r JOIN watch AS w ON w.company_id = r.company_id
    WHERE r.round_month >= DATE '2025-01-01'
),
scores AS (SELECT * FROM analytics.fct_weekly_score),
original AS (SELECT * FROM analytics.fct_weekly_score_original_rule),
rank_shift AS (
    -- Top Movers rank today and as first published, with the tie-breaks of exercise 4.07.
    SELECT
        ROW_NUMBER() OVER (ORDER BY m.momentum_now DESC, m.week_now DESC, d.company)       AS rank_now,
        ROW_NUMBER() OVER (ORDER BY m.momentum_pub DESC, m.week_pub DESC, d.company)       AS rank_published
    FROM (
        SELECT
            company_id,
            sum(momentum_weight * week_score_now)              AS momentum_now,
            sum(momentum_weight * week_score)                  AS momentum_pub,
            max(week_score_now) FILTER (WHERE weeks_back = 1)  AS week_now,
            max(week_score) FILTER (WHERE weeks_back = 1)      AS week_pub
        FROM original
        GROUP BY company_id
    ) AS m
    JOIN analytics.dim_company AS d ON d.company_id = m.company_id
    WHERE m.momentum_now > 0 OR m.momentum_pub > 0
),
window_cos AS (
    SELECT r.company_id
    FROM analytics.fct_last_round AS r JOIN watch AS w ON w.company_id = r.company_id
    WHERE r.date_status <> 'missing' AND r.amount_status <> 'exit'
      AND date_diff('month', r.round_month, (SELECT max(l.run_date) FROM scores AS l)) BETWEEN 15 AND 24
),
grant_cos AS (
    SELECT g.company_id, d.company, count(*) AS projects,
           ROW_NUMBER() OVER (ORDER BY count(*) DESC, sum(g.eu_contribution) DESC, d.company) AS rk,
           any_value(d.greek_fund_status) = 'current' AS backed
    FROM analytics.fct_signal AS g JOIN watch AS d ON d.company_id = g.company_id
    WHERE g.signal = 'grant' AND g.snapshot_date = (SELECT max(l.snapshot_date) FROM analytics.fct_signal AS l)
    GROUP BY g.company_id, d.company
),
weekly AS (
    SELECT run_date, weeks_back, sum(hiring) AS hiring, sum(github) AS github
    FROM scores GROUP BY run_date, weeks_back
),
latest_jobs AS (
    SELECT j.* FROM analytics.fct_signal AS j
    WHERE j.signal = 'job' AND j.snapshot_date = (SELECT max(l.snapshot_date) FROM analytics.fct_signal AS l)
)
SELECT metric, value FROM (VALUES
    ('companies',              (SELECT count(*) FROM analytics.dim_company)::VARCHAR),
    ('watchlist',              (SELECT count(*) FROM watch)::VARCHAR),
    ('runs',                   (SELECT count(DISTINCT run_date) FROM scores)::VARCHAR),
    ('top4_sector_companies',  (SELECT sum(n) FROM sectors WHERE rk <= 4)::VARCHAR),
    ('backed_companies',       (SELECT count(*) FROM watch WHERE greek_fund_status = 'current')::VARCHAR),
    ('fund_pairs',             (SELECT count(DISTINCT (fund_a, fund_b)) FROM pairs)::VARCHAR),
    ('fund_pair_holdings',     (SELECT count(*) FROM pairs)::VARCHAR),
    ('target_shared_companies',(SELECT count(DISTINCT company_id) FROM pairs WHERE both_target)::VARCHAR),
    ('target_shared_names',    (SELECT string_agg(DISTINCT d.company, ', ') FROM pairs AS p
                                JOIN watch AS d ON d.company_id = p.company_id WHERE p.both_target)),
    ('recent_usable_rounds',   (SELECT count(*) FROM recent WHERE is_usable)::VARCHAR),
    ('recent_excluded_rounds', (SELECT count(*) FROM recent WHERE NOT is_usable)::VARCHAR),
    ('recent_debt_rounds',     (SELECT string_agg(printf('%s %gM for %s', r.currency, r.amount_m, d.company), ', ')
                                FROM recent AS r JOIN watch AS d ON d.company_id = r.company_id
                                WHERE r.is_usable AND r.is_debt)),
    ('grant_top5',             (SELECT string_agg(company || ' ' || projects, ', ' ORDER BY rk) FROM grant_cos WHERE rk <= 5)),
    ('grant_top5_backed',      (SELECT count(*) FILTER (WHERE backed) FROM grant_cos WHERE rk <= 5)::VARCHAR),
    ('hiring_first_run',       (SELECT hiring FROM weekly ORDER BY run_date LIMIT 1)::VARCHAR),
    ('hiring_latest_run',      (SELECT hiring FROM weekly WHERE weeks_back = 1)::VARCHAR),
    ('github_min',             (SELECT min(github) FROM weekly)::VARCHAR),
    ('github_max',             (SELECT max(github) FROM weekly)::VARCHAR),
    ('total_points',           (SELECT sum(week_score) FROM scores)::VARCHAR),
    ('funding_points',         (SELECT sum(funding) FROM scores)::VARCHAR),
    ('tagged_headlines',       (SELECT count(*) FROM analytics.fct_signal
                                WHERE signal = 'news' AND news_kind = 'funding'
                                  AND event_date > snapshot_date - INTERVAL 7 DAY)::VARCHAR),
    ('published_total_points', (SELECT sum(week_score) FROM original)::VARCHAR),
    ('published_funding_points',(SELECT sum(funding) FROM original)::VARCHAR),
    ('max_rank_shift',         (SELECT max(abs(rank_now - rank_published)) FROM rank_shift)::VARCHAR),
    ('published_funding_pct',  (SELECT round(100.0 * sum(funding) / sum(week_score), 1) FROM original)::VARCHAR),
    ('window_companies',       (SELECT count(*) FROM window_cos)::VARCHAR),
    ('window_no_greek_fund',   (SELECT count(*) FROM window_cos AS c JOIN watch AS w USING (company_id)
                                WHERE w.greek_fund_status <> 'current')::VARCHAR),
    ('window_no_greek_names',  (SELECT string_agg(w.company, ', ' ORDER BY w.company) FROM window_cos AS c
                                JOIN watch AS w USING (company_id) WHERE w.greek_fund_status <> 'current')),
    ('window_top_scorer',      (SELECT arg_max(w.company, m.score_4_runs) FROM window_cos AS c
                                JOIN watch AS w USING (company_id)
                                JOIN analytics.company_momentum AS m USING (company_id))),
    ('window_unverified_names',(SELECT string_agg(w.company, ', ' ORDER BY w.company) FROM window_cos AS c
                                JOIN watch AS w USING (company_id)
                                WHERE w.greek_fund_status <> 'current' AND w.has_unverified_fact)),
    ('latest_job_postings',    (SELECT count(*) FROM latest_jobs)::VARCHAR),
    ('latest_job_rows',        (SELECT sum(listings) FROM latest_jobs)::VARCHAR),
    ('htb_new_postings_latest',(SELECT count(*) FROM analytics.fct_signal AS s
                                WHERE s.signal = 'job' AND s.company_id = 'GRDT-031'
                                  AND s.snapshot_date = (SELECT max(l.snapshot_date) FROM analytics.fct_signal AS l)
                                  AND s.item_id NOT IN (SELECT e.item_id FROM analytics.fct_signal AS e
                                                        WHERE e.signal = 'job' AND e.company_id = 'GRDT-031'
                                                          AND e.snapshot_date < s.snapshot_date))::VARCHAR),
    ('htb_hiring_points_latest',(SELECT hiring FROM scores WHERE company_id = 'GRDT-031' AND weeks_back = 1)::VARCHAR),
    ('htb_hiring_points_published',(SELECT hiring FROM original
                                WHERE company_id = 'GRDT-031' AND weeks_back = 1)::VARCHAR)
) AS t (metric, value);
