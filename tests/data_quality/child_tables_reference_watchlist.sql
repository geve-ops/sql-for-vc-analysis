-- scores, signals, pipeline and backtest only refer to watchlist companies.
SELECT 'scores' AS source_table, s.company_id FROM scores AS s
WHERE NOT EXISTS (SELECT 1 FROM watchlist AS w WHERE w.company_id = s.company_id)
UNION ALL
SELECT 'signals', s.company_id FROM signals AS s
WHERE NOT EXISTS (SELECT 1 FROM watchlist AS w WHERE w.company_id = s.company_id)
UNION ALL
SELECT 'pipeline', p.company_id FROM pipeline AS p
WHERE NOT EXISTS (SELECT 1 FROM watchlist AS w WHERE w.company_id = p.company_id)
UNION ALL
SELECT 'backtest', b.company_id FROM backtest AS b
WHERE NOT EXISTS (SELECT 1 FROM watchlist AS w WHERE w.company_id = b.company_id);
