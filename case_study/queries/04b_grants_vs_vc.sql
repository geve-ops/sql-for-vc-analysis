-- Grant activity against Greek VC backing, across the whole watchlist.
WITH grant_cos AS (
    SELECT DISTINCT company_id
    FROM signals
    WHERE signal = 'grant'
      AND snapshot_date = (SELECT max(snapshot_date) FROM signals)
)
SELECT CASE WHEN g.company_id IS NOT NULL THEN 'has CORDIS projects' ELSE 'no CORDIS projects' END AS eu_grants,
       count(*)                                                         AS companies,
       count(*) FILTER (WHERE w.greek_fund_status = 'current')          AS greek_fund_backed,
       round(100.0 * count(*) FILTER (WHERE w.greek_fund_status = 'current') / count(*), 1) AS pct_backed
FROM watchlist AS w
LEFT JOIN grant_cos AS g USING (company_id)
GROUP BY eu_grants
ORDER BY eu_grants;
