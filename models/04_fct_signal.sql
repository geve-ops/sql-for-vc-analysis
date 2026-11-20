-- fct_signal: one row per item per weekly snapshot.
-- Grain: snapshot_date, company_id, signal, item_id. Source: signals.
--
-- signals repeats a job once per city (same item_id, same title and URL). This model keeps one row
-- per posting and lists the cities. Every other signal is already one row per item.
CREATE OR REPLACE TABLE analytics.fct_signal AS
SELECT
    snapshot_date,
    company_id,
    signal,
    item_id,
    any_value(title)                                          AS title,
    any_value(url)                                            AS url,
    any_value(event_date)                                     AS event_date,
    any_value(source)                                         AS source,
    any_value(news_kind)                                      AS news_kind,
    any_value(lang)                                           AS lang,
    string_agg(DISTINCT location, '; ' ORDER BY location)     AS locations,
    count(*)                                                  AS listings,
    any_value(stars)                                          AS stars,
    any_value(window_commits)                                 AS window_commits,
    any_value(window_commits_bot)                             AS window_commits_bot,
    any_value(is_fork)                                        AS is_fork,
    any_value(grant_acronym)                                  AS grant_acronym,
    any_value(eu_contribution)                                AS eu_contribution,
    any_value(grant_status)                                   AS grant_status
FROM signals
GROUP BY snapshot_date, company_id, signal, item_id;
