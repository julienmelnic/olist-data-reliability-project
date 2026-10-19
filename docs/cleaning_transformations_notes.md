Notes Cleaning & Transformations - Olist
Cette étape vient après le profiling et les contrôles Data Quality.

L'objectif était de créer une couche de données plus propre pour l'analyse sans modifier les tables stg_. Les données brutes restent donc disponibles, et les transformations sont faites dans des vues vw_*_clean.

1. Produits - vw_products_clean

La catégorie anglaise est utilisée lorsqu'elle existe. Si la traduction manque, la catégorie originale est conservée. Si aucune catégorie n'existe, la valeur unknown est utilisée.

Les noms product_name_lenght et product_description_lenght sont corrigés dans la vue.

Les poids égaux à 0 sont transformés en NULL.

Résultats :
32 951 produits conservés ;
610 produits avec la catégorie unknown ;
0 poids à 0 restant ;
6 poids NULL après nettoyage.

2. Géolocalisation - vw_geolocation_clean

Avant nettoyage :
1 000 163 lignes ;
261 831 doublons supplémentaires ;
29 coordonnées potentiellement hors du Brésil ;

4 lignes appartenaient aux deux groupes à la fois.
Le nettoyage conserve uniquement la première occurrence de chaque ligne identique et les coordonnées restant dans la zone retenue pour le Brésil.

Résultats :
738 307 lignes après nettoyage ;
0 coordonnée hors Brésil restante ;
0 groupe de doublons exact restant.

3. Commandes - vw_orders_clean

Les commandes ne sont pas supprimées lorsqu'une date est incohérente.

Les dates originales restent disponibles et des colonnes clean_* sont ajoutées pour les analyses temporelles.

Résultats :
99 441 commandes conservées ;
1 382 commandes avec au moins une incohérence temporelle ;
1 359 dates transporteur neutralisées ;
84 dates de livraison client neutralisées ;

61 commandes cumulent une remise au transporteur avant approbation et au moins une incohérence liée à la livraison.

4. Avis - vw_reviews_clean

Tous les avis sont conservés.

Une date de création antérieure à la livraison devient NULL uniquement dans clean_review_creation_date.

is_review_timeline_valid vaut :
1 si la chronologie est vérifiée et correcte ;
0 si elle est vérifiée et incorrecte ;

NULL si elle ne peut pas être vérifiée.

Résultats :
99 224 avis conservés ;
91 232 avis valides ;
5 127 avis invalides ;
2 865 avis non vérifiables ;
5 127 dates d'avis neutralisées.

5. Paiements - vw_payments_clean

Deux transformations sont appliquées :
not_defined devient unknown ;
payment_installments = 0 devient NULL.
Les paiements à 0 restent conservés.

Résultats :
103 886 lignes conservées ;
0 not_defined restant ;
3 unknown ;
0 échéance à 0 restante ;
2 échéances NULL ;
9 paiements à 0 conservés.

6. Montants par commande - vw_order_financial_clean

Les écarts entre le montant payé et le total articles + frais ne sont pas corrigés automatiquement.

validated_total_paid contient le montant payé uniquement quand les deux totaux sont cohérents.

Résultats :
98 665 commandes comparables ;
98 285 commandes cohérentes ;
380 commandes avec un écart ;
98 285 montants validés ;
380 montants non validés.

7. Contrôle final

Volumes validés :
produits : 32 951
géolocalisation : 738 307
commandes : 99 441
avis : 99 224
paiements : 103 886
commandes financières comparables : 98 665
Les contrôles finaux retournent tous 0 :

aucun poids à 0 restant ;
aucune coordonnée hors Brésil restante ;
aucun payment_type = 'not_defined' restant ;
aucune échéance à 0 restante ;
aucun montant incohérent marqué comme validé.
La couche clean est donc validée et prête pour le modèle analytique.

