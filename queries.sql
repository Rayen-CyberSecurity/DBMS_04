-- Task 5a – All Work Items for a Given Customer
-- Relational algebra in words:
-- First select the customer whose name is 'Berger, Franz'.
-- Then join this customer with orders, vehicles, and work items.
-- Finally project order number, date, plate, description, and hours.

-- Formal notation:
-- π order_no, date, plate, description, hours
-- (
--   σ cust_name = 'Berger, Franz'
--   (customer ⋈ order ⋈ vehicle ⋈ work_item)
-- )

-- Query 5a:
SELECT
    o.order_no,
    o.date,
    v.plate,
    wi.description,
    wi.hours
FROM customer c
JOIN "order" o ON c.cust_no = o.cust_no
JOIN vehicle v ON o.plate = v.plate
JOIN work_item wi ON o.order_no = wi.order_no
WHERE c.cust_name = 'Berger, Franz'
ORDER BY o.date, wi.item_no;


-- Task 5b – Total Hours per Mechanic in March 2026
-- Purpose:
-- For each mechanic, calculate the total number of hours worked in March 2026
-- and count the number of distinct orders they worked on.

-- Query 5b:
SELECT
    m.mech_name,
    ROUND(SUM(wi.hours), 1) AS total_hours,
    COUNT(DISTINCT wi.order_no) AS orders
FROM mechanic m
JOIN work_item wi ON m.mech_id = wi.mech_id
JOIN "order" o ON wi.order_no = o.order_no
WHERE o.date >= '2026-03-01'
  AND o.date < '2026-04-01'
GROUP BY m.mech_id, m.mech_name
ORDER BY total_hours DESC;


-- Task 5c – Vehicles with No Repair Order
-- Purpose:
-- Return all vehicles that exist in the vehicle table but do not appear
-- in the order table.

-- Variant 1: EXCEPT
-- Query 5c-1:
SELECT
    plate,
    model
FROM vehicle

EXCEPT

SELECT
    v.plate,
    v.model
FROM vehicle v
JOIN "order" o ON v.plate = o.plate;


-- Variant 2: NOT EXISTS
-- Query 5c-2:
SELECT
    v.plate,
    v.model
FROM vehicle v
WHERE NOT EXISTS (
    SELECT 1
    FROM "order" o
    WHERE o.plate = v.plate
);
