/* ================================================================
   GOLD LAYER - DOCUMENTED ANALYTICAL QUERIES
   Project: Superstore Data Warehouse

   Purpose:
   This script contains analytical queries for executive reporting,
   KPI monitoring, profitability analysis, customer behavior,
   product performance, geographic analysis, and sales trends.

   Data Source:
   gold.fact_sales + gold dimension tables

   Star Schema:
   fact_sales
       |
       +-- dim_date
       +-- dim_customer
       +-- dim_product
       +-- dim_location
       +-- dim_ship_mode
================================================================ */


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



/* ================================================================
   QUERY 01 - OVERALL SALES KPIs
   ---------------------------------------------------------------
   Business Question:
   What are the overall sales, profit, quantity, and order KPIs?

   Purpose:
   Provides a high-level executive summary of business performance.
================================================================ */

SELECT
    COUNT(*) AS total_sales_transactions,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(quantity) AS total_quantity,
    SUM(sales_amount) AS total_sales,
    SUM(profit) AS total_profit,
    AVG(sales_amount) AS average_transaction_value,
    AVG(discount) AS average_discount,
    CASE
        WHEN SUM(sales_amount) = 0 THEN 0
        ELSE (SUM(profit) / SUM(sales_amount)) * 100
    END AS profit_margin_percentage
FROM gold.fact_sales;


/* ================================================================
   QUERY 02 - SALES BY CATEGORY
   ---------------------------------------------------------------
   Business Question:
   Which product categories generate the most sales?

   Purpose:
   Compares revenue contribution across product categories.
================================================================ */

SELECT
    p.category,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.quantity) AS total_quantity,
    SUM(f.profit) AS total_profit
FROM gold.fact_sales f
INNER JOIN gold.dim_product p
    ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_sales DESC;


/* ================================================================
   QUERY 03 - PROFITABILITY BY CATEGORY
   ---------------------------------------------------------------
   Business Question:
   Which categories are the most profitable?

   Purpose:
   Measures profit and profit margin by category.
================================================================ */

SELECT
    p.category,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.profit) AS total_profit,
    CASE
        WHEN SUM(f.sales_amount) = 0 THEN 0
        ELSE (SUM(f.profit) / SUM(f.sales_amount)) * 100
    END AS profit_margin_percentage
FROM gold.fact_sales f
INNER JOIN gold.dim_product p
    ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_profit DESC;


/* ================================================================
   QUERY 04 - TOP 10 PRODUCTS BY SALES
   ---------------------------------------------------------------
   Business Question:
   Which products generate the highest sales?

   Purpose:
   Identifies the strongest products by revenue contribution.
================================================================ */

SELECT TOP 10
    p.product_id,
    p.product_name,
    p.category,
    p.sub_category,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.profit) AS total_profit
FROM gold.fact_sales f
INNER JOIN gold.dim_product p
    ON f.product_key = p.product_key
GROUP BY
    p.product_id,
    p.product_name,
    p.category,
    p.sub_category
ORDER BY total_sales DESC;


/* ================================================================
   QUERY 05 - TOP 10 PRODUCTS BY PROFIT
   ---------------------------------------------------------------
   Business Question:
   Which products generate the highest profit?

   Purpose:
   Identifies products that contribute most to profitability,
   rather than only looking at revenue.
================================================================ */

SELECT TOP 10
    p.product_id,
    p.product_name,
    p.category,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.profit) AS total_profit,
    CASE
        WHEN SUM(f.sales_amount) = 0 THEN 0
        ELSE (SUM(f.profit) / SUM(f.sales_amount)) * 100
    END AS profit_margin_percentage
FROM gold.fact_sales f
INNER JOIN gold.dim_product p
    ON f.product_key = p.product_key
GROUP BY
    p.product_id,
    p.product_name,
    p.category
ORDER BY total_profit DESC;


/* ================================================================
   QUERY 06 - SALES TREND BY YEAR
   ---------------------------------------------------------------
   Business Question:
   How does sales performance change from year to year?

   Purpose:
   Analyzes long-term sales and profitability trends.
================================================================ */

SELECT
    d.year,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.profit) AS total_profit,
    SUM(f.quantity) AS total_quantity
FROM gold.fact_sales f
INNER JOIN gold.dim_date d
    ON f.order_date_key = d.date_key
GROUP BY d.year
ORDER BY d.year;


/* ================================================================
   QUERY 07 - MONTHLY SALES TREND
   ---------------------------------------------------------------
   Business Question:
   How do sales and profit change month by month?

   Purpose:
   Detects seasonal patterns and monthly performance changes.
================================================================ */

SELECT
    d.year,
    d.month,
    d.month_name,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.profit) AS total_profit,
    SUM(f.quantity) AS total_quantity
FROM gold.fact_sales f
INNER JOIN gold.dim_date d
    ON f.order_date_key = d.date_key
GROUP BY
    d.year,
    d.month,
    d.month_name
ORDER BY
    d.year,
    d.month;


/* ================================================================
   QUERY 08 - SALES BY REGION
   ---------------------------------------------------------------
   Business Question:
   Which regions generate the highest sales and profit?

   Purpose:
   Supports geographic performance analysis.
================================================================ */

SELECT
    l.region,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.profit) AS total_profit,
    SUM(f.quantity) AS total_quantity
FROM gold.fact_sales f
INNER JOIN gold.dim_location l
    ON f.location_key = l.location_key
GROUP BY l.region
ORDER BY total_sales DESC;


/* ================================================================
   QUERY 09 - SALES BY STATE
   ---------------------------------------------------------------
   Business Question:
   Which states contribute the most to sales?

   Purpose:
   Provides a more detailed geographic analysis than region level.
================================================================ */

SELECT TOP 15
    l.state,
    l.region,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.profit) AS total_profit
FROM gold.fact_sales f
INNER JOIN gold.dim_location l
    ON f.location_key = l.location_key
GROUP BY
    l.state,
    l.region
ORDER BY total_sales DESC;


/* ================================================================
   QUERY 10 - CUSTOMER PROFITABILITY
   ---------------------------------------------------------------
   Business Question:
   Which customers generate the highest sales and profit?

   Purpose:
   Supports customer value and profitability analysis.
================================================================ */

SELECT TOP 20
    c.customer_id,
    c.customer_name,
    c.segment,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.profit) AS total_profit
FROM gold.fact_sales f
INNER JOIN gold.dim_customer c
    ON f.customer_key = c.customer_key
GROUP BY
    c.customer_id,
    c.customer_name,
    c.segment
ORDER BY total_profit DESC;


/* ================================================================
   QUERY 11 - CUSTOMER SEGMENT PERFORMANCE
   ---------------------------------------------------------------
   Business Question:
   How does each customer segment perform?

   Purpose:
   Compares Consumer, Corporate, and other customer segments
   using sales, profit, and order volume.
================================================================ */

SELECT
    c.segment,
    COUNT(DISTINCT c.customer_id) AS number_of_customers,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.profit) AS total_profit,
    CASE
        WHEN SUM(f.sales_amount) = 0 THEN 0
        ELSE (SUM(f.profit) / SUM(f.sales_amount)) * 100
    END AS profit_margin_percentage
FROM gold.fact_sales f
INNER JOIN gold.dim_customer c
    ON f.customer_key = c.customer_key
GROUP BY c.segment
ORDER BY total_sales DESC;


/* ================================================================
   QUERY 12 - SHIP MODE PERFORMANCE
   ---------------------------------------------------------------
   Business Question:
   Which shipping modes generate the most sales and profit?

   Purpose:
   Evaluates sales performance across different shipping methods.
================================================================ */

SELECT
    sm.ship_mode,
    COUNT(DISTINCT f.order_id) AS total_orders,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.profit) AS total_profit,
    AVG(f.discount) AS average_discount
FROM gold.fact_sales f
INNER JOIN gold.dim_ship_mode sm
    ON f.ship_mode_key = sm.ship_mode_key
GROUP BY sm.ship_mode
ORDER BY total_sales DESC;


/* ================================================================
   QUERY 13 - HIGH-VALUE CUSTOMERS USING CTE
   ---------------------------------------------------------------
   Business Question:
   Which customers generate sales above the average customer sales?

   Purpose:
   Uses a CTE and subquery to identify high-value customers.
================================================================ */

WITH customer_sales AS
(
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(f.sales_amount) AS total_sales
    FROM gold.fact_sales f
    INNER JOIN gold.dim_customer c
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
WHERE total_sales >
(
    SELECT AVG(total_sales)
    FROM customer_sales
)
ORDER BY total_sales DESC;


/* ================================================================
   QUERY 14 - CUSTOMER PROFITABILITY CLASSIFICATION
   ---------------------------------------------------------------
   Business Question:
   How can customers be classified based on their profitability?

   Purpose:
   Uses a CTE and CASE statement to classify customers.
================================================================ */

WITH customer_profit AS
(
    SELECT
        c.customer_id,
        c.customer_name,
        SUM(f.sales_amount) AS total_sales,
        SUM(f.profit) AS total_profit
    FROM gold.fact_sales f
    INNER JOIN gold.dim_customer c
        ON f.customer_key = c.customer_key
    GROUP BY
        c.customer_id,
        c.customer_name
)
SELECT
    customer_id,
    customer_name,
    total_sales,
    total_profit,
    CASE
        WHEN total_profit >= 500 THEN 'High Profit'
        WHEN total_profit >= 100 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profitability_segment
FROM customer_profit
ORDER BY total_profit DESC;


/* ================================================================
   QUERY 15 - PRODUCTS ABOVE AVERAGE SALES
   ---------------------------------------------------------------
   Business Question:
   Which products generate sales above the average product sales?

   Purpose:
   Uses a subquery to identify products performing above
   the overall product average.
================================================================ */

SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(f.sales_amount) AS total_sales
FROM gold.fact_sales f
INNER JOIN gold.dim_product p
    ON f.product_key = p.product_key
GROUP BY
    p.product_id,
    p.product_name,
    p.category
HAVING SUM(f.sales_amount) >
(
    SELECT AVG(product_sales)
    FROM
    (
        SELECT
            SUM(sales_amount) AS product_sales
        FROM gold.fact_sales
        GROUP BY product_key
    ) AS product_summary
)
ORDER BY total_sales DESC;


/* ================================================================
   QUERY 16 - LOSS-MAKING PRODUCTS
   ---------------------------------------------------------------
   Business Question:
   Which products generate negative profit?

   Purpose:
   Identifies products that generate revenue but negatively
   affect overall profitability.
================================================================ */

SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.profit) AS total_profit
FROM gold.fact_sales f
INNER JOIN gold.dim_product p
    ON f.product_key = p.product_key
GROUP BY
    p.product_id,
    p.product_name,
    p.category
HAVING SUM(f.profit) < 0
ORDER BY total_profit ASC;


/* ================================================================
   QUERY 17 - DISCOUNT VS PROFITABILITY
   ---------------------------------------------------------------
   Business Question:
   How does discount level relate to sales and profit?

   Purpose:
   Groups transactions into discount ranges to analyze
   their relationship with profitability.
================================================================ */

SELECT
    CASE
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount <= 0.20 THEN 'Low Discount'
        WHEN discount <= 0.40 THEN 'Medium Discount'
        ELSE 'High Discount'
    END AS discount_category,

    COUNT(*) AS total_transactions,
    SUM(sales_amount) AS total_sales,
    SUM(profit) AS total_profit,

    CASE
        WHEN SUM(sales_amount) = 0 THEN 0
        ELSE (SUM(profit) / SUM(sales_amount)) * 100
    END AS profit_margin_percentage

FROM gold.fact_sales
GROUP BY
    CASE
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount <= 0.20 THEN 'Low Discount'
        WHEN discount <= 0.40 THEN 'Medium Discount'
        ELSE 'High Discount'
    END
ORDER BY total_sales DESC;


/* ================================================================
   QUERY 18 - SUB-CATEGORY PERFORMANCE
   ---------------------------------------------------------------
   Business Question:
   Which sub-categories have the strongest sales and profitability?

   Purpose:
   Provides a deeper product hierarchy analysis.
================================================================ */

SELECT
    p.category,
    p.sub_category,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.profit) AS total_profit,
    SUM(f.quantity) AS total_quantity
FROM gold.fact_sales f
INNER JOIN gold.dim_product p
    ON f.product_key = p.product_key
GROUP BY
    p.category,
    p.sub_category
ORDER BY
    p.category,
    total_sales DESC;


/* ================================================================
   QUERY 19 - CITY LEVEL PERFORMANCE
   ---------------------------------------------------------------
   Business Question:
   Which cities generate the highest sales?

   Purpose:
   Identifies high-performing geographic markets.
================================================================ */

SELECT TOP 20
    l.city,
    l.state,
    l.region,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.profit) AS total_profit
FROM gold.fact_sales f
INNER JOIN gold.dim_location l
    ON f.location_key = l.location_key
GROUP BY
    l.city,
    l.state,
    l.region
ORDER BY total_sales DESC;


/* ================================================================
   QUERY 20 - YEARLY PROFIT MARGIN
   ---------------------------------------------------------------
   Business Question:
   How does profitability change over time?

   Purpose:
   Tracks annual sales, profit, and profit margin.
================================================================ */

SELECT
    d.year,
    SUM(f.sales_amount) AS total_sales,
    SUM(f.profit) AS total_profit,
    CASE
        WHEN SUM(f.sales_amount) = 0 THEN 0
        ELSE (SUM(f.profit) / SUM(f.sales_amount)) * 100
    END AS profit_margin_percentage
FROM gold.fact_sales f
INNER JOIN gold.dim_date d
    ON f.order_date_key = d.date_key
GROUP BY d.year
ORDER BY d.year;