-- Q5a. What drives the weekly scores? Points by signal for each weekly run, all watchlist companies.
SELECT
    run_date                                                AS run,
    sum(funding)                                            AS funding,
    sum(grants)                                             AS grants,
    sum(press)                                              AS press,
    sum(hiring)                                             AS hiring,
    sum(github)                                             AS github,
    sum(week_score)                                         AS total,
    count(*) FILTER (WHERE week_score > 0)                  AS companies_scoring,
    sum(week_score) - LAG(sum(week_score)) OVER (ORDER BY run_date) AS change
FROM analytics.fct_weekly_score
GROUP BY run_date
ORDER BY run;
