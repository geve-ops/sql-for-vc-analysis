-- Q4a. Which companies take part in the most EU research projects, and does a Greek fund hold them?
-- CORDIS projects matched to each company in the latest weekly snapshot.
-- project_eu_eur_m is the EU contribution to the WHOLE project (all partners), not the company's share.
WITH grants AS (
    SELECT company_id, item_id, grant_status, eu_contribution, event_date
    FROM analytics.fct_signal
    WHERE signal = 'grant'
      AND snapshot_date = (SELECT max(l.snapshot_date) FROM analytics.fct_signal AS l)
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
    count(*)                                            AS projects,
    count(*) FILTER (WHERE g.grant_status = 'SIGNED')   AS running,
    round(sum(g.eu_contribution) / 1e6, 1)              AS project_eu_eur_m,
    year(max(g.event_date))                             AS latest_signed,
    coalesce(f.funds, '-')                              AS greek_funds_now
FROM grants AS g
JOIN analytics.dim_company AS d ON d.company_id = g.company_id
LEFT JOIN current_funds AS f ON f.company_id = g.company_id
GROUP BY d.company, d.sector, f.funds
ORDER BY projects DESC, project_eu_eur_m DESC, d.company
LIMIT 12;
