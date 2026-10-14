-- 01_data_profiling.sql
-- Olist - Data Profiling
-- Requêtes utilisées pendant le profiling dans DBeaver.
-- Les requêtes ratées / doublons de test ne sont pas conservés ici.

-- =========================================================
-- 1. stg_orders
-- =========================================================

-- Aperçu des commandes
SELECT *
FROM stg_orders
LIMIT 10;

-- Répartition des commandes par statut
SELECT
    order_status,
    COUNT(*) AS number_of_orders
FROM stg_orders
GROUP BY order_status
ORDER BY number_of_orders DESC;

-- Volume et unicité
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_order_ids,
    COUNT(DISTINCT customer_id) AS unique_customer_ids
FROM stg_orders;

-- Période couverte par le dataset
SELECT
    MIN(order_purchase_timestamp::timestamp) AS min_purchase_date,
    MAX(order_purchase_timestamp::timestamp) AS max_purchase_date
FROM stg_orders;

-- Valeurs manquantes
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(order_id) AS null_order_id,
    COUNT(*) - COUNT(customer_id) AS null_customer_id,
    COUNT(*) - COUNT(order_status) AS null_order_status,
    COUNT(*) - COUNT(order_purchase_timestamp) AS null_purchase_timestamp,
    COUNT(*) - COUNT(order_approved_at) AS null_approved_at,
    COUNT(*) - COUNT(order_delivered_carrier_date) AS null_delivered_carrier_date,
    COUNT(*) - COUNT(order_delivered_customer_date) AS null_delivered_customer_date,
    COUNT(*) - COUNT(order_estimated_delivery_date) AS null_estimated_delivery_date
FROM stg_orders;

-- Valeurs manquantes par statut
SELECT
    order_status,
    COUNT(*) AS total_orders,
    COUNT(*) - COUNT(order_approved_at) AS null_approved_at,
    COUNT(*) - COUNT(order_delivered_carrier_date) AS null_delivered_carrier_date,
    COUNT(*) - COUNT(order_delivered_customer_date) AS null_delivered_customer_date
FROM stg_orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- Commandes delivered sans date de livraison client
SELECT *
FROM stg_orders
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- Commandes delivered sans date de remise au transporteur
SELECT *
FROM stg_orders
WHERE order_status = 'delivered'
  AND order_delivered_carrier_date IS NULL;

-- Approbation avant achat
SELECT COUNT(*) AS approval_before_purchase
FROM stg_orders
WHERE order_approved_at IS NOT NULL
  AND order_approved_at::timestamp < order_purchase_timestamp::timestamp;

-- Remise au transporteur avant approbation
SELECT COUNT(*) AS carrier_before_approval
FROM stg_orders
WHERE order_delivered_carrier_date IS NOT NULL
  AND order_approved_at IS NOT NULL
  AND order_delivered_carrier_date::timestamp < order_approved_at::timestamp;

-- Répartition de l'écart lorsque le transporteur précède l'approbation
SELECT
    CASE
        WHEN order_approved_at::timestamp - order_delivered_carrier_date::timestamp <= INTERVAL '5 minutes'
            THEN '0-5 min'
        WHEN order_approved_at::timestamp - order_delivered_carrier_date::timestamp <= INTERVAL '1 hour'
            THEN '5 min-1 h'
        WHEN order_approved_at::timestamp - order_delivered_carrier_date::timestamp <= INTERVAL '1 day'
            THEN '1 h-1 jour'
        WHEN order_approved_at::timestamp - order_delivered_carrier_date::timestamp <= INTERVAL '7 days'
            THEN '1-7 jours'
        ELSE '> 7 jours'
    END AS gap_group,
    COUNT(*) AS occurrences
FROM stg_orders
WHERE order_delivered_carrier_date IS NOT NULL
  AND order_approved_at IS NOT NULL
  AND order_delivered_carrier_date::timestamp < order_approved_at::timestamp
GROUP BY gap_group
ORDER BY MIN(order_approved_at::timestamp - order_delivered_carrier_date::timestamp);

-- Livraison client avant remise au transporteur
SELECT COUNT(*) AS customer_before_carrier
FROM stg_orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date::timestamp < order_delivered_carrier_date::timestamp;

-- Détail des livraisons client avant transporteur
SELECT
    order_id,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_delivered_carrier_date::timestamp
        - order_delivered_customer_date::timestamp AS gap
FROM stg_orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_carrier_date IS NOT NULL
  AND order_delivered_customer_date::timestamp < order_delivered_carrier_date::timestamp
ORDER BY gap DESC;

-- Livraison client avant achat
SELECT COUNT(*) AS customer_before_purchase
FROM stg_orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_delivered_customer_date::timestamp < order_purchase_timestamp::timestamp;

-- Livraison client avant approbation
SELECT COUNT(*) AS customer_before_approval
FROM stg_orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_approved_at IS NOT NULL
  AND order_delivered_customer_date::timestamp < order_approved_at::timestamp;

-- Répartition de l'écart lorsque la livraison client précède l'approbation
SELECT
    CASE
        WHEN order_approved_at::timestamp - order_delivered_customer_date::timestamp <= INTERVAL '5 minutes'
            THEN '0-5 min'
        WHEN order_approved_at::timestamp - order_delivered_customer_date::timestamp <= INTERVAL '1 hour'
            THEN '5 min-1 h'
        WHEN order_approved_at::timestamp - order_delivered_customer_date::timestamp <= INTERVAL '1 day'
            THEN '1 h-1 jour'
        WHEN order_approved_at::timestamp - order_delivered_customer_date::timestamp <= INTERVAL '7 days'
            THEN '1-7 jours'
        ELSE '> 7 jours'
    END AS gap_group,
    COUNT(*) AS occurrences
FROM stg_orders
WHERE order_delivered_customer_date IS NOT NULL
  AND order_approved_at IS NOT NULL
  AND order_delivered_customer_date::timestamp < order_approved_at::timestamp
GROUP BY gap_group
ORDER BY MIN(order_approved_at::timestamp - order_delivered_customer_date::timestamp);


-- =========================================================
-- 2. stg_order_items
-- =========================================================

-- Aperçu des lignes de commande
SELECT *
FROM stg_order_items
LIMIT 10;

-- Volume des lignes de commande
SELECT
    COUNT(*) AS total_order_items,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT product_id) AS unique_products,
    COUNT(DISTINCT seller_id) AS unique_sellers
FROM stg_order_items;

-- Commandes sans ligne dans order_items selon leur statut
SELECT
    o.order_status,
    COUNT(*) AS number_of_orders
FROM stg_orders o
LEFT JOIN stg_order_items oi
    ON o.order_id = oi.order_id
WHERE oi.order_id IS NULL
GROUP BY o.order_status
ORDER BY number_of_orders DESC;

-- Vérification de l'unicité des lignes de commande
SELECT
    order_id,
    order_item_id,
    COUNT(*) AS occurrences
FROM stg_order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

-- Valeurs manquantes
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(order_id) AS null_order_id,
    COUNT(*) - COUNT(order_item_id) AS null_order_item_id,
    COUNT(*) - COUNT(product_id) AS null_product_id,
    COUNT(*) - COUNT(seller_id) AS null_seller_id,
    COUNT(*) - COUNT(shipping_limit_date) AS null_shipping_limit_date,
    COUNT(*) - COUNT(price) AS null_price,
    COUNT(*) - COUNT(freight_value) AS null_freight_value
FROM stg_order_items;

-- Montants négatifs
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE price < 0) AS negative_prices,
    COUNT(*) FILTER (WHERE freight_value < 0) AS negative_freight_values
FROM stg_order_items;

-- Statistiques sur les prix et les frais de livraison
SELECT
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    AVG(price) AS avg_price,
    MIN(freight_value) AS min_freight,
    MAX(freight_value) AS max_freight,
    AVG(freight_value) AS avg_freight
FROM stg_order_items;

-- Articles avec les prix les plus élevés
SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    price,
    freight_value
FROM stg_order_items
ORDER BY price DESC
LIMIT 10;

-- Catégories des articles les plus chers
SELECT
    oi.order_id,
    oi.product_id,
    p.product_category_name,
    oi.price,
    oi.freight_value
FROM stg_order_items oi
LEFT JOIN stg_products p
    ON oi.product_id = p.product_id
ORDER BY oi.price DESC
LIMIT 10;

-- Articles avec les frais de livraison les plus élevés
SELECT
    order_id,
    product_id,
    seller_id,
    price,
    freight_value
FROM stg_order_items
ORDER BY freight_value DESC
LIMIT 10;

-- Caractéristiques des produits avec les frais de livraison les plus élevés
SELECT
    oi.order_id,
    oi.product_id,
    p.product_category_name,
    oi.price,
    oi.freight_value,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm
FROM stg_order_items oi
LEFT JOIN stg_products p
    ON oi.product_id = p.product_id
ORDER BY oi.freight_value DESC
LIMIT 10;

-- Commandes avec le plus d'articles
SELECT
    order_id,
    COUNT(*) AS number_of_items
FROM stg_order_items
GROUP BY order_id
ORDER BY number_of_items DESC
LIMIT 10;

-- Produits sans correspondance
SELECT
    COUNT(*) AS missing_products
FROM stg_order_items oi
LEFT JOIN stg_products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

-- Vendeurs sans correspondance
SELECT
    COUNT(*) AS missing_sellers
FROM stg_order_items oi
LEFT JOIN stg_sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

-- Commandes sans correspondance
SELECT
    COUNT(*) AS missing_orders
FROM stg_order_items oi
LEFT JOIN stg_orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Dates limites d'expédition avant l'achat
SELECT
    COUNT(*) AS shipping_limit_before_purchase
FROM stg_order_items oi
INNER JOIN stg_orders o
    ON oi.order_id = o.order_id
WHERE oi.shipping_limit_date::timestamp
      < o.order_purchase_timestamp::timestamp;

-- Articles remis au transporteur après la date limite d'expédition
SELECT
    COUNT(*) AS late_shipments
FROM stg_order_items oi
INNER JOIN stg_orders o
    ON oi.order_id = o.order_id
WHERE o.order_delivered_carrier_date IS NOT NULL
  AND o.order_delivered_carrier_date::timestamp
      > oi.shipping_limit_date::timestamp;

-- Taux de lignes expédiées après la date limite
SELECT
    COUNT(*) AS comparable_items,
    COUNT(*) FILTER (
        WHERE o.order_delivered_carrier_date::timestamp
              > oi.shipping_limit_date::timestamp
    ) AS late_items,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE o.order_delivered_carrier_date::timestamp
                  > oi.shipping_limit_date::timestamp
        ) / COUNT(*),
        2
    ) AS late_item_rate
FROM stg_order_items oi
INNER JOIN stg_orders o
    ON oi.order_id = o.order_id
WHERE o.order_delivered_carrier_date IS NOT NULL;

-- Plus grands retards d'expédition
SELECT
    oi.order_id,
    oi.shipping_limit_date,
    o.order_delivered_carrier_date,
    o.order_delivered_carrier_date::timestamp
        - oi.shipping_limit_date::timestamp AS delay
FROM stg_order_items oi
INNER JOIN stg_orders o
    ON oi.order_id = o.order_id
WHERE o.order_delivered_carrier_date IS NOT NULL
  AND o.order_delivered_carrier_date::timestamp
      > oi.shipping_limit_date::timestamp
ORDER BY delay DESC
LIMIT 10;

-- Nombre de commandes distinctes avec retard d'expédition
SELECT
    COUNT(DISTINCT oi.order_id) AS late_orders
FROM stg_order_items oi
INNER JOIN stg_orders o
    ON oi.order_id = o.order_id
WHERE o.order_delivered_carrier_date IS NOT NULL
  AND o.order_delivered_carrier_date::timestamp
      > oi.shipping_limit_date::timestamp;

-- Retards inférieurs à 1 jour
SELECT COUNT(*) AS late_under_1_day
FROM stg_order_items oi
INNER JOIN stg_orders o
    ON oi.order_id = o.order_id
WHERE o.order_delivered_carrier_date::timestamp
      > oi.shipping_limit_date::timestamp
  AND o.order_delivered_carrier_date::timestamp
      - oi.shipping_limit_date::timestamp < INTERVAL '1 day';

-- Retards entre 1 et 3 jours
SELECT COUNT(*) AS late_1_to_3_days
FROM stg_order_items oi
INNER JOIN stg_orders o
    ON oi.order_id = o.order_id
WHERE o.order_delivered_carrier_date::timestamp
      > oi.shipping_limit_date::timestamp
  AND o.order_delivered_carrier_date::timestamp
      - oi.shipping_limit_date::timestamp >= INTERVAL '1 day'
  AND o.order_delivered_carrier_date::timestamp
      - oi.shipping_limit_date::timestamp < INTERVAL '3 days';

-- Retards entre 3 et 7 jours
SELECT COUNT(*) AS late_3_to_7_days
FROM stg_order_items oi
INNER JOIN stg_orders o
    ON oi.order_id = o.order_id
WHERE o.order_delivered_carrier_date::timestamp
      > oi.shipping_limit_date::timestamp
  AND o.order_delivered_carrier_date::timestamp
      - oi.shipping_limit_date::timestamp >= INTERVAL '3 days'
  AND o.order_delivered_carrier_date::timestamp
      - oi.shipping_limit_date::timestamp < INTERVAL '7 days';

-- Retards de 7 jours ou plus
SELECT COUNT(*) AS late_7_days_or_more
FROM stg_order_items oi
INNER JOIN stg_orders o
    ON oi.order_id = o.order_id
WHERE o.order_delivered_carrier_date::timestamp
      > oi.shipping_limit_date::timestamp
  AND o.order_delivered_carrier_date::timestamp
      - oi.shipping_limit_date::timestamp >= INTERVAL '7 days';


-- =========================================================
-- 3. stg_order_payments
-- =========================================================

-- Aperçu des paiements
SELECT *
FROM stg_order_payments
LIMIT 10;

-- Volume des paiements
SELECT
    COUNT(*) AS total_payments,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT payment_type) AS unique_payment_types
FROM stg_order_payments;

-- Commandes sans paiement
SELECT
    o.order_id,
    o.order_status
FROM stg_orders o
LEFT JOIN stg_order_payments p
    ON o.order_id = p.order_id
WHERE p.order_id IS NULL;

-- Répartition des moyens de paiement
SELECT
    payment_type,
    COUNT(*) AS number_of_payments
FROM stg_order_payments
GROUP BY payment_type
ORDER BY number_of_payments DESC;

-- Vérification de l'unicité des paiements
SELECT
    order_id,
    payment_sequential,
    COUNT(*) AS occurrences
FROM stg_order_payments
GROUP BY order_id, payment_sequential
HAVING COUNT(*) > 1;

-- Valeurs manquantes
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(order_id) AS null_order_id,
    COUNT(*) - COUNT(payment_sequential) AS null_payment_sequential,
    COUNT(*) - COUNT(payment_type) AS null_payment_type,
    COUNT(*) - COUNT(payment_installments) AS null_payment_installments,
    COUNT(*) - COUNT(payment_value) AS null_payment_value
FROM stg_order_payments;

-- Paiements de type not_defined
SELECT *
FROM stg_order_payments
WHERE payment_type = 'not_defined';

-- Nombre de paiements nuls ou négatifs
SELECT COUNT(*) AS non_positive_payments
FROM stg_order_payments
WHERE payment_value <= 0;

-- Détail des paiements nuls ou négatifs
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM stg_order_payments
WHERE payment_value <= 0
ORDER BY payment_value;

-- Tous les paiements des commandes contenant un paiement à 0
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM stg_order_payments
WHERE order_id IN (
    SELECT order_id
    FROM stg_order_payments
    WHERE payment_value = 0
)
ORDER BY order_id, payment_sequential;

-- Résumé des commandes contenant un paiement à 0
SELECT
    order_id,
    COUNT(*) AS payment_lines,
    SUM(payment_value) AS total_payment_value
FROM stg_order_payments
WHERE order_id IN (
    SELECT order_id
    FROM stg_order_payments
    WHERE payment_value = 0
)
GROUP BY order_id
ORDER BY total_payment_value;

-- Valeurs minimum et maximum du nombre d'échéances
SELECT
    MIN(payment_installments) AS min_installments,
    MAX(payment_installments) AS max_installments
FROM stg_order_payments;

-- Paiements avec 0 échéance
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM stg_order_payments
WHERE payment_installments = 0;

-- Tous les paiements des commandes avec 0 échéance
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM stg_order_payments
WHERE order_id IN (
    SELECT order_id
    FROM stg_order_payments
    WHERE payment_installments = 0
)
ORDER BY order_id, payment_sequential;

-- Répartition du nombre d'échéances
SELECT
    payment_installments,
    COUNT(*) AS number_of_payments
FROM stg_order_payments
GROUP BY payment_installments
ORDER BY payment_installments;

-- Nombre de commandes avec un paiement en 24 échéances
SELECT
    COUNT(DISTINCT order_id) AS orders_paid_in_24_installments
FROM stg_order_payments
WHERE payment_installments = 24;

-- Statistiques sur les montants des paiements
SELECT
    MIN(payment_value) AS min_payment,
    MAX(payment_value) AS max_payment,
    AVG(payment_value) AS avg_payment
FROM stg_order_payments;

-- Paiements avec les montants les plus élevés
SELECT
    order_id,
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM stg_order_payments
ORDER BY payment_value DESC
LIMIT 10;

-- Articles de la commande avec le paiement le plus élevé
SELECT
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.price,
    oi.freight_value
FROM stg_order_items oi
WHERE oi.order_id = (
    SELECT order_id
    FROM stg_order_payments
    ORDER BY payment_value DESC
    LIMIT 1
)
ORDER BY oi.order_item_id;

-- Paiements sans commande correspondante
SELECT
    COUNT(*) AS missing_orders
FROM stg_order_payments p
LEFT JOIN stg_orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Montant total payé par commande
SELECT
    order_id,
    SUM(payment_value) AS total_paid
FROM stg_order_payments
GROUP BY order_id
ORDER BY total_paid DESC
LIMIT 10;

-- Comparaison montant payé / articles + frais
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
    i.total_items
FROM payment_totals p
INNER JOIN item_totals i
    ON p.order_id = i.order_id
LIMIT 10;

-- Nombre de commandes avec un écart de plus de 0,01
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
    COUNT(*) AS inconsistent_orders
FROM payment_totals p
INNER JOIN item_totals i
    ON p.order_id = i.order_id
WHERE ABS(p.total_paid - i.total_items) > 0.01;

-- Plus grandes différences entre paiement et articles
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
    p.total_paid - i.total_items AS difference
FROM payment_totals p
INNER JOIN item_totals i
    ON p.order_id = i.order_id
WHERE ABS(p.total_paid - i.total_items) > 0.01
ORDER BY ABS(p.total_paid - i.total_items) DESC
LIMIT 10;

-- Détail des paiements de la commande avec le plus gros écart
SELECT
    payment_sequential,
    payment_type,
    payment_installments,
    payment_value
FROM stg_order_payments
WHERE order_id = 'ce6d150fb29ada17d2082f4847107665'
ORDER BY payment_sequential;

-- Détail des articles de la commande avec le plus gros écart
SELECT
    order_item_id,
    product_id,
    seller_id,
    price,
    freight_value,
    price + freight_value AS item_total
FROM stg_order_items
WHERE order_id = 'ce6d150fb29ada17d2082f4847107665'
ORDER BY order_item_id;

-- Statut de la commande avec le plus gros écart
SELECT
    order_id,
    order_status
FROM stg_orders
WHERE order_id = 'ce6d150fb29ada17d2082f4847107665';

-- Répartition des commandes avec écart selon leur statut
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
    o.order_status,
    COUNT(*) AS inconsistent_orders
FROM payment_totals p
INNER JOIN item_totals i
    ON p.order_id = i.order_id
INNER JOIN stg_orders o
    ON p.order_id = o.order_id
WHERE ABS(p.total_paid - i.total_items) > 0.01
GROUP BY o.order_status
ORDER BY inconsistent_orders DESC;

-- Moyens de paiement présents parmi les commandes avec écart
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
),
inconsistent_orders AS (
    SELECT
        p.order_id
    FROM payment_totals p
    INNER JOIN item_totals i
        ON p.order_id = i.order_id
    WHERE ABS(p.total_paid - i.total_items) > 0.01
)
SELECT
    pay.payment_type,
    COUNT(DISTINCT pay.order_id) AS number_of_orders
FROM stg_order_payments pay
INNER JOIN inconsistent_orders inc
    ON pay.order_id = inc.order_id
GROUP BY pay.payment_type
ORDER BY number_of_orders DESC;

-- Répartition des commandes avec écart selon le nombre d'échéances
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
),
inconsistent_orders AS (
    SELECT
        p.order_id
    FROM payment_totals p
    INNER JOIN item_totals i
        ON p.order_id = i.order_id
    WHERE ABS(p.total_paid - i.total_items) > 0.01
),
installments_by_order AS (
    SELECT
        order_id,
        MAX(payment_installments) AS max_installments
    FROM stg_order_payments
    GROUP BY order_id
)
SELECT
    CASE
        WHEN ins.max_installments > 1 THEN 'plusieurs échéances'
        ELSE '1 échéance ou moins'
    END AS installment_group,
    COUNT(*) AS number_of_orders
FROM inconsistent_orders inc
INNER JOIN installments_by_order ins
    ON inc.order_id = ins.order_id
GROUP BY installment_group;

-- Taux d'écart selon le nombre d'échéances
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
),
orders_analysis AS (
    SELECT
        p.order_id,
        MAX(pay.payment_installments) AS max_installments,
        CASE
            WHEN ABS(p.total_paid - i.total_items) > 0.01 THEN 1
            ELSE 0
        END AS is_inconsistent
    FROM payment_totals p
    INNER JOIN item_totals i
        ON p.order_id = i.order_id
    INNER JOIN stg_order_payments pay
        ON p.order_id = pay.order_id
    GROUP BY p.order_id, p.total_paid, i.total_items
)
SELECT
    CASE
        WHEN max_installments > 1 THEN 'plusieurs échéances'
        ELSE '1 échéance ou moins'
    END AS installment_group,
    COUNT(*) AS total_orders,
    SUM(is_inconsistent) AS inconsistent_orders,
    ROUND(
        100.0 * SUM(is_inconsistent) / COUNT(*),
        2
    ) AS inconsistent_rate
FROM orders_analysis
GROUP BY installment_group;


-- =========================================================
-- 4. stg_customers
-- =========================================================

-- Aperçu des clients
SELECT *
FROM stg_customers
LIMIT 10;

-- Volume et identifiants clients
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM stg_customers;

-- Nombre de clients ayant plusieurs commandes
SELECT COUNT(*) AS repeat_customers
FROM (
    SELECT customer_unique_id
    FROM stg_customers
    GROUP BY customer_unique_id
    HAVING COUNT(*) > 1
) AS repeat_customers;

-- Valeurs manquantes
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(customer_id) AS null_customer_id,
    COUNT(*) - COUNT(customer_unique_id) AS null_customer_unique_id,
    COUNT(*) - COUNT(customer_zip_code_prefix) AS null_zip_code,
    COUNT(*) - COUNT(customer_city) AS null_city,
    COUNT(*) - COUNT(customer_state) AS null_state
FROM stg_customers;

-- Commandes sans client correspondant
SELECT
    COUNT(*) AS missing_customers
FROM stg_orders o
LEFT JOIN stg_customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Répartition des clients uniques par État
SELECT
    customer_state,
    COUNT(DISTINCT customer_unique_id) AS unique_customers
FROM stg_customers
GROUP BY customer_state
ORDER BY unique_customers DESC;

-- Vérification des codes d'État
SELECT
    customer_state,
    COUNT(*) AS occurrences
FROM stg_customers
GROUP BY customer_state
ORDER BY customer_state;


-- =========================================================
-- 5. stg_order_reviews
-- =========================================================

-- Aperçu des avis
SELECT *
FROM stg_order_reviews
LIMIT 10;

-- Volume des avis
SELECT
    COUNT(*) AS total_reviews,
    COUNT(DISTINCT review_id) AS unique_reviews,
    COUNT(DISTINCT order_id) AS unique_orders
FROM stg_order_reviews;

-- Review_id présents plusieurs fois
SELECT
    review_id,
    COUNT(*) AS occurrences,
    COUNT(DISTINCT order_id) AS unique_orders
FROM stg_order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 20;

-- Vérification de l'unicité review_id + order_id
SELECT
    review_id,
    order_id,
    COUNT(*) AS occurrences
FROM stg_order_reviews
GROUP BY review_id, order_id
HAVING COUNT(*) > 1;

-- Valeurs manquantes
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(review_id) AS null_review_id,
    COUNT(*) - COUNT(order_id) AS null_order_id,
    COUNT(*) - COUNT(review_score) AS null_review_score,
    COUNT(*) - COUNT(review_comment_title) AS null_comment_title,
    COUNT(*) - COUNT(review_comment_message) AS null_comment_message,
    COUNT(*) - COUNT(review_creation_date) AS null_creation_date,
    COUNT(*) - COUNT(review_answer_timestamp) AS null_answer_timestamp
FROM stg_order_reviews;

-- Vérification des notes d'avis
SELECT
    review_score,
    COUNT(*) AS occurrences
FROM stg_order_reviews
GROUP BY review_score
ORDER BY review_score;

-- Avis sans commande correspondante
SELECT
    COUNT(*) AS missing_orders
FROM stg_order_reviews r
LEFT JOIN stg_orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;

-- Réponse à l'avis avant la création de l'avis
SELECT
    COUNT(*) AS invalid_review_dates
FROM stg_order_reviews
WHERE review_answer_timestamp::timestamp
      < review_creation_date::timestamp;

-- Avis créés avant la livraison, comparaison timestamp
SELECT
    COUNT(*) AS reviews_before_delivery
FROM stg_order_reviews r
INNER JOIN stg_orders o
    ON r.order_id = o.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND r.review_creation_date::timestamp
      < o.order_delivered_customer_date::timestamp;

-- Avis créés un jour antérieur à la livraison
SELECT
    COUNT(*) AS reviews_before_delivery_date
FROM stg_order_reviews r
INNER JOIN stg_orders o
    ON r.order_id = o.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND r.review_creation_date::date
      < o.order_delivered_customer_date::date;

-- Plus grands écarts entre création de l'avis et livraison
SELECT
    r.order_id,
    r.review_creation_date,
    o.order_delivered_customer_date,
    o.order_delivered_customer_date::date
        - r.review_creation_date::date AS days_before_delivery
FROM stg_order_reviews r
INNER JOIN stg_orders o
    ON r.order_id = o.order_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND r.review_creation_date::date
      < o.order_delivered_customer_date::date
ORDER BY days_before_delivery DESC
LIMIT 10;


-- =========================================================
-- 6. stg_products
-- =========================================================

-- Aperçu des produits
SELECT *
FROM stg_products
LIMIT 10;

-- Volume et unicité des produits
SELECT
    COUNT(*) AS total_products,
    COUNT(DISTINCT product_id) AS unique_products
FROM stg_products;

-- Valeurs manquantes
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(product_id) AS null_product_id,
    COUNT(*) - COUNT(product_category_name) AS null_category,
    COUNT(*) - COUNT(product_name_lenght) AS null_name_length,
    COUNT(*) - COUNT(product_description_lenght) AS null_description_length,
    COUNT(*) - COUNT(product_photos_qty) AS null_photos_qty,
    COUNT(*) - COUNT(product_weight_g) AS null_weight,
    COUNT(*) - COUNT(product_length_cm) AS null_length,
    COUNT(*) - COUNT(product_height_cm) AS null_height,
    COUNT(*) - COUNT(product_width_cm) AS null_width
FROM stg_products;

-- Produits sans informations descriptives
SELECT
    COUNT(*) AS missing_product_info
FROM stg_products
WHERE product_category_name IS NULL
  AND product_name_lenght IS NULL
  AND product_description_lenght IS NULL
  AND product_photos_qty IS NULL;

-- Produits sans informations physiques
SELECT
    product_id,
    product_category_name,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM stg_products
WHERE product_weight_g IS NULL
   OR product_length_cm IS NULL
   OR product_height_cm IS NULL
   OR product_width_cm IS NULL;

-- Valeurs physiques nulles ou négatives
SELECT
    COUNT(*) FILTER (WHERE product_weight_g <= 0) AS invalid_weight,
    COUNT(*) FILTER (WHERE product_length_cm <= 0) AS invalid_length,
    COUNT(*) FILTER (WHERE product_height_cm <= 0) AS invalid_height,
    COUNT(*) FILTER (WHERE product_width_cm <= 0) AS invalid_width
FROM stg_products;

-- Produits avec un poids invalide
SELECT
    product_id,
    product_category_name,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
FROM stg_products
WHERE product_weight_g <= 0;

-- Valeurs minimum et maximum des caractéristiques physiques
SELECT
    MIN(product_weight_g) AS min_weight,
    MAX(product_weight_g) AS max_weight,
    MIN(product_length_cm) AS min_length,
    MAX(product_length_cm) AS max_length,
    MIN(product_height_cm) AS min_height,
    MAX(product_height_cm) AS max_height,
    MIN(product_width_cm) AS min_width,
    MAX(product_width_cm) AS max_width
FROM stg_products;


-- =========================================================
-- 7. stg_sellers
-- =========================================================

-- Aperçu des vendeurs
SELECT *
FROM stg_sellers
LIMIT 10;

-- Volume et unicité des vendeurs
SELECT
    COUNT(*) AS total_sellers,
    COUNT(DISTINCT seller_id) AS unique_sellers
FROM stg_sellers;

-- Valeurs manquantes
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(seller_id) AS null_seller_id,
    COUNT(*) - COUNT(seller_zip_code_prefix) AS null_zip_code,
    COUNT(*) - COUNT(seller_city) AS null_city,
    COUNT(*) - COUNT(seller_state) AS null_state
FROM stg_sellers;

-- Vérification des codes d'État des vendeurs
SELECT
    seller_state,
    COUNT(*) AS occurrences
FROM stg_sellers
GROUP BY seller_state
ORDER BY seller_state;


-- =========================================================
-- 8. stg_geolocation
-- =========================================================

-- Aperçu des données géographiques
SELECT *
FROM stg_geolocation
LIMIT 10;

-- Volume de stg_geolocation
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT geolocation_zip_code_prefix) AS unique_zip_codes
FROM stg_geolocation;

-- Valeurs manquantes
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(geolocation_zip_code_prefix) AS null_zip_code,
    COUNT(*) - COUNT(geolocation_lat) AS null_lat,
    COUNT(*) - COUNT(geolocation_lng) AS null_lng,
    COUNT(*) - COUNT(geolocation_city) AS null_city,
    COUNT(*) - COUNT(geolocation_state) AS null_state
FROM stg_geolocation;

-- Doublons exacts les plus fréquents
SELECT
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state,
    COUNT(*) AS occurrences
FROM stg_geolocation
GROUP BY
    geolocation_zip_code_prefix,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 20;

-- Nombre de groupes de doublons et de lignes supplémentaires
WITH duplicate_groups AS (
    SELECT
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state,
        COUNT(*) AS occurrences
    FROM stg_geolocation
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(*) AS duplicate_groups,
    SUM(occurrences - 1) AS duplicate_rows
FROM duplicate_groups;

-- Validité mondiale des coordonnées
SELECT
    COUNT(*) FILTER (
        WHERE geolocation_lat < -90
           OR geolocation_lat > 90
    ) AS invalid_lat,
    COUNT(*) FILTER (
        WHERE geolocation_lng < -180
           OR geolocation_lng > 180
    ) AS invalid_lng
FROM stg_geolocation;

-- Minimum et maximum des coordonnées
SELECT
    MIN(geolocation_lat) AS min_lat,
    MAX(geolocation_lat) AS max_lat,
    MIN(geolocation_lng) AS min_lng,
    MAX(geolocation_lng) AS max_lng
FROM stg_geolocation;

-- Nombre de coordonnées potentiellement situées hors du Brésil
SELECT COUNT(*) AS coordinates_outside_brazil
FROM stg_geolocation
WHERE geolocation_lat < -35
   OR geolocation_lat > 6
   OR geolocation_lng < -75
   OR geolocation_lng > -30;

-- Détail des coordonnées potentiellement situées hors du Brésil
SELECT *
FROM stg_geolocation
WHERE geolocation_lat < -35
   OR geolocation_lat > 6
   OR geolocation_lng < -75
   OR geolocation_lng > -30;

-- Vérification des codes d'État
SELECT
    geolocation_state,
    COUNT(*) AS occurrences
FROM stg_geolocation
GROUP BY geolocation_state
ORDER BY geolocation_state;


-- =========================================================
-- 9. stg_product_category_name_translation
-- =========================================================

-- Aperçu de la table de traduction
SELECT *
FROM stg_product_category_name_translation
LIMIT 10;

-- Volume et unicité des traductions
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT product_category_name) AS unique_categories,
    COUNT(DISTINCT product_category_name_english) AS unique_english_categories
FROM stg_product_category_name_translation;

-- Valeurs manquantes
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(product_category_name) AS null_category,
    COUNT(*) - COUNT(product_category_name_english) AS null_english_category
FROM stg_product_category_name_translation;

-- Nombre de catégories produits sans traduction anglaise
SELECT
    COUNT(DISTINCT p.product_category_name) AS categories_without_translation
FROM stg_products p
LEFT JOIN stg_product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL;

-- Catégories sans traduction anglaise
SELECT DISTINCT
    p.product_category_name
FROM stg_products p
LEFT JOIN stg_product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
ORDER BY p.product_category_name;
