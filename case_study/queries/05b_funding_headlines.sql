-- Q5b. The headlines behind every funding point in the four runs.
-- A funding point needs a new headline tagged "funding", published inside that week's window.
SELECT
    s.snapshot_date     AS run,
    d.company,
    s.event_date        AS published,
    s.source,
    s.title
FROM analytics.fct_signal AS s
JOIN analytics.fct_weekly_score AS w
    ON w.company_id = s.company_id AND w.run_date = s.snapshot_date
JOIN analytics.dim_company AS d ON d.company_id = s.company_id
WHERE s.signal = 'news'
  AND s.news_kind = 'funding'
  AND w.funding > 0
  AND s.event_date > s.snapshot_date - INTERVAL 7 DAY
ORDER BY run, d.company, s.source;
