-- What is driving the weekly scores? Points by signal for each weekly run, all 69 companies.
SELECT date                                        AS run,
       sum(funding)                                AS funding,
       sum(grants)                                 AS grants,
       sum(press)                                  AS press,
       sum(hiring)                                 AS hiring,
       sum(github)                                 AS github,
       sum(week_score)                             AS total,
       count(*) FILTER (WHERE week_score > 0)      AS companies_scoring,
       sum(week_score) - LAG(sum(week_score)) OVER (ORDER BY date) AS change
FROM scores
GROUP BY date
ORDER BY run;
