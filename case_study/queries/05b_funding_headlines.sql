-- The headlines behind every funding point in the four runs.
-- A funding point needs a new headline tagged "funding" that was published inside that week's window.
SELECT s.snapshot_date      AS run,
       w.company,
       s.event_date         AS published,
       s.source,
       s.title
FROM signals AS s
JOIN watchlist AS w USING (company_id)
JOIN scores    AS sc ON sc.company_id = s.company_id AND sc.date = s.snapshot_date
WHERE s.signal = 'news'
  AND s.news_kind = 'funding'
  AND sc.funding > 0
  AND s.event_date > s.snapshot_date - INTERVAL 7 DAY
ORDER BY run, w.company, s.source;
