-- check: ordered
WITH years AS (
    SELECT category,
           TRY_CAST(regexp_extract(founded, '(\d{4})', 1) AS INTEGER) AS founded_year
    FROM companies
)
SELECT category,
       count(founded_year)                        AS with_year,
       count(*) - count(founded_year)             AS unknown,
       round(avg(2026 - founded_year), 1)         AS avg_age_years
FROM years
GROUP BY category
ORDER BY category;
