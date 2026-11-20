-- company_id follows the market map's format, GRDT- and three digits.
SELECT company_id, company
FROM companies
WHERE NOT regexp_matches(company_id, '^GRDT-\d{3}$');
