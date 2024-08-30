CREATE VIEW OrdersByCustomer AS
SELECT 
    c.id AS customer_id,
    CONCAT(CONVERT(NVARCHAR(MAX), c.last_name), ', ', CONVERT(NVARCHAR(MAX), c.first_name)) AS customer_name,
    COUNT(o.id) AS total_orders,
    SUM(ol.price * ol.quantity) AS total_spent,
    AVG(ol.price * ol.quantity) AS avg_order_value
FROM 
    customers c
JOIN 
    orders o ON c.id = o.customer_id
JOIN 
    order_lines ol ON o.id = ol.order_id
GROUP BY 
    c.id, 
    CONCAT(CONVERT(NVARCHAR(MAX), c.last_name), ', ', CONVERT(NVARCHAR(MAX), c.first_name));

