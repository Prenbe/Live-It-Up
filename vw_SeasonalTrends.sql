CREATE VIEW SeasonalTrends AS
SELECT 
    o.id AS order_id,
    MONTH(o.created_at) AS month,
    SUM(o.total_price) AS total_sales,
    AVG(o.total_price) AS avg_order_value,
    COUNT(DISTINCT o.id) AS total_orders
FROM 
    orders o
GROUP BY 
    o.id, MONTH(o.created_at)