-- =========================================================
-- E-COMMERCE SALES ANALYSIS
-- Database: ecommerce_sample
-- Tool: MySQL Workbench
--
-- Project purpose:
-- Analyze orders, revenue, products, customers,
-- discounts and product returns.
--
-- IMPORTANT:
-- Revenue in this project is calculated as:
-- quantity * unit_price
--
-- This represents the gross value of order items
-- BEFORE deducting order discounts.
-- It does not necessarily represent the final
-- realized revenue of the business.
-- =========================================================


-- =========================================================
-- 1. DATABASE OVERVIEW
-- Explore database tables and basic information.
-- =========================================================

SHOW TABLES;

SELECT *
FROM addresses;

SELECT COUNT(*) AS total_brands
FROM brands;


-- =========================================================
-- 2. ORDER ANALYSIS
-- Explore orders and understand their status distribution.
-- =========================================================

DESCRIBE orders;

SELECT *
FROM orders
LIMIT 10;

SELECT COUNT(*) AS total_orders
FROM orders;


-- Count orders by status ID.
SELECT
    order_status_id,
    COUNT(*) AS total_orders
FROM orders
GROUP BY order_status_id
ORDER BY total_orders DESC;


-- Explore order status descriptions.
SELECT *
FROM order_statuses;


-- Count orders by status name.
SELECT
    os.status_name,
    COUNT(o.id) AS total_orders
FROM orders o
JOIN order_statuses os
    ON o.order_status_id = os.id
GROUP BY os.status_name
ORDER BY total_orders DESC;


-- Calculate the percentage of orders by status.
SELECT
    os.status_name,
    COUNT(o.id) AS total_orders,
    ROUND(
        COUNT(o.id) * 100.0 /
        (SELECT COUNT(*) FROM orders),
        2
    ) AS percentage
FROM orders o
JOIN order_statuses os
    ON o.order_status_id = os.id
GROUP BY os.status_name
ORDER BY total_orders DESC;


-- =========================================================
-- 3. REVENUE ANALYSIS
-- Calculate gross revenue from order items.
--
-- Revenue definition:
-- quantity * unit_price
--
-- This is gross order-item value BEFORE order discounts.
-- It should not be interpreted as final realized revenue.
-- =========================================================

DESCRIBE order_items;

SELECT *
FROM order_items;


-- Preview order item revenue calculation.
SELECT
    order_id,
    product_id,
    quantity,
    unit_price,
    quantity * unit_price AS revenue
FROM order_items
LIMIT 10;


-- Calculate total gross revenue.
SELECT
    SUM(quantity * unit_price) AS total_gross_revenue
FROM order_items;


-- Calculate gross revenue by order status.
SELECT
    os.status_name,
    SUM(oi.quantity * oi.unit_price) AS gross_revenue
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.id
JOIN order_statuses os
    ON o.order_status_id = os.id
GROUP BY os.status_name
ORDER BY gross_revenue DESC;


-- =========================================================
-- 4. PRODUCT AND CATEGORY ANALYSIS
-- Identify the best-performing product categories and products.
-- =========================================================

DESCRIBE products;

DESCRIBE categories;

SELECT *
FROM categories
LIMIT 10;


-- Gross revenue by product category.
SELECT
    c.name AS category,
    SUM(oi.quantity * oi.unit_price) AS gross_revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.id
JOIN categories c
    ON p.category_id = c.id
GROUP BY c.name
ORDER BY gross_revenue DESC;


-- Top 10 products by gross revenue.
SELECT
    p.name AS product_name,
    SUM(oi.quantity * oi.unit_price) AS gross_revenue
FROM order_items oi
JOIN products p
    ON oi.product_id = p.id
GROUP BY p.id, p.name
ORDER BY gross_revenue DESC
LIMIT 10;


-- Top 10 products by quantity sold.
SELECT
    p.name AS product_name,
    SUM(oi.quantity) AS total_quantity_sold
FROM order_items oi
JOIN products p
    ON oi.product_id = p.id
GROUP BY p.id, p.name
ORDER BY total_quantity_sold DESC
LIMIT 10;


-- Top 10 products by revenue, including quantity sold
-- and weighted average selling price.
SELECT
    p.name AS product_name,
    SUM(oi.quantity) AS total_quantity_sold,
    ROUND(
        SUM(oi.quantity * oi.unit_price), 2
    ) AS total_gross_revenue,
    ROUND(
        SUM(oi.quantity * oi.unit_price) /
        SUM(oi.quantity), 2
    ) AS average_selling_price
FROM order_items oi
JOIN products p
    ON oi.product_id = p.id
GROUP BY p.id, p.name
ORDER BY total_gross_revenue DESC
LIMIT 10;


-- =========================================================
-- 5. TIME-BASED SALES ANALYSIS
-- Explore the date range and revenue trends over time.
-- =========================================================


-- Identify the first and last order dates.
SELECT
    MIN(created_at) AS first_order,
    MAX(created_at) AS last_order
FROM orders;


-- Calculate monthly gross revenue.
SELECT
    YEAR(o.created_at) AS year,
    MONTH(o.created_at) AS month,
    DATE_FORMAT(o.created_at, '%Y-%m') AS year_month,
    SUM(oi.quantity * oi.unit_price) AS gross_revenue
FROM orders o
JOIN order_items oi
    ON o.id = oi.order_id
GROUP BY
    YEAR(o.created_at),
    MONTH(o.created_at),
    DATE_FORMAT(o.created_at, '%Y-%m')
ORDER BY year_month;


-- Calculate yearly revenue and number of orders.
SELECT
    YEAR(o.created_at) AS year,
    COUNT(DISTINCT o.id) AS total_orders,
    SUM(oi.quantity * oi.unit_price) AS gross_revenue
FROM orders o
JOIN order_items oi
    ON o.id = oi.order_id
GROUP BY YEAR(o.created_at)
ORDER BY year;


-- Calculate yearly revenue and average order value.
SELECT
    YEAR(o.created_at) AS year,
    COUNT(DISTINCT o.id) AS total_orders,
    ROUND(
        SUM(oi.quantity * oi.unit_price), 2
    ) AS gross_revenue,
    ROUND(
        SUM(oi.quantity * oi.unit_price) /
        COUNT(DISTINCT o.id), 2
    ) AS average_order_value
FROM orders o
JOIN order_items oi
    ON o.id = oi.order_id
GROUP BY YEAR(o.created_at)
ORDER BY year;


-- Year-over-year (YoY) revenue growth.
-- LAG() retrieves the revenue from the previous year.
WITH yearly_revenue AS (
    SELECT
        YEAR(o.created_at) AS year,
        SUM(oi.quantity * oi.unit_price) AS revenue
    FROM orders o
    JOIN order_items oi
        ON o.id = oi.order_id
    GROUP BY YEAR(o.created_at)
),
revenue_comparison AS (
    SELECT
        year,
        revenue,
        LAG(revenue) OVER (ORDER BY year) AS previous_year_revenue
    FROM yearly_revenue
)
SELECT
    year,
    ROUND(revenue, 2) AS revenue,
    ROUND(previous_year_revenue, 2) AS previous_year_revenue,
    ROUND(
        (revenue - previous_year_revenue) /
        NULLIF(previous_year_revenue, 0) * 100,
        2
    ) AS yoy_growth_percent
FROM revenue_comparison
ORDER BY year;


-- =========================================================
-- 6. CUSTOMER ANALYSIS
-- Explore customer purchasing behavior and loyalty.
-- =========================================================


-- Top 10 customers by gross order-item value.
SELECT
    u.id AS customer_id,
    COUNT(DISTINCT o.id) AS total_orders,
    ROUND(
        SUM(oi.quantity * oi.unit_price), 2
    ) AS total_gross_spent
FROM users u
JOIN orders o
    ON u.id = o.user_id
JOIN order_items oi
    ON o.id = oi.order_id
GROUP BY u.id
ORDER BY total_gross_spent DESC
LIMIT 10;


-- Classify customers as one-time or repeat customers.
WITH customer_orders AS (
    SELECT
        user_id,
        COUNT(*) AS total_orders
    FROM orders
    GROUP BY user_id
)
SELECT
    CASE
        WHEN total_orders = 1 THEN 'One-time customer'
        ELSE 'Repeat customer'
    END AS customer_type,
    COUNT(*) AS total_customers,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM customer_orders),
        2
    ) AS percentage
FROM customer_orders
GROUP BY customer_type;


-- Distribution of customers by number of orders.
SELECT
    total_orders,
    COUNT(*) AS total_customers
FROM (
    SELECT
        user_id,
        COUNT(*) AS total_orders
    FROM orders
    GROUP BY user_id
) AS customer_orders
GROUP BY total_orders
ORDER BY total_orders;


-- Calculate average number of orders per customer.
SELECT
    COUNT(DISTINCT user_id) AS total_customers,
    COUNT(*) AS total_orders,
    ROUND(
        COUNT(*) * 1.0 /
        COUNT(DISTINCT user_id), 2
    ) AS avg_orders_per_customer
FROM orders;


-- =========================================================
-- 7. DISCOUNT ANALYSIS
-- Explore discounts applied to order items and orders.
-- =========================================================


-- Check whether individual order items have discounts.
SELECT
    COUNT(*) AS total_items,
    SUM(
        CASE
            WHEN discount_amount > 0 THEN 1
            ELSE 0
        END
    ) AS discounted_items,
    SUM(discount_amount) AS total_discount
FROM order_items;


-- Analyze discounts applied at order level.
SELECT
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN discount_amount > 0 THEN 1
            ELSE 0
        END
    ) AS discounted_orders,
    ROUND(SUM(discount_amount), 2) AS total_discount
FROM orders;


-- =========================================================
-- 8. PRODUCT RETURN ANALYSIS
-- Explore return requests, their statuses and reasons.
-- =========================================================

DESCRIBE order_returns;


-- Calculate total return requests and returned quantities.
SELECT
    COUNT(*) AS total_return_requests,
    SUM(quantity) AS total_returned_items,
    COUNT(DISTINCT order_item_id) AS returned_order_items
FROM order_returns;


-- Analyze return requests by status.
SELECT
    status,
    COUNT(*) AS total_return_requests,
    SUM(quantity) AS total_returned_quantity
FROM order_returns
GROUP BY status
ORDER BY total_return_requests DESC;


-- Explore return reason table.
DESCRIBE return_reasons;


-- Analyze return requests by reason.
SELECT
    rr.reason_text AS return_reason,
    COUNT(*) AS total_return_requests,
    SUM(or1.quantity) AS total_returned_quantity
FROM order_returns or1
JOIN return_reasons rr
    ON or1.reason_id = rr.id
GROUP BY rr.reason_text
ORDER BY total_return_requests DESC;


-- =========================================================
-- END OF E-COMMERCE SALES ANALYSIS
-- =========================================================