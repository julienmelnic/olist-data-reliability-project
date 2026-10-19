Synthèse Cleaning & Transformations - Olist

La phase de nettoyage a construit une couche clean sans modifier les tables de staging.

Six vues principales ont été créées :
vw_products_clean
vw_geolocation_clean
vw_orders_clean
vw_reviews_clean
vw_payments_clean
vw_order_financial_clean

Les principaux traitements sont :
traduction des catégories avec fallback vers la catégorie originale puis unknown ;
transformation des poids à 0 en NULL ;
suppression des doublons géographiques exacts ;
exclusion des coordonnées clairement incohérentes ;
neutralisation des dates temporellement incohérentes dans des colonnes clean_* ;
remplacement de not_defined par unknown pour les paiements ;
transformation des échéances à 0 en NULL ;

validation des montants financiers uniquement lorsque paiement et total articles + frais sont cohérents.
Le contrôle final est validé : tous les tests de résidus d'anomalies retournent 0.

La couche clean est maintenant prête pour la construction du modèle analytique, les KPI métier et Power BI.

