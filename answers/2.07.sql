-- check: ordered
SELECT w.category,
       count(*)                              AS grants,
       round(sum(s.eu_contribution) / 1e6, 2) AS eu_eur_m
FROM signals AS s
JOIN watchlist AS w ON w.company_id = s.company_id
WHERE s.signal = 'grant'
  AND s.snapshot_date = DATE '2026-11-16'
GROUP BY w.category
ORDER BY eu_eur_m DESC, w.category;
