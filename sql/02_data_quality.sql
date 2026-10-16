-- =========================================================
-- 1. Qualité des commandes
-- =========================================================

-- Ajout de flags pour repérer les incohérences de dates

CREATE OR REPLACE VIEW vw_orders_quality AS
SELECT
    o.*,
    CASE
        WHEN order_approved_at IS NOT NULL
         AND order_delivered_carrier_date IS NOT NULL
         AND order_delivered_carrier_date::timestamp < order_approved_at::timestamp
        THEN 1
        ELSE 0
    END AS flag_carrier_before_approval,
    CASE
        WHEN order_delivered_carrier_date IS NOT NULL
         AND order_delivered_customer_date IS NOT NULL
         AND order_delivered_customer_date::timestamp < order_delivered_carrier_date::timestamp
        THEN 1
        ELSE 0
    END AS flag_delivery_before_carrier,
    CASE
        WHEN order_approved_at IS NOT NULL
         AND order_delivered_customer_date IS NOT NULL
         AND order_delivered_customer_date::timestamp < order_approved_at::timestamp
        THEN 1
        ELSE 0
    END AS flag_delivery_before_approval
FROM stg_orders o;


-- Vérification des flags

SELECT
    COUNT(*) AS total_orders,
    SUM(flag_carrier_before_approval) AS carrier_before_approval,
    SUM(flag_delivery_before_carrier) AS delivery_before_carrier,
    SUM(flag_delivery_before_approval) AS delivery_before_approval
FROM vw_orders_quality;

SELECT
    current_database(),
    current_schema();

SELECT *
FROM vw_orders_quality
LIMIT 5;

-- Vue de qualité des avis

CREATE OR REPLACE VIEW vw_reviews_quality AS
SELECT
    r.*,
    o.order_delivered_customer_date,
    CASE
        WHEN o.order_delivered_customer_date IS NULL
        THEN NULL
        WHEN r.review_creation_date::date
             < o.order_delivered_customer_date::date
        THEN 1
        ELSE 0
    END AS flag_review_before_delivery
FROM stg_order_reviews r
LEFT JOIN stg_orders o
    ON r.order_id = o.order_id;

-- Vérification du contrôle sur les avis

SELECT
    COUNT(*) AS total_reviews,
    COUNT(flag_review_before_delivery) AS reviews_checked,
    SUM(flag_review_before_delivery) AS reviews_before_delivery
FROM vw_reviews_quality;

SELECT COUNT(*)
FROM vw_reviews_quality
WHERE flag_review_before_delivery IS NULL;

-- Vue de qualité des produits

CREATE OR REPLACE VIEW vw_products_quality AS
SELECT
    p.*,
    CASE
        WHEN product_category_name IS NULL
         AND product_name_lenght IS NULL
         AND product_description_lenght IS NULL
         AND product_photos_qty IS NULL
        THEN 1
        ELSE 0
    END AS flag_missing_product_info,
    CASE
        WHEN product_weight_g IS NULL
         AND product_length_cm IS NULL
         AND product_height_cm IS NULL
         AND product_width_cm IS NULL
        THEN 1
        ELSE 0
    END AS flag_missing_physical_info,
    CASE
        WHEN product_weight_g = 0
        THEN 1
        ELSE 0
    END AS flag_zero_weight
FROM stg_products p;

SELECT
    COUNT(*) AS total_products,
    SUM(flag_missing_product_info) AS missing_product_info,
    SUM(flag_missing_physical_info) AS missing_physical_info,
    SUM(flag_zero_weight) AS zero_weight
FROM vw_products_quality;

-- Vue de qualité des paiements

CREATE OR REPLACE VIEW vw_payments_quality AS
SELECT
    p.*,
    CASE
        WHEN payment_value = 0
        THEN 1
        ELSE 0
    END AS flag_zero_payment,
    CASE
        WHEN payment_installments = 0
        THEN 1
        ELSE 0
    END AS flag_zero_installments,
    CASE
        WHEN payment_type = 'not_defined'
        THEN 1
        ELSE 0
    END AS flag_payment_type_not_defined
FROM stg_order_payments p;

-- Vérification des flags paiements

SELECT
    COUNT(*) AS total_payment_rows,
    SUM(flag_zero_payment) AS zero_payment_rows,
    SUM(flag_zero_installments) AS zero_installment_rows,
    SUM(flag_payment_type_not_defined) AS not_defined_rows
FROM vw_payments_quality;

-- Comparaison entre le montant payé et le montant des articles

CREATE OR REPLACE VIEW vw_order_payment_quality as
WITH payment_totals AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_paid
    FROM stg_order_payments
    GROUP BY order_id
),
item_totals AS (
    SELECT
        order_id,
        SUM(price + freight_value) AS total_items
    FROM stg_order_items
    GROUP BY order_id
)
SELECT
    p.order_id,
    p.total_paid,
    i.total_items,
    p.total_paid - i.total_items AS payment_difference,
    CASE
        WHEN ABS(p.total_paid - i.total_items) > 0.01
        THEN 1
        ELSE 0
    END AS flag_payment_difference
FROM payment_totals p
INNER JOIN item_totals i
    ON p.order_id = i.order_id;

-- Vérification des écarts paiement / articles

SELECT
    COUNT(*) AS comparable_orders,
    SUM(flag_payment_difference) AS orders_with_payment_difference
FROM vw_order_payment_quality;

SELECT *
FROM vw_order_payment_quality v
WHERE v.flag_payment_difference = 1;

-- Vue de qualité des données géographiques

CREATE OR REPLACE VIEW vw_geolocation_quality AS
WITH geo_ranked AS (
    SELECT
        g.*,
        ROW_NUMBER() OVER (
            PARTITION BY
                geolocation_zip_code_prefix,
                geolocation_lat,
                geolocation_lng,
                geolocation_city,
                geolocation_state
            ORDER BY geolocation_zip_code_prefix
        ) AS duplicate_rank
    FROM stg_geolocation g
)
SELECT
    geo_ranked.*,
    CASE
        WHEN duplicate_rank > 1
        THEN 1
        ELSE 0
    END AS flag_exact_duplicate,
    CASE
        WHEN geolocation_lat < -35
          OR geolocation_lat > 6
          OR geolocation_lng < -75
          OR geolocation_lng > -30
        THEN 1
        ELSE 0
    END AS flag_outside_brazil
FROM geo_ranked;

-- Vérification des flags géographiques

SELECT
    COUNT(*) AS total_geo_rows,
    SUM(flag_exact_duplicate) AS duplicate_rows,
    SUM(flag_outside_brazil) AS outside_brazil_rows
FROM vw_geolocation_quality;

-- Vue de qualité des traductions de catégories

CREATE OR REPLACE VIEW vw_product_categories_quality AS
SELECT
    p.product_id,
    p.product_category_name,
    t.product_category_name_english,
    CASE
        WHEN p.product_category_name IS NOT NULL
        AND t.product_category_name_english IS NULL
        THEN 1
        ELSE 0
    END AS flag_missing_translation
FROM stg_products p
LEFT JOIN stg_product_category_name_translation t
    ON p.product_category_name = t.product_category_name;

-- Vérification des traductions manquantes

SELECT
    COUNT(*) AS total_products,
    SUM(flag_missing_translation) AS products_without_translation,
    COUNT(DISTINCT CASE
        WHEN flag_missing_translation = 1
        THEN product_category_name
    END) AS categories_without_translation
FROM vw_product_categories_quality;

-- Contrôle final des vues Data Quality

SELECT
    (SELECT COUNT(*) FROM vw_orders_quality) AS orders_rows,
    (SELECT COUNT(*) FROM vw_reviews_quality) AS reviews_rows,
    (SELECT COUNT(*) FROM vw_products_quality) AS products_rows,
    (SELECT COUNT(*) FROM vw_payments_quality) AS payment_rows,
    (SELECT COUNT(*) FROM vw_order_payment_quality) AS comparable_orders,
    (SELECT COUNT(*) FROM vw_geolocation_quality) AS geolocation_rows,
    (SELECT COUNT(*) FROM vw_product_categories_quality) AS category_product_rows;

