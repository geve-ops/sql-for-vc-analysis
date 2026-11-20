-- Where is the investable universe, and how much of it can a fund actually see?
-- One row per sector of the watchlist (market map Include + Borderline companies).
WITH clean_rounds AS (
    -- a round size counts only when the text starts with a currency and an amount:
    -- no "~" approximations, no UNVERIFIED figures, no "More than", no acquisitions, no grants
    SELECT company_id
    FROM watchlist
    WHERE regexp_matches(last_round_amount, '^(USD|EUR|GBP) [0-9.]+[MK]')
      AND last_round_amount NOT ILIKE '%grant%'
),
scored AS (
    SELECT company_id
    FROM scores
    GROUP BY company_id
    HAVING sum(week_score) > 0
)
SELECT w.category                                                  AS sector,
       count(*)                                                    AS companies,
       count(*) FILTER (WHERE w.map_status = 'Include')            AS include,
       count(*) FILTER (WHERE w.greek_fund_status = 'current')     AS greek_fund_backed,
       count(r.company_id)                                         AS confirmed_round_size,
       count(s.company_id)                                         AS scored_in_4_weeks,
       round(100.0 * count(*) / sum(count(*)) OVER (), 1)          AS pct_of_watchlist
FROM watchlist AS w
LEFT JOIN clean_rounds AS r ON r.company_id = w.company_id
LEFT JOIN scored       AS s ON s.company_id = w.company_id
GROUP BY w.category
ORDER BY companies DESC, sector;
