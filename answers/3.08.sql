-- check: ordered
WITH parsed AS (
    SELECT company,
           regexp_extract(last_round_amount, '^(USD|EUR) ([0-9.]+)([MK])', 1)                  AS currency,
           TRY_CAST(regexp_extract(last_round_amount, '^(USD|EUR) ([0-9.]+)([MK])', 2) AS DOUBLE) AS amount,
           regexp_extract(last_round_amount, '^(USD|EUR) ([0-9.]+)([MK])', 3)                  AS unit
    FROM watchlist
    WHERE last_round_amount NOT ILIKE '%grant%'
),
in_millions AS (
    SELECT company, currency,
           CASE WHEN unit = 'K' THEN amount / 1000 ELSE amount END AS amount_m
    FROM parsed
    WHERE currency IN ('USD', 'EUR')
)
SELECT currency,
       CASE
         WHEN amount_m < 1  THEN '1: under 1M'
         WHEN amount_m < 5  THEN '2: 1-5M'
         WHEN amount_m < 20 THEN '3: 5-20M'
         ELSE                    '4: 20M+'
       END AS size_bucket,
       count(*) AS rounds
FROM in_millions
GROUP BY currency, size_bucket
ORDER BY currency, size_bucket;
