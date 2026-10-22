Notes — Modèle analytique Olist

Cette étape vient après le profiling, les contrôles de qualité et le nettoyage.

L'objectif était de transformer les données propres en un modèle analytique plus simple à utiliser dans SQL et dans Power BI.

L'idée principale est de séparer :
les dimensions, qui décrivent les objets métier ;
les tables de faits, qui représentent les événements et les mesures.

1. Dimension produits — dim_products

Grain : 1 ligne = 1 produit.

Source : vw_products_clean.

Colonnes conservées :

product_id
product_category_name
product_name_length
product_description_length
product_photos_qty
product_weight_g
product_length_cm
product_height_cm
product_width_cm

Validation :
32 951 lignes ;
32 951 product_id uniques.

2. Dimension vendeurs — dim_sellers

Grain : 1 ligne = 1 vendeur.

Source : stg_sellers.

Aucune vue clean intermédiaire n'a été créée car le profiling n'avait pas identifié de correction nécessaire.

Colonnes conservées :
seller_id
seller_zip_code_prefix
seller_city
seller_state

Validation :
3 095 lignes ;
3 095 vendeurs uniques.

3. Dimension clients — dim_customers

Grain : 1 ligne = 1 customer_id.

Source : stg_customers.

Colonnes conservées :
customer_id
customer_unique_id
customer_zip_code_prefix
customer_city
customer_state

customer_id sert à relier une commande à un client.

customer_unique_id permet de reconnaître une même personne sur plusieurs commandes.

Validation :
99 441 lignes ;
99 441 customer_id uniques ;
96 096 customer_unique_id uniques.

4. Dimension dates — dim_date

Grain : 1 ligne = 1 jour.

La dimension est générée entre la première et la dernière date d'achat avec GENERATE_SERIES.

Période :
2016-09-04
2018-10-17

Colonnes principales :
date_id
full_date
year
quarter
month_number
month_name
year_month
day_of_month
day_of_week
is_weekend

Validation :
774 dates ;
774 date_id uniques.

5. Table de faits commandes — fact_orders

Grain : 1 ligne = 1 commande.

Cette vue part de vw_orders_clean et récupère les informations financières depuis vw_order_financial_clean.

Colonnes principales :
order_id
customer_id
order_status
purchase_date_id
clean_purchase_timestamp
clean_approved_at
clean_carrier_date
clean_customer_delivery_date
clean_estimated_delivery_date
is_timeline_valid
total_paid
total_items
validated_total_paid
flag_payment_difference

Un LEFT JOIN est utilisé afin de conserver toutes les commandes, même lorsqu'elles ne disposent pas de données financières comparables.

Validation :
99 441 commandes ;
99 441 order_id uniques ;
0 client manquant ;
0 date d'achat manquante ;
98 665 commandes avec données financières comparables ;
380 commandes avec un écart financier ;
98 285 montants financiers validés.

6. Table de faits articles — fact_order_items

Grain : 1 ligne = 1 article dans une commande.

Source principale : stg_order_items.

Colonnes principales :
order_id
order_item_id
product_id
seller_id
customer_id
purchase_date_id
shipping_limit_date
price
freight_value
item_total_amount
item_total_amount = price + freight_value.

Validation :
112 650 lignes ;
112 650 couples (order_id, order_item_id) uniques ;
0 produit manquant ;
0 vendeur manquant ;
0 client manquant ;
0 date d'achat manquante ;
0 prix négatif ;
0 fret négatif ;
0 montant total négatif.

7. Table de faits paiements — fact_payments

Grain : 1 ligne = 1 opération de paiement.

Source principale : vw_payments_clean.

Colonnes principales :
order_id
payment_sequential
customer_id
purchase_date_id
payment_type
payment_installments
payment_value

Validation :
103 886 lignes ;
103 886 couples (order_id, payment_sequential) uniques ;
0 client manquant ;
0 date d'achat manquante ;
0 type de paiement manquant.

8. Contrôle final

Volumes finaux :
produits : 32 951 ;
vendeurs : 3 095 ;
clients : 99 441 ;
dates : 774 ;
commandes : 99 441 ;
lignes d'articles : 112 650 ;
paiements : 103 886.

Les contrôles de relations ont tous retourné 0 :
aucune commande sans client ;
aucune commande sans date ;
aucun article sans produit ;
aucun article sans vendeur ;
aucun article sans commande ;
aucun paiement sans commande.

Le modèle analytique est cohérent et prêt pour les KPI SQL et Power BI.
