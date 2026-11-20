-- company_momentum covers every watchlist company and its weekly figures match scores.
SELECT m.company_id, m.this_week, s.week_score
FROM analytics.company_momentum AS m
LEFT JOIN scores AS s
       ON s.company_id = m.company_id AND s.date = (SELECT max(date) FROM scores)
WHERE s.week_score IS DISTINCT FROM m.this_week
UNION ALL
SELECT NULL, NULL, NULL
WHERE (SELECT count(*) FROM analytics.company_momentum) <> (SELECT count(*) FROM watchlist);
