SELECT
    current_database(),
    current_schema();

-- =========================================================
-- 1. Nettoyage des produits
-- =========================================================

CREATE OR REPLACE VIEW vw_products_clean AS
SELECT
    p.product_id,
    COALESCE(
        t.product_category_name_english,
        p.product_category_name,
        'unknown'
    ) AS product_category_name,
    p.product_name_lenght AS product_name_length,
    p.product_description_lenght AS product_description_length,
    p.product_photos_qty,
    NULLIF(p.product_weight_g, 0) AS product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM stg_products p
LEFT JOIN stg_product_category_name_translation t
    ON p.product_category_name = t.product_category_name;

SELECT
    COUNT(*) AS total_products,
    COUNT(*) FILTER (
        WHERE product_category_name = 'unknown'
    ) AS unknown_categories,
    COUNT(*) FILTER (
        WHERE product_weight_g = 0
    ) AS zero_weights,
    COUNT(*) FILTER (
        WHERE product_weight_g IS NULL
    ) AS null_weights
FROM vw_products_clean;

-- Vérification du chevauchement entre doublons et coordonnées hors Brésil

SELECT
    COUNT(*) AS total_rows,
    SUM(flag_exact_duplicate) AS duplicate_rows,
    SUM(flag_outside_brazil) AS outside_brazil_rows,
    COUNT(*) FILTER (
        WHERE flag_exact_duplicate = 1
          AND flag_outside_brazil = 1
    ) AS duplicate_and_outside_brazil
FROM vw_geolocation_quality;

-- =========================================================
-- 2. Nettoyage de la géolocalisation
-- =========================================================

CREATE OR REPLACE VIEW vw_geolocation_clean AS
SELECT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
FROM vw_geolocation_quality
WHERE flag_exact_duplicate = 0
 AND flag_outside_brazil = 0;

SELECT
    COUNT(*) AS clean_geo_rows,
    COUNT(*) FILTER (
        WHERE geolocation_lat < -35
           OR geolocation_lat > 6
           OR geolocation_lng < -75
           OR geolocation_lng > -30
    ) AS remaining_outside_brazil
FROM vw_geolocation_clean;

-- Vérification des doublons restants

SELECT COUNT(*) AS duplicate_groups
FROM (
    SELECT
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    FROM vw_geolocation_clean
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    HAVING COUNT(*) > 1
) duplicates;

-- =========================================================
-- 3. Nettoyage des commandes
-- =========================================================

CREATE OR REPLACE VIEW vw_orders_clean AS
SELECT
    q.*,
    order_purchase_timestamp::timestamp
        AS clean_purchase_timestamp,
    order_approved_at::timestamp
        AS clean_approved_at,
    CASE
        WHEN flag_carrier_before_approval = 1
        THEN NULL
        ELSE order_delivered_carrier_date::timestamp
    END AS clean_carrier_date,
    CASE
        WHEN flag_delivery_before_carrier = 1
          OR flag_delivery_before_approval = 1
        THEN NULL
        ELSE order_delivered_customer_date::timestamp
    END AS clean_customer_delivery_date,
    order_estimated_delivery_date::timestamp
        AS clean_estimated_delivery_date,
    CASE
        WHEN flag_carrier_before_approval = 1
          OR flag_delivery_before_carrier = 1
          OR flag_delivery_before_approval = 1
        THEN 0
        ELSE 1
    END AS is_timeline_valid
FROM vw_orders_quality q;

-- Vérification de la vue commandes nettoyées

SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (
        WHERE is_timeline_valid = 0
    ) AS invalid_timelines,
    COUNT(*) FILTER (
        WHERE order_delivered_carrier_date IS NOT NULL
          AND clean_carrier_date IS NULL
    ) AS cleaned_carrier_dates,
    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NOT NULL
          AND clean_customer_delivery_date IS NULL
    ) AS cleaned_delivery_dates
FROM vw_orders_clean;

-- Commandes avec remise au transporteur avant approbation
-- et au moins une incohérence liée à la livraison
SELECT COUNT(*) AS overlapping_orders
FROM vw_orders_quality
WHERE flag_carrier_before_approval = 1
  AND (
        flag_delivery_before_carrier = 1
        OR flag_delivery_before_approval = 1
      );

-- =========================================================
-- 4. Nettoyage des avis
-- =========================================================

CREATE OR REPLACE VIEW vw_reviews_clean AS
SELECT
    q.*,
    CASE
        WHEN flag_review_before_delivery = 1
        THEN NULL
        ELSE review_creation_date::timestamp
    END AS clean_review_creation_date,
    CASE
        WHEN flag_review_before_delivery = 1
        THEN 0
        WHEN flag_review_before_delivery = 0
        THEN 1
        ELSE NULL
    END AS is_review_timeline_valid
FROM vw_reviews_quality q;

-- Vérification du nettoyage des avis

SELECT
    COUNT(*) AS total_reviews,
    COUNT(*) FILTER (
        WHERE is_review_timeline_valid = 1
    ) AS valid_reviews,
    COUNT(*) FILTER (
        WHERE is_review_timeline_valid = 0
    ) AS invalid_reviews,
    COUNT(*) FILTER (
        WHERE is_review_timeline_valid IS NULL
    ) AS uncheckable_reviews,
    COUNT(*) FILTER (
        WHERE review_creation_date IS NOT NULL
          AND clean_review_creation_date IS NULL
    ) AS cleaned_review_dates
FROM vw_reviews_clean;

-- =========================================================
-- 5. Nettoyage des paiements
-- =========================================================

CREATE OR REPLACE VIEW vw_payments_clean AS
SELECT
    q.order_id,
    q.payment_sequential,
    CASE
        WHEN q.payment_type = 'not_defined'
        THEN 'unknown'
        ELSE q.payment_type
    END AS payment_type,
    NULLIF(q.payment_installments, 0)
        AS payment_installments,
    q.payment_value,
    q.flag_zero_payment,
    q.flag_zero_installments,
    q.flag_payment_type_not_defined
FROM vw_payments_quality q;

-- Vérification du nettoyage des paiements

SELECT
    COUNT(*) AS total_payment_rows,
    COUNT(*) FILTER (
        WHERE payment_type = 'not_defined'
    ) AS remaining_not_defined,
    COUNT(*) FILTER (
        WHERE payment_type = 'unknown'
    ) AS unknown_payment_types,
    COUNT(*) FILTER (
        WHERE payment_installments = 0
    ) AS remaining_zero_installments,
    COUNT(*) FILTER (
        WHERE payment_installments IS NULL
    ) AS null_installments,
    COUNT(*) FILTER (
        WHERE payment_value = 0
    ) AS zero_payments
FROM vw_payments_clean;

-- =========================================================
-- 6. Préparation des montants par commande
-- =========================================================

CREATE OR REPLACE VIEW vw_order_financial_clean AS
SELECT
    q.order_id,
    q.total_paid,
    q.total_items,
    q.payment_difference,
    q.flag_payment_difference,
    CASE
        WHEN q.flag_payment_difference = 0
        THEN q.total_paid
        ELSE NULL
    END AS validated_total_paid
FROM vw_order_payment_quality q;

-- Vérification des montants validés

SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (
        WHERE flag_payment_difference = 0
    ) AS consistent_orders,
    COUNT(*) FILTER (
        WHERE flag_payment_difference = 1
    ) AS inconsistent_orders,
    COUNT(validated_total_paid) AS validated_payment_totals,
    COUNT(*) FILTER (
        WHERE validated_total_paid IS null
    ) AS invalidated_payment_totals
FROM vw_order_financial_clean;

-- =========================================================
-- 7. Contrôle final des vues clean
-- =========================================================

SELECT
    (SELECT COUNT(*) FROM vw_products_clean) AS products_rows,
    (SELECT COUNT(*) FROM vw_geolocation_clean) AS geolocation_rows,
    (SELECT COUNT(*) FROM vw_orders_clean) AS orders_rows,
    (SELECT COUNT(*) FROM vw_reviews_clean) AS reviews_rows,
    (SELECT COUNT(*) FROM vw_payments_clean) AS payment_rows,
    (SELECT COUNT(*) FROM vw_order_financial_clean) AS financial_orders;

-- Contrôle des principales règles de nettoyage

SELECT
    (SELECT COUNT(*)
     FROM vw_products_clean
     WHERE product_weight_g = 0) AS remaining_zero_weights,
    (SELECT COUNT(*)
     FROM vw_geolocation_clean
     WHERE geolocation_lat < -35
        OR geolocation_lat > 6
        OR geolocation_lng < -75
        OR geolocation_lng > -30) AS remaining_outside_brazil,
    (SELECT COUNT(*)
     FROM vw_payments_clean
     WHERE payment_type = 'not_defined') AS remaining_not_defined,
    (SELECT COUNT(*)
     FROM vw_payments_clean
     WHERE payment_installments = 0) AS remaining_zero_installments,
    (SELECT COUNT(*)
     FROM vw_order_financial_clean
     WHERE flag_payment_difference = 1
       AND validated_total_paid IS NOT NULL) AS invalid_financial_validation;