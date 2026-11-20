-- Which companies pull in the most EU research money, and are they VC-backed?
-- CORDIS projects matched to each company in the latest weekly snapshot.
-- eu_contribution is the EU contribution to the WHOLE project (all partners), not the company's share.
WITH latest AS (
    SELECT *
    FROM signals
    WHERE signal = 'grant'
      AND snapshot_date = (SELECT max(snapshot_date) FROM signals)
)
SELECT w.company,
       w.category                                              AS sector,
       count(*)                                                AS projects,
       count(*) FILTER (WHERE g.grant_status = 'SIGNED')       AS running,
       round(sum(g.eu_contribution) / 1e6, 1)                  AS project_eu_eur_m,
       year(max(g.event_date))                                 AS latest_signed,
       CASE WHEN w.greek_fund_status = 'current' THEN w.greek_funds ELSE '-' END AS greek_funds_now
FROM latest AS g
JOIN watchlist AS w USING (company_id)
GROUP BY w.company, w.category, w.greek_funds, w.greek_fund_status
ORDER BY projects DESC, project_eu_eur_m DESC, w.company
LIMIT 12;
