Notes de profiling des données Olist
Ce document regroupe les principaux constats faits pendant l'exploration des tables de staging.
L'objectif était surtout de comprendre le contenu des données, leur grain, les valeurs manquantes, les doublons et les incohérences possibles avant de commencer le nettoyage.

1. stg_orders
La table contient 99 441 commandes.
order_id est unique, donc une ligne correspond bien à une commande.

La période couverte va du 04/09/2016 au 17/10/2018.

La majorité des commandes ont le statut delivered.

Valeurs manquantes
- order_approved_at : 160
- order_delivered_carrier_date : 1 783
- order_delivered_customer_date : 2 965

Une partie de ces valeurs manquantes est logique pour des commandes annulées, indisponibles ou non encore livrées.

Cohérence des dates
Plusieurs contrôles ont été faits sur l'ordre des événements :
- approbation avant achat : 0
- remise au transporteur avant approbation : 1 359
- livraison client avant remise au transporteur : 23
- livraison client avant achat : 0
- livraison client avant approbation : 61

Ces cas seront à revoir pendant la phase Data Quality. Ils ne sont pas forcément tous des erreurs, mais certaines différences sont assez importantes pour être signalées.


2. stg_order_items

La table contient 112 650 lignes pour :
- 98 666 commandes
- 32 951 produits
- 3 095 vendeurs
Le grain est donc : une ligne = un article dans une commande.
Le couple order_id + order_item_id est unique.
Valeurs manquantes et validité

Aucune valeur manquante sur les colonnes principales.

Aucun prix négatif et aucun frais de livraison négatif.

Prix et livraison
- prix minimum : 0,85
- prix maximum : 6 735
- prix moyen : environ 120,65
- frais de livraison minimum : 0
- frais de livraison maximum : 409,68
- frais de livraison moyen : environ 19,99
Les valeurs les plus élevées ont été vérifiées. Elles semblent plausibles, notamment parce que certains produits sont lourds ou volumineux.

Intégrité entre les tables
Aucune référence manquante pour :
- product_id vers stg_products
- seller_id vers stg_sellers
- order_id vers stg_orders
En revanche, 775 commandes de stg_orders n'ont pas de ligne dans stg_order_items. Elles concernent surtout des commandes unavailable ou canceled.

Retards d'expédition

10 423 lignes d'articles ont été remises au transporteur après leur shipping_limit_date, soit 9,35 % des lignes comparables.

Cela correspond à 8 861 commandes distinctes.

Répartition des retards :
- moins de 1 jour : 5 198
- entre 1 et moins de 3 jours : 2 190
- entre 3 et moins de 7 jours : 1 752
- 7 jours ou plus : 1 283


3. stg_order_payments

La table contient 103 886 lignes de paiement pour 99 440 commandes distinctes.

Une commande peut donc avoir plusieurs lignes de paiement.

Les types de paiement observés sont :
- credit_card : 76 795
- boleto : 19 784
- voucher : 5 775
- debit_card : 1 529
- not_defined : 3

Le couple order_id + payment_sequential est unique.

Aucune valeur NULL n'a été détectée.

Cas particuliers

Une commande livrée n'a aucun paiement associé.

Il existe 9 lignes avec un payment_value égal à 0 :
- 6 voucher
- 3 not_defined
Les 6 vouchers à 0 apparaissent dans des commandes qui ont aussi d'autres paiements positifs.

Les 3 lignes not_defined correspondent à des commandes dont le montant total de paiement est également 0.

Échéances

Le nombre d'échéances va de 0 à 24.

Deux paiements par carte ont payment_installments = 0 malgré un montant positif.

18 commandes distinctes ont au moins un paiement enregistré en 24 échéances.

Montants
- minimum : 0
- maximum : 13 664,08
- moyenne : environ 154,10
Le paiement maximum a été vérifié : la commande contient 8 articles à 1 680 avec 28,01 de frais de livraison chacun. Le total correspond exactement au paiement de 13 664,08.

Écart entre paiement et valeur de la commande
Pour 380 commandes, le montant total payé diffère de plus de 0,01 du total price + freight_value.

Répartition par statut :
- delivered : 374
- shipped : 3
- canceled : 2
- invoiced : 1
Les écarts ne semblent donc pas venir principalement des commandes annulées.

Le taux d'écart est :
- 0,14 % pour les commandes avec 1 échéance ou moins
- 0,62 % pour les commandes avec plusieurs échéances
Les paiements en plusieurs fois sont donc davantage associés à ces écarts, sans permettre de dire qu'ils en sont la cause.


4. stg_customers

La table contient 99 441 lignes.
- customer_id distincts : 99 441
- customer_unique_id distincts : 96 096
customer_id est lié à la commande, alors que customer_unique_id permet d'identifier le même client sur plusieurs commandes.

2 997 clients apparaissent sur plusieurs commandes.

Aucune valeur manquante n'a été détectée.
Toutes les commandes ont un client correspondant dans stg_customers.

Les 27 unités fédératives brésiliennes sont présentes dans customer_state et aucun code manifestement invalide n'a été trouvé.


5. stg_order_reviews

La table contient 99 224 lignes.
- review_id distincts : 98 410
- order_id distincts : 98 673
review_id seul n'est pas unique.
En revanche, le couple review_id + order_id est unique.

Valeurs manquantes

Aucune valeur manquante pour :
- review_id
- order_id
- review_score
- review_creation_date
- review_answer_timestamp
En revanche :
- review_comment_title : 87 656 NULL
- review_comment_message : 58 247 NULL
Ces valeurs manquantes sont plausibles car un client peut laisser une note sans commentaire.

Notes

review_score contient uniquement les valeurs de 1 à 5.

Répartition :
- 1 : 11 424
- 2 : 3 151
- 3 : 8 179
- 4 : 19 142
- 5 : 57 328

Tous les avis ont une commande correspondante.
Cohérence des dates
Aucune réponse à un avis n'est datée avant sa création.

En revanche, 5 127 avis ont une date de création située au moins un jour avant la date de livraison enregistrée.

Les plus gros écarts atteignent 186 jours.
Ces cas seront à examiner pendant la phase Data Quality.


6. stg_products

La table contient 32 951 produits et tous les product_id sont uniques.

Le grain est donc : une ligne = un produit.
Valeurs manquantes

610 produits ont en même temps :
- product_category_name NULL
- product_name_lenght NULL
- product_description_lenght NULL
- product_photos_qty NULL

Deux produits ont le poids et les dimensions entièrement manquants.

Valeurs physiques

Quatre produits ont product_weight_g = 0.
Ils appartiennent tous à la catégorie cama_mesa_banho.

Plages observées :
- poids : 0 à 40 425 g
- longueur : 7 à 105 cm
- hauteur : 2 à 105 cm
- largeur : 6 à 118 cm

À part les 4 poids nuls, aucune valeur maximale ne paraît manifestement impossible.


7. stg_sellers

La table contient 3 095 vendeurs et les 3 095 seller_id sont uniques.

Aucune valeur manquante sur :
- seller_id
- seller_zip_code_prefix
- seller_city
- seller_state

Les vendeurs sont présents dans 23 États brésiliens.

Aucun code d'État manifestement invalide n'a été détecté.


8. stg_geolocation

La table contient 1 000 163 lignes pour seulement 19 015 préfixes de codes postaux distincts.

Un même code postal apparaît donc plusieurs fois avec différentes observations géographiques.

Aucune valeur manquante n'a été détectée.

Doublons
- groupes de doublons exacts : 128 174
- lignes supplémentaires identiques : 261 831

Cette table contient donc beaucoup de doublons qui pourront être supprimés ou regroupés pendant le nettoyage.

Coordonnées

Toutes les latitudes et longitudes respectent les limites géographiques mondiales.

Les valeurs observées vont de :
- latitude : -36,61 à 45,07
- longitude : -101,47 à 121,11

Certaines coordonnées sont cependant incompatibles avec une localisation au Brésil.
Avec les limites utilisées pour le contrôle, 29 lignes sont potentiellement situées hors du Brésil alors que les villes et États renseignés sont brésiliens.

Les 27 unités fédératives brésiliennes sont présentes dans la table.


9. stg_product_category_name_translation

La table contient 71 lignes.
- 71 catégories portugaises uniques
- 71 traductions anglaises uniques
- aucune valeur manquante
- aucun doublon détecté

Deux catégories présentes dans stg_products n'ont pas de traduction :
- pc_gamer
- portateis_cozinha_e_preparadores_de_alimentos

La table de traduction est donc légèrement incomplète.

Points à reprendre pendant le nettoyage
Les principaux sujets à traiter ensuite sont :
- les incohérences de dates dans stg_orders
- les avis datés avant la livraison
- les doublons de stg_geolocation
- les coordonnées géographiques suspectes
- les 610 produits sans informations descriptives
- les 4 poids produits égaux à 0
- les catégories sans traduction
- les paiements atypiques
- les écarts entre montant payé et valeur des articles

Les tables de staging restent inchangées pour garder une copie fidèle des données sources.