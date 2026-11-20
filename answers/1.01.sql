-- check: ordered
SELECT company, sub_sector, stage
FROM companies
WHERE category = 'Robotics & Drones'
ORDER BY company;
