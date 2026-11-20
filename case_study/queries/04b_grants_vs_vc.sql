-- Q4b. EU project participation against Greek VC backing, across the whole watchlist.
WITH grant_companies AS (
    SELECT DISTINCT company_id
    FROM analytics.fct_signal
    WHERE signal = 'grant'
      AND snapshot_date = (SELECT max(l.snapshot_date) FROM analytics.fct_signal AS l)
)
SELECT
    CASE WHEN g.company_id IS NOT NULL THEN 'has CORDIS projects' ELSE 'no CORDIS projects' END AS eu_grants,
    count(*)                                                            AS companies,
    count(*) FILTER (WHERE d.greek_fund_status = 'current')             AS greek_fund_backed,
    round(100.0 * count(*) FILTER (WHERE d.greek_fund_status = 'current') / count(*), 1) AS pct_backed
FROM analytics.dim_company AS d
LEFT JOIN grant_companies AS g ON g.company_id = d.company_id
WHERE d.on_watchlist
GROUP BY eu_grants
ORDER BY eu_grants;
