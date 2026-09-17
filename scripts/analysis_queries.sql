CREATE OR ALTER VIEW gold.vw_sales_performance
AS
SELECT
    f.sales_key,
    f.order_id,
    d.full_date AS order_date,
    c.customer_id,
    c.customer_name,
    c.segment,
    p.product_id,
    p.product_name,
    p.category,
    p.sub_category,
    l.city,
    l.state,
    l.region,
    sm.ship_mode,
    f.sales_amount,
    f.quantity,
    f.discount,
    f.profit
FROM gold.fact_sales f
JOIN gold.dim_date d
    ON f.order_date_key = d.date_key
JOIN gold.dim_customer c
    ON f.customer_key = c.customer_key
JOIN gold.dim_product p
    ON f.product_key = p.product_key
JOIN gold.dim_location l
    ON f.location_key = l.location_key
JOIN gold.dim_ship_mode sm
    ON f.ship_mode_key = sm.ship_mode_key;
GO


CREATE OR ALTER PROCEDURE gold.usp_sales_kpis
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        COUNT(*) AS total_orders,
        SUM(quantity) AS total_quantity,
        SUM(sales_amount) AS total_sales,
        SUM(profit) AS total_profit,
        AVG(sales_amount) AS avg_order_value,
        AVG(discount) AS avg_discount,
        CASE
            WHEN SUM(sales_amount) = 0 THEN 0
            ELSE (SUM(profit) / SUM(sales_amount)) * 100
        END AS profit_margin_percentage
    FROM gold.fact_sales;
END;
GO


EXEC gold.usp_sales_kpis;



-- Total Sales
SELECT
    SUM(sales_amount) AS total_sales
FROM gold.fact_sales;
--Total Sales
SELECT
    SUM(profit) AS total_profit
FROM gold.fact_sales;
--Sales by Category
SELECT
    p.category,
    SUM(f.sales_amount) AS total_sales
FROM gold.fact_sales f
JOIN gold.dim_product p
    ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_sales DESC;
--Profit by Category

SELECT
    p.category,
    SUM(f.profit) AS total_profit
FROM gold.fact_sales f
JOIN gold.dim_product p
    ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_profit DESC;
--Sales by Region
SELECT
    l.region,
    SUM(f.sales_amount) AS total_sales
FROM gold.fact_sales f
JOIN gold.dim_location l
    ON f.location_key = l.location_key
GROUP BY l.region
ORDER BY total_sales DESC;

--Profit by Region
SELECT
    l.region,
    SUM(f.profit) AS total_profit
FROM gold.fact_sales f
JOIN gold.dim_location l
    ON f.location_key = l.location_key
GROUP BY l.region
ORDER BY total_profit DESC;
--Customer Profitability
SELECT
    c.customer_id,
    c.customer_name,
    c.segment,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.profit) AS total_profit
FROM gold.fact_sales f
JOIN gold.dim_customer c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_id,
    c.customer_name,
    c.segment
ORDER BY total_profit DESC;
--Top 10 Products
SELECT TOP 10
    p.product_name,
    SUM(f.sales_amount) AS total_sales
FROM gold.fact_sales f
JOIN gold.dim_product p
    ON f.product_key = p.product_key
GROUP BY p.product_name
ORDER BY total_sales DESC;
--Sales by Ship Mode
SELECT
    sm.ship_mode,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.profit) AS total_profit
FROM gold.fact_sales f
JOIN gold.dim_ship_mode sm
    ON f.ship_mode_key = sm.ship_mode_key
GROUP BY sm.ship_mode
ORDER BY total_sales DESC;
--Monthly Sales Trend
SELECT
    d.year,
    d.month,
    d.month_name,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.profit) AS total_profit
FROM gold.fact_sales f
JOIN gold.dim_date d
    ON f.order_date_key = d.date_key
GROUP BY
    d.year,
    d.month,
    d.month_name
ORDER BY
    d.year,
    d.month;
--CTE
WITH customer_sales AS (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales f
    JOIN gold.dim_customer c
        ON f.customer_key = c.customer_key
    GROUP BY
        c.customer_id,
        c.customer_name
)
SELECT
    customer_id,
    customer_name,
    total_sales
FROM customer_sales
WHERE total_sales > (
    SELECT AVG(total_sales)
    FROM customer_sales
)
ORDER BY total_sales DESC;
--CTE2

WITH customer_profit AS (
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(f.profit) AS total_profit
    FROM gold.fact_sales f
    JOIN gold.dim_customer c
        ON f.customer_key = c.customer_key
    GROUP BY
        c.customer_id,
        c.customer_name
)
SELECT
    customer_id,
    customer_name,
    total_profit,
    CASE
        WHEN total_profit >= 500 THEN 'High Profit'
        WHEN total_profit >= 100 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profitability_segment
FROM customer_profit
ORDER BY total_profit DESC;

--Subquery
SELECT
    p.product_name,
    SUM(f.sales_amount) AS total_sales
FROM gold.fact_sales f
JOIN gold.dim_product p
    ON f.product_key = p.product_key
GROUP BY p.product_name
HAVING SUM(f.sales_amount) >
(
    SELECT AVG(product_sales)
    FROM (
        SELECT
            SUM(sales_amount) AS product_sales
        FROM gold.fact_sales
        GROUP BY product_key
    ) x
)
ORDER BY total_sales DESC;

--Optimization

CREATE INDEX IX_fact_sales_customer
ON gold.fact_sales(customer_key);

CREATE INDEX IX_fact_sales_product
ON gold.fact_sales(product_key);

CREATE INDEX IX_fact_sales_location
ON gold.fact_sales(location_key);

CREATE INDEX IX_fact_sales_order_date
ON gold.fact_sales(order_date_key);

CREATE INDEX IX_fact_sales_ship_date
ON gold.fact_sales(ship_date_key);

CREATE INDEX IX_fact_sales_ship_mode
ON gold.fact_sales(ship_mode_key);

CREATE INDEX IX_fact_sales_order_id
ON gold.fact_sales(order_id);