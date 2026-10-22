SELECT
    current_database(),
    current_schema();

-- =========================================================
-- 1. Vue d'ensemble des commandes
-- =========================================================

SELECT
    COUNT(*) AS total_orders,
    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
    ) AS delivered_orders,
    COUNT(*) FILTER (
        WHERE order_status = 'canceled'
    ) AS canceled_orders,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE order_status = 'canceled'
        ) / COUNT(*),
        2
    ) AS cancellation_rate
FROM fact_orders;

-- =========================================================
-- 2. Ventes et panier moyen
-- =========================================================

SELECT
    ROUND(SUM(i.price)::numeric, 2) AS product_revenue,
    ROUND(SUM(i.freight_value)::numeric, 2) AS total_freight,
    ROUND(SUM(i.item_total_amount)::numeric, 2) AS gross_order_value,
    ROUND(
        SUM(i.item_total_amount)::numeric
        / COUNT(DISTINCT i.order_id),
        2
    ) AS average_order_value
FROM fact_order_items i
INNER JOIN fact_orders o
    ON i.order_id = o.order_id
WHERE o.order_status = 'delivered';

-- Montants payés validés sur les commandes livrées

SELECT
    COUNT(*) AS delivered_orders,
    COUNT(validated_total_paid) AS validated_financial_orders,
    ROUND(
        SUM(validated_total_paid)::numeric,
        2
    ) AS validated_paid_amount,
    ROUND(
        AVG(validated_total_paid)::numeric,
        2
    ) AS average_validated_paid_amount
FROM fact_orders
WHERE order_status = 'delivered';

-- Comparaison sur les commandes financièrement validées

SELECT
    COUNT(*) AS validated_delivered_orders,
    ROUND(
        SUM(total_items)::numeric,
        2
    ) AS validated_order_value,
    ROUND(
        SUM(validated_total_paid)::numeric,
        2
    ) AS validated_paid_amount,
    ROUND(
        (
            SUM(validated_total_paid)
            - SUM(total_items)
        )::numeric,
        2
    ) AS remaining_difference
FROM fact_orders
WHERE order_status = 'delivered'
  AND validated_total_paid IS NOT NULL;

-- =========================================================
-- 3. Évolution temporelle des ventes et paiements
-- =========================================================

-- Valeur commerciale mensuelle des commandes
SELECT
    d.year_month,
    COUNT(DISTINCT i.order_id) AS total_orders,
    ROUND(
        SUM(i.item_total_amount)::numeric,
        2
    ) AS gross_order_value,
    ROUND(
        SUM(i.item_total_amount)::numeric
        / COUNT(DISTINCT i.order_id),
        2
    ) AS average_order_value
FROM fact_order_items i
INNER JOIN fact_orders o
    ON i.order_id = o.order_id
INNER JOIN dim_date d
    ON i.purchase_date_id = d.date_id
WHERE o.order_status = 'delivered'
GROUP BY d.year_month
ORDER BY d.year_month;

-- Paiements validés par mois
SELECT
    d.year_month,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    COUNT(o.validated_total_paid) AS validated_financial_orders,
    ROUND(
        SUM(o.validated_total_paid)::numeric,
        2
    ) AS validated_paid_amount,
    ROUND(
        AVG(o.validated_total_paid)::numeric,
        2
    ) AS average_validated_order_value
FROM fact_orders o
INNER JOIN dim_date d
    ON o.purchase_date_id = d.date_id
WHERE o.order_status = 'delivered'
GROUP BY d.year_month
ORDER BY d.year_month;

-- Paiements validés par année
SELECT
    d.year,
    COUNT(DISTINCT o.order_id) AS delivered_orders,
    COUNT(o.validated_total_paid) AS validated_financial_orders,
    ROUND(
        SUM(o.validated_total_paid)::numeric,
        2
    ) AS validated_paid_amount,
    ROUND(
        AVG(o.validated_total_paid)::numeric,
        2
    ) AS average_validated_order_value
FROM fact_orders o
INNER JOIN dim_date d
    ON o.purchase_date_id = d.date_id
WHERE o.order_status = 'delivered'
GROUP BY d.year
ORDER BY d.year;

-- =========================================================
-- 4. Produits, catégories et vendeurs
-- =========================================================

-- Top catégories par valeur commerciale
SELECT
    p.product_category_name,
    COUNT(*) AS items_sold,
    COUNT(DISTINCT i.order_id) AS total_orders,
    ROUND(
        SUM(i.price)::numeric,
        2
    ) AS product_value,
    ROUND(
        SUM(i.freight_value)::numeric,
        2
    ) AS freight_value,
    ROUND(
        SUM(i.item_total_amount)::numeric,
        2
    ) AS gross_order_value
FROM fact_order_items i
INNER JOIN fact_orders o
    ON i.order_id = o.order_id
INNER JOIN dim_products p
    ON i.product_id = p.product_id
WHERE o.order_status = 'delivered'
AND o.validated_total_paid IS NOT NULL
GROUP BY p.product_category_name
ORDER BY gross_order_value DESC
LIMIT 10;


-- Top vendeurs par valeur commerciale
-- Commandes livrées et financièrement validées
SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(*) AS items_sold,
    COUNT(DISTINCT i.order_id) AS total_orders,
    ROUND(
        SUM(i.price)::numeric,
        2
    ) AS product_value,
    ROUND(
        SUM(i.freight_value)::numeric,
        2
    ) AS freight_value,
    ROUND(
        SUM(i.item_total_amount)::numeric,
        2
    ) AS gross_order_value
FROM fact_order_items i
INNER JOIN fact_orders o
    ON i.order_id = o.order_id
INNER JOIN dim_sellers s
    ON i.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
  AND o.validated_total_paid IS NOT NULL
GROUP BY
    s.seller_id,
    s.seller_city,
    s.seller_state
ORDER BY gross_order_value DESC
LIMIT 10;


-- Valeur commerciale par État vendeur
-- Commandes livrées et financièrement validées

SELECT
    s.seller_state,
    COUNT(DISTINCT s.seller_id) AS total_sellers,
    COUNT(*) AS items_sold,
    COUNT(DISTINCT i.order_id) AS total_orders,
    ROUND(
        SUM(i.price)::numeric,
        2
    ) AS product_value,
    ROUND(
        SUM(i.freight_value)::numeric,
        2
    ) AS freight_value,
    ROUND(
        SUM(i.item_total_amount)::numeric,
        2
    ) AS gross_order_value
FROM fact_order_items i
INNER JOIN fact_orders o
    ON i.order_id = o.order_id
INNER JOIN dim_sellers s
    ON i.seller_id = s.seller_id
WHERE o.order_status = 'delivered'
  AND o.validated_total_paid IS NOT NULL
GROUP BY s.seller_state
ORDER BY gross_order_value DESC;

-- ---------------------------------------------------------
-- 4.4 Part de la valeur commerciale par État vendeur
-- ---------------------------------------------------------

WITH state_sales AS (
    SELECT
        s.seller_state,
        ROUND(
            SUM(i.item_total_amount)::numeric,
            2
        ) AS gross_order_value
    FROM fact_order_items i
    INNER JOIN fact_orders o
        ON i.order_id = o.order_id
    INNER JOIN dim_sellers s
        ON i.seller_id = s.seller_id
    WHERE o.order_status = 'delivered'
      AND o.validated_total_paid IS NOT NULL
    GROUP BY s.seller_state
)
SELECT
    seller_state,
    gross_order_value,
    ROUND(
        100.0 * gross_order_value
        / SUM(gross_order_value) OVER (),
        2
    ) AS share_of_total
FROM state_sales
ORDER BY gross_order_value DESC;

-- =========================================================
-- 5. Clients et fidélisation
-- =========================================================


-- Clients récurrents
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM fact_orders o
    INNER JOIN dim_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (
        WHERE total_orders = 1
    ) AS one_time_customers,
    COUNT(*) FILTER (
        WHERE total_orders > 1
    ) AS repeat_customers,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE total_orders > 1
        ) / COUNT(*),
        2
    ) AS repeat_customer_rate
FROM customer_orders;


-- 5.2 Nombre moyen de commandes par client
WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM fact_orders o
    INNER JOIN dim_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT
    ROUND(
        AVG(total_orders)::numeric,
        2
    ) AS average_orders_per_customer,
    MAX(total_orders) AS max_orders_by_customer
FROM customer_orders;

-- Valeur commerciale moyenne par client

WITH customer_value AS (
    SELECT
        c.customer_unique_id,
        SUM(i.item_total_amount) AS gross_order_value
    FROM fact_order_items i
    INNER JOIN fact_orders o
        ON i.order_id = o.order_id
    INNER JOIN dim_customers c
        ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
      AND o.validated_total_paid IS NOT NULL
    GROUP BY c.customer_unique_id
)
SELECT
    ROUND(
        AVG(gross_order_value)::numeric,
        2
    ) AS average_customer_value,
    ROUND(
        MAX(gross_order_value)::numeric,
        2
    ) AS max_customer_value
FROM customer_value;


-- Top 10 clients par valeur commerciale
SELECT
    c.customer_unique_id,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(
        SUM(i.item_total_amount)::numeric,
        2
    ) AS gross_order_value,
    ROUND(
        AVG(i.item_total_amount)::numeric,
        2
    ) AS average_item_value,
       ROUND(
        (
            SUM(i.item_total_amount)
            / COUNT(DISTINCT o.order_id)
        )::numeric,
        2
    ) AS average_order_value
FROM fact_order_items i
INNER JOIN fact_orders o
    ON i.order_id = o.order_id
INNER JOIN dim_customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.validated_total_paid IS NOT NULL
GROUP BY c.customer_unique_id
ORDER BY gross_order_value DESC
LIMIT 10;

-- =========================================================
-- 6. Livraison et performance opérationnelle
-- =========================================================


-- Délais et respect de la date estimée
SELECT
    COUNT(*) AS delivered_orders,
    COUNT(clean_customer_delivery_date)
        AS orders_with_valid_delivery_date,
    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    clean_customer_delivery_date
                    - clean_purchase_timestamp
                )
            ) / 86400
        )::numeric,
        2
    ) AS average_delivery_days,
    COUNT(*) FILTER (
        WHERE clean_customer_delivery_date
              <= clean_estimated_delivery_date
    ) AS on_time_orders,
    COUNT(*) FILTER (
        WHERE clean_customer_delivery_date
              > clean_estimated_delivery_date
    ) AS late_orders,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE clean_customer_delivery_date
                  > clean_estimated_delivery_date
        )
        / COUNT(clean_customer_delivery_date),
        2
    ) AS late_delivery_rate
FROM fact_orders
WHERE order_status = 'delivered';

-- Retard des commandes livrées en retard

SELECT
    COUNT(*) AS late_orders,
    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    clean_customer_delivery_date
                    - clean_estimated_delivery_date
                )
            ) / 86400
        )::numeric,
        2
    ) AS average_delay_days,
    ROUND(
        MAX(
            EXTRACT(
                EPOCH FROM (
                    clean_customer_delivery_date
                    - clean_estimated_delivery_date
                )
            ) / 86400
        )::numeric,
        2
    ) AS max_delay_days
FROM fact_orders
WHERE order_status = 'delivered'
  AND clean_customer_delivery_date IS NOT NULL
  AND clean_estimated_delivery_date IS NOT NULL
  AND clean_customer_delivery_date
      > clean_estimated_delivery_date;

-- Performance de livraison par État client

SELECT
    c.customer_state,
    COUNT(*) AS delivered_orders,
    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    o.clean_customer_delivery_date
                    - o.clean_purchase_timestamp
                )
            ) / 86400
        )::numeric,
        2
    ) AS average_delivery_days,
    COUNT(*) FILTER (
        WHERE o.clean_customer_delivery_date
              > o.clean_estimated_delivery_date
    ) AS late_orders,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE o.clean_customer_delivery_date
                  > o.clean_estimated_delivery_date
        )
        / COUNT(o.clean_customer_delivery_date),
        2
    ) AS late_delivery_rate
FROM fact_orders o
INNER JOIN dim_customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.clean_customer_delivery_date IS NOT NULL
  AND o.clean_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY late_delivery_rate DESC;

-- Performance de livraison par État
-- États avec au moins 500 commandes

SELECT
    c.customer_state,
    COUNT(*) AS delivered_orders,
    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    o.clean_customer_delivery_date
                    - o.clean_purchase_timestamp
                )
            ) / 86400
        )::numeric,
        2
    ) AS average_delivery_days,
    COUNT(*) FILTER (
        WHERE o.clean_customer_delivery_date
              > o.clean_estimated_delivery_date
    ) AS late_orders,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE o.clean_customer_delivery_date
                  > o.clean_estimated_delivery_date
        )
        / COUNT(*),
        2
    ) AS late_delivery_rate
FROM fact_orders o
INNER JOIN dim_customers c
    ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
  AND o.clean_customer_delivery_date IS NOT NULL
  AND o.clean_estimated_delivery_date IS NOT NULL
GROUP BY c.customer_state
HAVING COUNT(*) >= 500
ORDER BY late_delivery_rate DESC;

-- =========================================================
-- 7. Paiements
-- =========================================================

-- Répartition par moyen de paiement
SELECT
    p.payment_type,
    COUNT(*) AS payment_rows,
    COUNT(DISTINCT p.order_id) AS total_orders,
    ROUND(
        SUM(p.payment_value)::numeric,
        2
    ) AS total_payment_value,
    ROUND(
        AVG(p.payment_value)::numeric,
        2
    ) AS average_payment_value
FROM fact_payments p
INNER JOIN fact_orders o
    ON p.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.validated_total_paid IS NOT NULL
GROUP BY p.payment_type
ORDER BY total_payment_value DESC;

-- Part de chaque moyen de paiement
WITH payment_totals AS (
    SELECT
        p.payment_type,
        SUM(p.payment_value) AS total_payment_value
    FROM fact_payments p
    INNER JOIN fact_orders o
        ON p.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.validated_total_paid IS NOT NULL
    GROUP BY p.payment_type
)
SELECT
    payment_type,
    ROUND(
        total_payment_value::numeric,
        2
    ) AS total_payment_value,
    ROUND(
         (
            100.0 * total_payment_value
            / SUM(total_payment_value) OVER ()
        )::numeric,
        2
    ) AS payment_share
FROM payment_totals
ORDER BY total_payment_value DESC;


-- Paiements en plusieurs fois
SELECT
    COUNT(*) AS payment_rows,
    COUNT(*) FILTER (
        WHERE payment_installments = 1
    ) AS single_installment_payments,
    COUNT(*) FILTER (
        WHERE payment_installments > 1
    ) AS multi_installment_payments,
    ROUND(
        AVG(payment_installments)::numeric,
        2
    ) AS average_installments,
    ROUND(
    100.0 * COUNT(*) FILTER (
        WHERE payment_installments > 1
    )
    / COUNT(*),
    2
) AS multi_installment_rate,
    MAX(payment_installments) AS max_installments
FROM fact_payments p
INNER JOIN fact_orders o
    ON p.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.validated_total_paid IS NOT NULL
  AND p.payment_installments IS NOT NULL;

-- =========================================================
-- 8. Satisfaction et avis clients
-- =========================================================

-- Satisfaction globale

SELECT
    COUNT(*) AS total_reviews,
    ROUND(
        AVG(review_score)::numeric,
        2
    ) AS average_review_score,
    COUNT(*) FILTER (
        WHERE review_score >= 4
    ) AS positive_reviews,
    COUNT(*) FILTER (
        WHERE review_score <= 2
    ) AS negative_reviews,
    ROUND(
        (
            100.0 * COUNT(*) FILTER (
                WHERE review_score >= 4
            )
            / COUNT(*)
        )::numeric,
        2
    ) AS positive_review_rate,
    ROUND(
        (
            100.0 * COUNT(*) FILTER (
                WHERE review_score <= 2
            )
            / COUNT(*)
        )::numeric,
        2
    ) AS negative_review_rate
FROM vw_reviews_clean;


-- Satisfaction selon le respect du délai de livraison
WITH delivery_reviews AS (
    SELECT
        r.review_score,
        CASE
            WHEN o.clean_customer_delivery_date
                 > o.clean_estimated_delivery_date
            THEN 'late'
            ELSE 'on_time'
        END AS delivery_status
    FROM vw_reviews_clean r
    INNER JOIN fact_orders o
        ON r.order_id = o.order_id
    WHERE o.order_status = 'delivered'
      AND o.clean_customer_delivery_date IS NOT NULL
      AND o.clean_estimated_delivery_date IS NOT NULL
)
SELECT
    delivery_status,
    COUNT(*) AS total_reviews,
    ROUND(
        AVG(review_score)::numeric,
        2
    ) AS average_review_score,
    ROUND(
        (
            100.0 * COUNT(*) FILTER (
                WHERE review_score >= 4
            )
            / COUNT(*)
        )::numeric,
        2
    ) AS positive_review_rate,
    ROUND(
        (
            100.0 * COUNT(*) FILTER (
                WHERE review_score <= 2
            )
            / COUNT(*)
        )::numeric,
        2
    ) AS negative_review_rate
FROM delivery_reviews
GROUP BY delivery_status
ORDER BY delivery_status;

-- =========================================================
-- 9. Synthèse finale des KPI
-- =========================================================

-- Commandes :
-- 99 441 commandes au total, dont 96 478 livrées.
-- Taux d'annulation : 0,63 %.

-- Valeur des commandes :
-- Valeur brute des commandes livrées : 15 419 773,75.
-- Montant payé validé : 15 349 784,01.
-- Panier moyen brut : 159,83.

-- Évolution mensuelle :
-- Le montant payé validé augmente fortement entre fin 2016 et 2018.
-- Les volumes mensuels deviennent nettement plus élevés à partir de 2017.
-- Les mois de début et de fin de dataset sont à interpréter avec prudence
-- car 2016 commence en septembre et 2018 s'arrête en octobre.

-- Montant payé validé par année :
-- 2016 : 45 794,18 (année partielle à partir de septembre).
-- 2017 : 6 893 028,66.
-- 2018 : 8 410 961,17 (année partielle jusqu'en octobre).
-- Attention : 2016 et 2018 sont incomplètes et ne doivent pas
-- être comparées directement à 2017 comme des années pleines.

-- Produits et vendeurs :
-- health_beauty est la catégorie avec la plus forte valeur commerciale.
-- Les vendeurs de l'État de SP représentent 64,54 % de la valeur commerciale.

-- Clients :
-- 93 358 clients ont au moins une commande livrée.
-- Seulement 3 % sont des clients récurrents.
-- Nombre moyen de commandes par client : 1,03.

-- Livraison :
-- Délai moyen de livraison : 12,56 jours.
-- Taux de retard : 8,12 %.
-- Retard moyen lorsqu'une commande est en retard : 9,55 jours.
-- Les performances de livraison varient fortement selon les États.

-- Paiements :
-- La carte bancaire représente 78,45 % du montant payé.
-- 49,34 % des paiements exploitables sont réalisés en plusieurs fois.
-- Nombre moyen d'échéances : 2,84.

-- Satisfaction :
-- Note moyenne : 4,09 / 5.
-- 77,07 % des avis sont positifs.
-- Note moyenne à l'heure : 4,29 / 5.
-- Note moyenne en retard : 2,57 / 5.
-- Les retards sont fortement associés à une baisse de satisfaction.

-- Principaux constats :
-- Faible fidélisation client.
-- Forte concentration des vendeurs dans l'État de SP.
-- Écarts importants de performance logistique entre les régions.
-- Forte association entre retard de livraison et insatisfaction client.

