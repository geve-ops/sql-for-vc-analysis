-- A usable round has a currency, a positive amount and a month no later than the latest run;
-- an amount is only filled for confirmed amounts, so nothing approximate leaks into the analysis.
SELECT company_id, amount_status, date_status, currency, amount_m, round_month
FROM analytics.fct_last_round
WHERE (is_usable AND (currency IS NULL OR amount_m IS NULL OR amount_m <= 0 OR round_month IS NULL
                      OR round_month > (SELECT max(s.date) FROM scores AS s)))
   OR (amount_status <> 'confirmed' AND amount_m IS NOT NULL)
   OR amount_status NOT IN ('confirmed', 'approximate', 'lower_bound', 'unverified', 'grant', 'exit',
                            'not_disclosed')
   OR date_status NOT IN ('confirmed', 'unverified', 'missing')
   OR (SELECT count(*) FROM analytics.fct_last_round AS a) <> (SELECT count(*) FROM companies AS c);
