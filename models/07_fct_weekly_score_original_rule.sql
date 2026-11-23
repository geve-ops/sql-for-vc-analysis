-- fct_weekly_score_original_rule: each weekly score as the tracker's original rules gave it.
-- Grain: run_date, company_id. Sources: fct_weekly_score, fct_signal.
-- The tracker changed two rules on 20 November 2026 and rescored its history on 23 November:
--   funding  5 points per headline the collector tagged "funding" (news_kind), capped at 10.
--            Now a headline counts only if it names a round or an amount next to a money word.
--   hiring   1 point per job listing, so a posting listed in several cities scored once per city.
--            Now each posting counts once.
-- Parts the rule change did not touch keep today's points. Headlines that were funding then are
-- press now, so press is recounted only where tagged headlines exist.
-- The data-quality rule score_original_rule_matches_published checks every row against the
-- scores as first published (seeds/scores_first_published.csv).
CREATE OR REPLACE TABLE analytics.fct_weekly_score_original_rule AS
WITH news AS (
    SELECT
        company_id,
        snapshot_date                                  AS run_date,
        count(*) FILTER (WHERE news_kind = 'funding')  AS funding_tagged,
        count(*) FILTER (WHERE news_kind = 'press')    AS press_tagged
    FROM analytics.fct_signal
    WHERE signal = 'news' AND event_date > snapshot_date - INTERVAL 7 DAY
    GROUP BY company_id, snapshot_date
),

first_run AS (SELECT min(snapshot_date) AS d FROM analytics.fct_signal),

new_jobs AS (
    -- A posting is new when the previous run did not list it; in the first run, when it was
    -- published inside the week.
    SELECT
        j.company_id,
        j.snapshot_date                                AS run_date,
        count(*)                                       AS postings,
        sum(j.listings)::BIGINT                        AS listings
    FROM analytics.fct_signal AS j
    CROSS JOIN first_run AS f
    WHERE j.signal = 'job'
      AND CASE
          WHEN j.snapshot_date = f.d THEN j.event_date > j.snapshot_date - INTERVAL 7 DAY
          ELSE NOT EXISTS (
              SELECT 1
              FROM analytics.fct_signal AS p
              WHERE p.signal = 'job'
                AND p.company_id = j.company_id
                AND p.item_id = j.item_id
                AND p.snapshot_date = j.snapshot_date - INTERVAL 7 DAY
          )
      END
    GROUP BY j.company_id, j.snapshot_date
),

parts AS (
    SELECT
        w.run_date,
        w.company_id,
        w.weeks_back,
        w.momentum_weight,
        w.week_score                                   AS week_score_now,
        least(10, 5 * coalesce(n.funding_tagged, 0))   AS funding,
        w.grants,
        CASE WHEN n.funding_tagged > 0 THEN least(3, n.press_tagged) ELSE w.press END AS press,
        CASE WHEN j.listings > j.postings THEN least(5, j.listings) ELSE w.hiring END AS hiring,
        w.github
    FROM analytics.fct_weekly_score AS w
    LEFT JOIN news AS n ON n.company_id = w.company_id AND n.run_date = w.run_date
    LEFT JOIN new_jobs AS j ON j.company_id = w.company_id AND j.run_date = w.run_date
)

SELECT
    run_date,
    company_id,
    weeks_back,
    momentum_weight,
    week_score_now,
    (funding + grants + press + hiring + github)::BIGINT AS week_score,
    funding,
    grants,
    press,
    hiring,
    github
FROM parts;
