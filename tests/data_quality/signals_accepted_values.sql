-- Categorical columns in signals only hold known values, and type-specific columns are filled
-- for their own signal type.
SELECT snapshot_date, company_id, signal, item_id
FROM signals
WHERE signal NOT IN ('github_repo', 'news', 'job', 'grant')
   OR (signal = 'news'  AND (news_kind NOT IN ('funding', 'press') OR lang NOT IN ('en', 'el')))
   OR (signal = 'grant' AND (grant_status NOT IN ('SIGNED', 'CLOSED', 'TERMINATED')
                             OR eu_contribution IS NULL OR eu_contribution <= 0))
   OR (signal <> 'news'  AND news_kind IS NOT NULL)
   OR (signal <> 'grant' AND eu_contribution IS NOT NULL)
   OR title IS NULL OR url IS NULL OR item_id IS NULL;
