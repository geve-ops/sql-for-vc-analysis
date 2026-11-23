-- fct_weekly_score_original_rule reproduces every score as the tracker first published it.
SELECT
    p.date,
    p.company_id,
    p.week_score    AS published,
    o.week_score    AS rebuilt
FROM analytics.ref_scores_first_published AS p
FULL OUTER JOIN analytics.fct_weekly_score_original_rule AS o
    ON o.run_date = p.date::DATE AND o.company_id = p.company_id
WHERE o.week_score IS DISTINCT FROM p.week_score::INTEGER
   OR o.funding IS DISTINCT FROM p.funding::INTEGER
   OR o.press IS DISTINCT FROM p.press::INTEGER
   OR o.hiring IS DISTINCT FROM p.hiring::INTEGER;
