-- The source tables keep the column names and types the exercises and models rely on.
-- A refresh that changes a type (for example a date column read as text) fails here first.
WITH expected (table_name, column_name, data_type) AS (
    VALUES
    ('companies', 'company_id', 'VARCHAR'), ('companies', 'category', 'VARCHAR'),
    ('companies', 'map_status', 'VARCHAR'), ('companies', 'founded', 'VARCHAR'),
    ('companies', 'last_round_amount', 'VARCHAR'), ('companies', 'last_round_date', 'VARCHAR'),
    ('companies', 'source_link', 'VARCHAR'), ('companies', 'last_verified', 'DATE'),
    ('watchlist', 'company_id', 'VARCHAR'), ('watchlist', 'greek_funds', 'VARCHAR'),
    ('watchlist', 'greek_fund_status', 'VARCHAR'), ('watchlist', 'github_org', 'VARCHAR'),
    ('scores', 'date', 'DATE'), ('scores', 'company_id', 'VARCHAR'), ('scores', 'week_score', 'BIGINT'),
    ('scores', 'funding', 'BIGINT'), ('scores', 'grants', 'BIGINT'), ('scores', 'press', 'BIGINT'),
    ('scores', 'hiring', 'BIGINT'), ('scores', 'github', 'BIGINT'),
    ('pipeline', 'company_id', 'VARCHAR'), ('pipeline', 'updated', 'DATE'),
    ('backtest', 'company_id', 'VARCHAR'), ('backtest', 'round_month', 'VARCHAR'),
    ('backtest', 'commits_baseline', 'BIGINT'), ('backtest', 'commits_before', 'BIGINT'),
    ('signals', 'snapshot_date', 'DATE'), ('signals', 'event_date', 'DATE'),
    ('signals', 'eu_contribution', 'DOUBLE')
)
SELECT e.table_name, e.column_name, e.data_type AS expected_type, c.data_type AS actual_type
FROM expected AS e
LEFT JOIN information_schema.columns AS c
       ON c.table_schema = 'main' AND c.table_name = e.table_name AND c.column_name = e.column_name
WHERE c.data_type IS DISTINCT FROM e.data_type;
