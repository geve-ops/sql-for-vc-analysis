-- Who should a Greek fund call this month?
-- Companies whose last dated round was 15 to 24 months before the latest run (the usual gap
-- to the next round), with who already backs them and what the tracker saw in the last 4 weeks.
WITH latest_run AS (SELECT max(date) AS d FROM scores),
window_cos AS (
    SELECT w.company_id, w.company, w.category, w.stage, w.last_round_amount,
           coalesce(w.greek_funds, '-') AS greek_funds,
           date_diff('month', strptime(left(w.last_round_date, 7), '%Y-%m')::DATE, (SELECT d FROM latest_run))
             AS months_since_round
    FROM watchlist AS w
    WHERE regexp_matches(w.last_round_date, '^\d{4}-\d{2}')
      AND w.stage NOT ILIKE '%exited%'
),
activity AS (
    SELECT company_id,
           sum(week_score)       AS score_4w,
           sum(hiring)           AS hiring_pts,
           sum(github)           AS github_pts,
           sum(press + funding)  AS news_pts
    FROM scores
    WHERE date > (SELECT d FROM latest_run) - INTERVAL 28 DAY
    GROUP BY company_id
),
open_roles AS (
    SELECT company_id, count(DISTINCT item_id) AS open_roles
    FROM signals
    WHERE signal = 'job' AND snapshot_date = (SELECT max(snapshot_date) FROM signals)
    GROUP BY company_id
)
SELECT c.company,
       c.category                          AS sector,
       c.months_since_round,
       c.last_round_amount                 AS last_round,
       c.greek_funds,
       coalesce(r.open_roles, 0)           AS open_roles,
       a.score_4w,
       split_part(m.source_link, ' | ', 1) AS round_source
FROM window_cos AS c
JOIN activity   AS a USING (company_id)
JOIN companies  AS m USING (company_id)
LEFT JOIN open_roles AS r USING (company_id)
WHERE c.months_since_round BETWEEN 15 AND 24
ORDER BY a.score_4w DESC, open_roles DESC, c.company;
