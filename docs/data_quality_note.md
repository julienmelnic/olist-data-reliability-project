Notes Data Quality - Olist

Ce document reprend les contrôles réalisés après le profiling.

L'objectif était de transformer les anomalies repérées en règles de qualité simples, sans modifier les tables de staging.

Les tables stg_ restent donc intactes. Les contrôles sont ajoutés dans des vues avec des flags pour pouvoir identifier facilement les lignes à surveiller.

1. Commandes - vw_orders_quality
La vue reprend toutes les colonnes de stg_orders et ajoute trois flags liés à la chronologie des dates.

Flags ajoutés:

flag_carrier_before_approval : vaut 1 si la commande est remise au transporteur avant son approbation.

flag_delivery_before_carrier : vaut 1 si la livraison client est enregistrée avant la remise au transporteur.

flag_delivery_before_approval : vaut 1 si la livraison client est enregistrée avant l'approbation.

Résultats

commandes au total : 99 441
transporteur avant approbation : 1 359
livraison avant transporteur : 23
livraison avant approbation : 61

Ces lignes ne sont pas supprimées. Elles sont simplement signalées pour pouvoir être exclues plus tard si une analyse dépend de la cohérence des dates.

2. Avis - vw_reviews_quality

La vue reprend les avis et ajoute la date de livraison de la commande pour pouvoir comparer les deux.

Flag ajouté:

flag_review_before_delivery : vaut 1 si la date de création de l'avis est antérieure à la date de livraison enregistrée.

Lorsque la date de livraison est absente, le flag reste à NULL car le contrôle est impossible.

Résultats

avis au total : 99 224
avis contrôlables : 96 359
avis créés avant la livraison : 5 127
avis non contrôlables faute de date de livraison : 2 865

Les 5 127 avis concernés seront à exclure uniquement des analyses où la chronologie de livraison est importante.

3. Produits - vw_products_quality

La vue reprend les produits et ajoute trois contrôles.

Flags ajoutés:

flag_missing_product_info : catégorie, longueur du nom, longueur de description et nombre de photos absents en même temps.

flag_missing_physical_info : poids et dimensions absents en même temps.

flag_zero_weight : poids du produit égal à 0.

Résultats
produits au total : 32 951
produits sans informations descriptives : 610
produits sans informations physiques : 2
produits avec un poids égal à 0 : 4

Les poids à 0 devront probablement être transformés en NULL pendant le nettoyage plutôt que supprimés.

4. Paiements - vw_payments_quality

Cette vue contrôle les anomalies directement au niveau des lignes de paiement.

Flags ajoutés:

flag_zero_payment : montant du paiement égal à 0.
flag_zero_installments : nombre d'échéances égal à 0.

flag_payment_type_not_defined : type de paiement égal à not_defined.

Résultats
lignes de paiement : 103 886
paiements à 0 : 9
paiements avec 0 échéance : 2
paiements not_defined : 3

Ces cas restent rares. Ils sont conservés mais identifiés pour ne pas les mélanger avec les paiements standards.

5. Comparaison paiements / articles - vw_order_payment_quality

Une deuxième vue a été créée au niveau de la commande.

Le total payé est calculé avec la somme des payment_value.

Le total de la commande est calculé avec price + freight_value pour tous les articles de la commande.

Flag ajouté:

flag_payment_difference : vaut 1 lorsque la différence entre le total payé et le total articles + frais dépasse 0,01.

Résultats
commandes comparables : 98 665
commandes avec un écart : 380

Les écarts représentent une petite partie des commandes. Ils sont conservés et signalés plutôt que corrigés automatiquement car la cause exacte n'est pas connue.

6. Géolocalisation - vw_geolocation_quality

Cette vue permet de repérer les doublons exacts et les coordonnées manifestement incohérentes.

Doublons

ROW_NUMBER() est utilisé pour numéroter les lignes identiques.

La première occurrence garde le rang 1. Les occurrences suivantes sont considérées comme des doublons supplémentaires.

Flags ajoutés:

flag_exact_duplicate : vaut 1 pour les occurrences supplémentaires d'une ligne géographique identique.

flag_outside_brazil : vaut 1 lorsque les coordonnées sortent largement des limites utilisées pour contrôler la zone du Brésil.

Résultats
lignes géographiques : 1 000 163
doublons supplémentaires : 261 831
coordonnées potentiellement hors du Brésil : 29

La géolocalisation sera le principal bloc à nettoyer, surtout à cause du volume important de doublons.

7. Traduction des catégories - vw_product_categories_quality

La vue relie les produits à la table de traduction des catégories.

Flag ajouté:

flag_missing_translation : vaut 1 lorsqu'une catégorie existe en portugais mais n'a pas de traduction anglaise.

Les produits sans catégorie d'origine ne sont pas considérés comme des traductions manquantes.

Résultats
produits au total : 32 951
produits utilisant une catégorie sans traduction : 13
catégories distinctes sans traduction : 2

Les deux catégories concernées sont :
pc_gamer
portateis_cozinha_e_preparadores_de_alimentos

Un fallback pourra être utilisé pendant le nettoyage pour conserver le nom original lorsque la traduction n'existe pas.

8. Contrôle final

Les volumes des vues ont été comparés avec les tables d'origine.

Résultats validés :

vw_orders_quality : 99 441
vw_reviews_quality : 99 224
vw_products_quality : 32 951
vw_payments_quality : 103 886
vw_order_payment_quality : 98 665
vw_geolocation_quality : 1 000 163
vw_product_categories_quality : 32 951
Les volumes sont cohérents avec le profiling.

Décisions pour la suite
Pour la phase de nettoyage :

conserver les tables stg_ telles quelles ;
garder les incohérences de dates avec leurs flags ;

ne pas supprimer les avis anormaux globalement, mais les exclure des analyses temporelles concernées ;

transformer les poids à 0 en NULL ;

dédupliquer la géolocalisation ;

écarter les coordonnées clairement hors du Brésil des analyses cartographiques ;

conserver les paiements atypiques avec leurs flags ;

ne pas corriger automatiquement les 380 écarts de paiement ;

utiliser la catégorie originale lorsqu'une traduction anglaise manque.
