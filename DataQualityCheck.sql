-- 1. Check for Missing Email Addresses
SELECT *
FROM customers
WHERE CAST(Email AS varchar(MAX)) IS NULL OR CAST(Email AS varchar(MAX)) = '';

-- 2. Check for Missing Phone Numbers
SELECT *
FROM customers
WHERE CAST(Phone AS varchar(MAX)) IS NULL OR CAST(Phone AS varchar(MAX)) = '';

-- 3. Check for Missing Names
SELECT *
FROM customers
WHERE CAST(First_Name AS varchar(MAX)) IS NULL OR CAST(First_Name AS varchar(MAX)) = '' 
   OR CAST(Last_Name AS varchar(MAX)) IS NULL OR CAST(Last_Name AS varchar(MAX)) = '';

-- 4. Check for Invalid Email Format
SELECT *
FROM customers
WHERE CAST(Email AS varchar(MAX)) NOT LIKE '%@%' OR CAST(Email AS varchar(MAX)) NOT LIKE '%.%';

-- 5. Check for Duplicate Email Addresses
SELECT CAST(Email AS varchar(MAX)), COUNT(*)
FROM customers
GROUP BY CAST(Email AS varchar(MAX))
HAVING COUNT(*) > 1;

-- 6. Check for Duplicate Phone Numbers
SELECT CAST(Phone AS varchar(MAX)) AS Phone, COUNT(*)
FROM customers
GROUP BY CAST(Phone AS varchar(MAX))
HAVING COUNT(*) > 1;

-- 7. Check for Unusually High/Low Orders Count
SELECT MAX(orders_count) MostOrders, MIN(orders_count) LeastOrders, MAX(total_spent) MostSpent, MIN(total_spent) AS LeastSpent
FROM customers;

-- 8. Check for Inactive Customers (no updates in over a year)
SELECT DATEDIFF(DAY, Updated_At, GETDATE()) AS DaysSinceUpdate, *
FROM customers
ORDER BY DATEDIFF(DAY, Updated_At, GETDATE()) DESC;

-- 9. Looking into phone number formatting, perhaps this is something that could be standardized?
SELECT TOP 50 *
FROM customers
WHERE CAST(Phone AS varchar(MAX)) LIKE '%[^0-9]%';

-- 10. Standardize Phone Numbers and Separate Extensions
WITH CleanedPhones AS (
    SELECT
        Phone,
        -- Convert the Phone column to VARCHAR(MAX) before applying REPLACE
        REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CAST(Phone AS VARCHAR(MAX)), ' ', ''), '.', '-'), '(', ''), ')', ''), '+1-', ''), '001-', '') AS CleanedNumber
    FROM
        customers
),
FormattedPhones AS (
    SELECT
        Phone,
        -- Handle extensions: find 'x' and separate the extension
        CASE
            WHEN CHARINDEX('x', CleanedNumber) > 0 THEN
                SUBSTRING(CleanedNumber, 1, CHARINDEX('x', CleanedNumber) - 1)
            ELSE
                CleanedNumber
        END AS BaseNumber,
        CASE
            WHEN CHARINDEX('x', CleanedNumber) > 0 THEN
                SUBSTRING(CleanedNumber, CHARINDEX('x', CleanedNumber) + 1, LEN(CleanedNumber))
            ELSE
                NULL
        END AS Extension
    FROM
        CleanedPhones
)
SELECT
    Phone,
    -- Standardize the phone number format
    CASE
        WHEN LEN(BaseNumber) = 10 THEN
            '+1-' + SUBSTRING(BaseNumber, 1, 3) + '-' + SUBSTRING(BaseNumber, 4, 3) + '-' + SUBSTRING(BaseNumber, 7, 4)
        WHEN LEN(BaseNumber) = 11 THEN
            '+1-' + SUBSTRING(BaseNumber, 2, 3) + '-' + SUBSTRING(BaseNumber, 5, 3) + '-' + SUBSTRING(BaseNumber, 8, 4)
        WHEN LEN(BaseNumber) = 12 THEN
            '+1-' + SUBSTRING(BaseNumber, 1, 3) + '-' + SUBSTRING(BaseNumber, 5, 3) + '-' + SUBSTRING(BaseNumber, 9, 4)
        ELSE
            BaseNumber
    END AS StandardizedPhoneNumber,
    -- Add the extension as a separate column
    Extension AS PhoneExtension
FROM
    FormattedPhones;

-- 11. Check for Consistent Casing in Names (First Letter Capitalized)
SELECT *
FROM customers
WHERE CAST(First_Name AS varchar(MAX)) <> UPPER(LEFT(CAST(First_Name AS varchar(MAX)), 1)) + LOWER(SUBSTRING(CAST(First_Name AS varchar(MAX)), 2, LEN(CAST(First_Name AS varchar(MAX)))))
   OR CAST(Last_Name AS varchar(MAX)) <> UPPER(LEFT(CAST(Last_Name AS varchar(MAX)), 1)) + LOWER(SUBSTRING(CAST(Last_Name AS varchar(MAX)), 2, LEN(CAST(Last_Name AS varchar(MAX)))));

-- 12. Check Referential Integrity (Customer IDs in Orders Table)
SELECT o.Customer_Id
FROM orders o
LEFT JOIN customers c ON o.Customer_Id = c.Id
WHERE c.Id IS NULL;

-- 13. Count the Number of Records in the Customers Table
SELECT COUNT(*) AS Total_Customers FROM customers;

-- 14. Check for Customers Without Orders
SELECT *
FROM customers c
LEFT JOIN orders o ON c.Id = o.Customer_Id
WHERE o.Customer_Id IS NULL;
-- This query identifies customers who do not have any orders.

-- 15. Check for Orders Without Customers
SELECT *
FROM orders o
LEFT JOIN customers c ON o.Customer_Id = c.Id
WHERE c.Id IS NULL;
-- This query identifies orders that are not associated with any customer.

-- 16. Check for Non-Unique Customer IDs
SELECT Id, COUNT(*)
FROM customers
GROUP BY Id
HAVING COUNT(*) > 1;
-- This query identifies any duplicate customer IDs, which should be unique.

-- 17. Check for Inactive Customers with Recent Orders
SELECT *
FROM customers c
JOIN orders o ON c.Id = o.Customer_Id
WHERE DATEDIFF(DAY, c.Updated_At, GETDATE()) > 365 AND o.updated_at > DATEADD(DAY, -365, GETDATE());
-- This query identifies inactive customers who have placed recent orders, which could indicate that their information needs updating.

-- 18. Check for Orders Placed by Inactive Customers
SELECT *
FROM orders o
JOIN customers c ON o.Customer_Id = c.Id
WHERE DATEDIFF(DAY, c.Updated_At, GETDATE()) > 365;
-- This query identifies orders placed by customers who haven't updated their information in over a year.
