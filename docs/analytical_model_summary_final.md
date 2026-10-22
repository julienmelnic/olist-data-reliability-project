Synthèse — Modèle analytique Olist

La partie 4 avait pour objectif de transformer les données nettoyées en un modèle analytique simple à exploiter dans SQL et Power BI.

Le modèle contient quatre 
dimensions :
dim_products
dim_sellers
dim_customers
dim_date

et trois tables de faits :
fact_orders
fact_order_items
fact_payments

Les grains sont définis clairement :
dim_products : 1 produit ;
dim_sellers : 1 vendeur ;
dim_customers : 1 customer_id ;
dim_date : 1 jour ;
fact_orders : 1 commande ;
fact_order_items : 1 article dans une commande ;
fact_payments : 1 opération de paiement.

Volumes validés :
32 951 produits ;
3 095 vendeurs ;
99 441 clients ;
774 dates ;
99 441 commandes ;
112 650 lignes d'articles ;
103 886 paiements.

Les contrôles d'unicité et de relations ont été validés.

Aucune relation orpheline n'a été détectée dans les contrôles réalisés.

Le modèle analytique est maintenant prêt pour :
les KPI métier en SQL ;
Power Query pour le chargement et les types si nécessaire ;
les mesures DAX ;
les visualisations Power BI ;
l'analyse métier.
