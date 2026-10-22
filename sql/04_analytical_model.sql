SELECT
    current_database(),
    current_schema();

-- =========================================================
-- 1. Dimension produits
-- =========================================================

CREATE OR REPLACE VIEW dim_products AS
SELECT
    product_id,
    product_category_name,
    product_name_length,
    product_description_length,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM vw_products_clean;

-- Vérification de la dimension produits

SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT product_id) AS unique_products
FROM dim_products;

-- =========================================================
-- 2. Dimension vendeurs
-- =========================================================

CREATE OR REPLACE VIEW dim_sellers AS
SELECT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM stg_sellers;

SELECT
    COUNT(*) AS total_sellers,
    COUNT(DISTINCT seller_id) AS unique_sellers
FROM dim_sellers;

-- =========================================================
-- 3. Dimension clients
-- =========================================================

CREATE OR REPLACE VIEW dim_customers AS
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM stg_customers;

SELECT
    COUNT(*) AS total_customers,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS unique_real_customers
FROM dim_customers;

-- =========================================================
-- 4. Dimension dates
-- =========================================================

CREATE OR REPLACE VIEW dim_date AS
SELECT
    TO_CHAR(d.date, 'YYYYMMDD')::integer AS date_id,
    d.date::date AS full_date,
    EXTRACT(YEAR FROM d.date)::integer AS year,
    EXTRACT(QUARTER FROM d.date)::integer AS quarter,
    EXTRACT(MONTH FROM d.date)::integer AS month_number,
    TO_CHAR(d.date, 'Month') AS month_name,
    TO_CHAR(d.date, 'YYYY-MM') AS year_month,
    EXTRACT(DAY FROM d.date)::integer AS day_of_month,
    EXTRACT(ISODOW FROM d.date)::integer AS day_of_week,
    CASE
        WHEN EXTRACT(ISODOW FROM d.date) IN (6, 7)
        THEN 1
        ELSE 0
    END AS is_weekend
FROM GENERATE_SERIES(
    (SELECT MIN(clean_purchase_timestamp)::date
     FROM vw_orders_clean),
    (SELECT MAX(clean_purchase_timestamp)::date
     FROM vw_orders_clean),
    INTERVAL '1 day'
) AS d(date);

SELECT
    COUNT(*) AS total_dates,
    COUNT(DISTINCT date_id) AS unique_dates,
    MIN(full_date) AS first_date,
    MAX(full_date) AS last_date
FROM dim_date;

-- =========================================================
-- 5. Table de faits commandes
-- =========================================================

CREATE OR REPLACE VIEW fact_orders AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    TO_CHAR(
        o.clean_purchase_timestamp,
        'YYYYMMDD'
    )::integer AS purchase_date_id,
    o.clean_purchase_timestamp,
    o.clean_approved_at,
    o.clean_carrier_date,
    o.clean_customer_delivery_date,
    o.clean_estimated_delivery_date,
    o.is_timeline_valid,
    f.total_paid,
    f.total_items,
    f.validated_total_paid,
    f.flag_payment_difference
FROM vw_orders_clean o
LEFT JOIN vw_order_financial_clean f
    ON o.order_id = f.order_id;

-- Verification de fact_orders
SELECT
    COUNT(*) AS total_orders,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS missing_customers,
    COUNT(*) FILTER (
        WHERE purchase_date_id IS NULL
    ) AS missing_purchase_dates
FROM fact_orders;

-- Vérification des données financières de fact_orders

SELECT
    COUNT(*) AS total_orders,
    COUNT(total_paid) AS orders_with_financial_data,
    COUNT(*) FILTER (
        WHERE flag_payment_difference = 1
    ) AS inconsistent_financial_orders,
    COUNT(*) FILTER (
        WHERE validated_total_paid IS NOT NULL
    ) AS validated_financial_orders
FROM fact_orders;

-- =========================================================
-- 6. Table de faits articles
-- =========================================================

CREATE OR REPLACE VIEW fact_order_items AS
SELECT
    i.order_id,
    i.order_item_id,
    i.product_id,
    i.seller_id,
    o.customer_id,
    o.purchase_date_id,
    i.shipping_limit_date::timestamp AS shipping_limit_date,
    i.price,
    i.freight_value,
    i.price + i.freight_value AS item_total_amount
FROM stg_order_items i
INNER JOIN fact_orders o
    ON i.order_id = o.order_id;

SELECT
    COUNT(*) AS total_items,
    COUNT(*) FILTER (
        WHERE product_id IS NULL
    ) AS missing_products,
    COUNT(*) FILTER (
        WHERE seller_id IS NULL
    ) AS missing_sellers,
    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS missing_customers,
    COUNT(*) FILTER (
        WHERE purchase_date_id IS NULL
    ) AS missing_purchase_dates
FROM fact_order_items;

-- Vérification de l'unicité du grain

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (order_id, order_item_id)) AS unique_order_items
FROM fact_order_items;

-- Vérification des montants

SELECT
    COUNT(*) FILTER (
        WHERE price < 0
    ) AS negative_prices,
    COUNT(*) FILTER (
        WHERE freight_value < 0
    ) AS negative_freight,
    COUNT(*) FILTER (
        WHERE item_total_amount < 0
    ) AS negative_item_totals
FROM fact_order_items;

-- =========================================================
-- 7. Table de faits paiements
-- =========================================================

CREATE OR REPLACE VIEW fact_payments AS
SELECT
    p.order_id,
    p.payment_sequential,
    o.customer_id,
    o.purchase_date_id,
    p.payment_type,
    p.payment_installments,
    p.payment_value
FROM vw_payments_clean p
INNER JOIN fact_orders o
    ON p.order_id = o.order_id;

-- Vérification de fact_payments

SELECT
    COUNT(*) AS total_payments,
    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS missing_customers,
    COUNT(*) FILTER (
        WHERE purchase_date_id IS NULL
    ) AS missing_purchase_dates,
    COUNT(*) FILTER (
        WHERE payment_type IS NULL
    ) AS missing_payment_types
FROM fact_payments;

-- Vérification de l'unicité du grain

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT (order_id, payment_sequential)) AS unique_payments
FROM fact_payments;

-- =========================================================
-- 8. Contrôle final du modèle analytique
-- =========================================================

SELECT
    (SELECT COUNT(*) FROM dim_products) AS products,
    (SELECT COUNT(*) FROM dim_sellers) AS sellers,
    (SELECT COUNT(*) FROM dim_customers) AS customers,
    (SELECT COUNT(*) FROM dim_date) AS dates,
    (SELECT COUNT(*) FROM fact_orders) AS orders,
    (SELECT COUNT(*) FROM fact_order_items) AS order_items,
    (SELECT COUNT(*) FROM fact_payments) AS payments;

-- Vérification des relations du modèle

SELECT
    (SELECT COUNT(*)
     FROM fact_orders f
     LEFT JOIN dim_customers d
       ON f.customer_id = d.customer_id
     WHERE d.customer_id IS NULL
    ) AS orders_without_customer,
    (SELECT COUNT(*)
     FROM fact_orders f
     LEFT JOIN dim_date d
       ON f.purchase_date_id = d.date_id
     WHERE d.date_id IS NULL
    ) AS orders_without_date,
    (SELECT COUNT(*)
     FROM fact_order_items f
     LEFT JOIN dim_products d
       ON f.product_id = d.product_id
     WHERE d.product_id IS NULL
    ) AS items_without_product,
    (SELECT COUNT(*)
     FROM fact_order_items f
     LEFT JOIN dim_sellers d
       ON f.seller_id = d.seller_id
     WHERE d.seller_id IS NULL
    ) AS items_without_seller,
    (SELECT COUNT(*)
     FROM fact_order_items f
     LEFT JOIN fact_orders o
       ON f.order_id = o.order_id
     WHERE o.order_id IS NULL
    ) AS items_without_order,
    (SELECT COUNT(*)
     FROM fact_payments f
     LEFT JOIN fact_orders o
       ON f.order_id = o.order_id
     WHERE o.order_id IS NULL
    ) AS payments_without_order;

