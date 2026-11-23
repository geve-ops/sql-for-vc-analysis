-- Q5b. Funding-tag audit: every headline the collector tagged "funding" inside a weekly window,
-- next to the funding points that company earns in that run under the corrected scoring.
-- news_kind is the tag given when the headline was collected (the original keyword rule).
SELECT
    s.snapshot_date     AS run,
    d.company,
    s.event_date        AS published,
    s.source,
    s.title,
    w.funding           AS funding_points_now
FROM analytics.fct_signal AS s
JOIN analytics.fct_weekly_score AS w
    ON w.company_id = s.company_id AND w.run_date = s.snapshot_date
JOIN analytics.dim_company AS d ON d.company_id = s.company_id
WHERE s.signal = 'news'
  AND s.news_kind = 'funding'
  AND s.event_date > s.snapshot_date - INTERVAL 7 DAY
ORDER BY run, d.company, s.source;
