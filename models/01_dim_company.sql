-- dim_company: one row per market-map company (88), cleaned and typed.
-- Grain: company_id. Sources: companies, watchlist.
CREATE OR REPLACE TABLE analytics.dim_company AS
SELECT
    c.company_id,
    c.company,
    c.category                                                        AS sector,
    c.sub_sector,
    c.map_status,
    w.company_id IS NOT NULL                                          AS on_watchlist,
    TRY_CAST(regexp_extract(c.founded, '(\d{4})', 1) AS INTEGER)      AS founded_year,
    c.hq_greek_link,
    c.website,
    nullif(split_part(c.source_link, ' | ', 1), '')                   AS primary_source,
    c.verification_status,
    c.verification_status ILIKE '%unverified%'                        AS has_unverified_fact,
    c.github_org,
    w.jobs_source,
    coalesce(w.greek_fund_status, 'none')                             AS greek_fund_status,
    c.last_verified
FROM companies AS c
LEFT JOIN watchlist AS w ON w.company_id = c.company_id;
