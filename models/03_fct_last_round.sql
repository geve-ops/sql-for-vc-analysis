-- fct_last_round: each company's last round, parsed from free text.
-- Grain: company_id (88 rows). Source: companies.last_round_amount and last_round_date.
--
-- A round is usable for analysis only when both its amount and its date are confirmed:
--   amount_status = 'confirmed'  the text starts with a currency and an exact amount (USD 11.7M, EUR 500K)
--   date_status   = 'confirmed'  the text starts with YYYY-MM and is not marked UNVERIFIED
-- Nothing is estimated or converted: amount_m is in millions of the stated currency.
CREATE OR REPLACE TABLE analytics.fct_last_round AS
WITH parsed AS (
    SELECT
        c.company_id,
        c.last_round_amount                                                           AS amount_text,
        c.last_round_date                                                             AS date_text,
        regexp_extract(c.last_round_amount, '^(USD|EUR|GBP) ([0-9.]+)([MK])', 1)      AS currency_raw,
        TRY_CAST(regexp_extract(c.last_round_amount, '^(USD|EUR|GBP) ([0-9.]+)([MK])', 2) AS DOUBLE)
            AS amount_raw,
        regexp_extract(c.last_round_amount, '^(USD|EUR|GBP) ([0-9.]+)([MK])', 3)      AS unit_raw,
        CASE
            WHEN c.last_round_amount ILIKE 'acquisition%'
                OR c.stage ILIKE 'exited%'                                  THEN 'exit'
            WHEN c.last_round_amount ILIKE '%grant%'                        THEN 'grant'
            WHEN c.last_round_amount ILIKE 'unverified%'                    THEN 'unverified'
            WHEN c.last_round_amount LIKE '~%'                              THEN 'approximate'
            WHEN c.last_round_amount ILIKE 'more than%'                     THEN 'lower_bound'
            WHEN regexp_matches(c.last_round_amount, '^(USD|EUR|GBP) [0-9.]+[MK]') THEN 'confirmed'
            ELSE 'not_disclosed'
        END                                                                           AS amount_status,
        CASE
            WHEN NOT regexp_matches(c.last_round_date, '^\d{4}-\d{2}')     THEN 'missing'
            WHEN c.last_round_date ILIKE '%unverified%'                     THEN 'unverified'
            ELSE 'confirmed'
        END                                                                           AS date_status,
        nullif(split_part(c.source_link, ' | ', 1), '')                               AS source_url
    FROM companies AS c
)
SELECT
    company_id,
    amount_text,
    date_text,
    amount_status,
    date_status,
    CASE WHEN amount_status = 'confirmed' THEN currency_raw END                      AS currency,
    CASE
        WHEN amount_status <> 'confirmed' THEN NULL
        WHEN unit_raw = 'K' THEN amount_raw / 1000
        ELSE amount_raw
    END                                                                               AS amount_m,
    CASE
        WHEN date_status <> 'missing' THEN strptime(left(date_text, 7), '%Y-%m')::DATE
    END                                                                               AS round_month,
    amount_text ILIKE '%debt%'                                                        AS is_debt,
    amount_status = 'confirmed' AND date_status = 'confirmed'                         AS is_usable,
    source_url
FROM parsed;
