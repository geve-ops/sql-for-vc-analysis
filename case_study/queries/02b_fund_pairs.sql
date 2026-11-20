-- Q2b. Every pair of Greek funds that currently hold the same watchlist company.
SELECT
    a.fund                                              AS fund_a,
    b.fund                                              AS fund_b,
    count(*)                                            AS shared,
    string_agg(d.company, ', ' ORDER BY d.company)      AS companies
FROM analytics.bridge_company_fund AS a
JOIN analytics.bridge_company_fund AS b
    ON b.company_id = a.company_id AND a.fund < b.fund AND b.is_current
JOIN analytics.dim_company AS d ON d.company_id = a.company_id
WHERE a.is_current
GROUP BY a.fund, b.fund
ORDER BY shared DESC, fund_a, fund_b;
