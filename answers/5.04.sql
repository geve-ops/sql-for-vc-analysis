-- check: ordered
-- Approach: Group by the project; count distinct companies; string_agg with ORDER BY for a stable list.
-- Watch out: Summing eu_contribution across companies counts these projects twice.
SELECT s.item_id                                       AS project_id,
       any_value(s.grant_acronym)                      AS acronym,
       count(DISTINCT s.company_id)                    AS companies,
       string_agg(w.company, ', ' ORDER BY w.company)  AS partners
FROM signals AS s
JOIN watchlist AS w ON w.company_id = s.company_id
WHERE s.signal = 'grant'
  AND s.snapshot_date = DATE '2026-11-16'
GROUP BY s.item_id
HAVING count(DISTINCT s.company_id) > 1
ORDER BY project_id;
