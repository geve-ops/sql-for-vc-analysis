-- check: ordered
-- Approach: Filter one category, then sort.
-- Watch out: Text comparison is exact: 'Robotics & Drones' with the ampersand, in single quotes.
SELECT company, sub_sector, stage
FROM companies
WHERE category = 'Robotics & Drones'
ORDER BY company;
