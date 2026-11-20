-- Q5c. How much of the Top Movers ranking rests on funding points?
-- The tracker's momentum (exercise 4.07) next to the same score without funding points.
SELECT
    momentum_rank           AS rank,
    company,
    momentum,
    momentum_ex_funding     AS without_funding,
    rank_ex_funding         AS rank_without_funding
FROM analytics.company_momentum
WHERE momentum_rank <= 10
ORDER BY rank;
