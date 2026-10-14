Synthèse du profiling Olist

Le profiling des 9 tables de staging est terminé.
L'objectif était de comprendre la structure des données et de repérer les principaux problèmes de qualité avant de commencer le nettoyage.

Ce qui est globalement propre

Plusieurs tables ont une structure cohérente :
- stg_orders contient 99 441 commandes avec un order_id unique.
- stg_products contient 32 951 produits avec un product_id unique.
- stg_sellers contient 3 095 vendeurs avec un seller_id unique.
- Les relations entre commandes, clients, produits et vendeurs sont globalement cohérentes.
- Les montants négatifs sont absents dans les prix, les frais de livraison et les paiements.
- Les notes clients sont toutes comprises entre 1 et 5.
- La table de traduction ne contient ni NULL ni doublon.


Principales anomalies détectées

Dates et chronologie

Plusieurs incohérences temporelles ont été trouvées dans les commandes :
- 1 359 lignes où la remise au transporteur précède l'approbation
- 23 livraisons client avant la remise au transporteur
- 61 livraisons client avant l'approbation

Dans les avis, 5 127 lignes ont une date de création antérieure à la date de livraison enregistrée, avec des écarts pouvant aller jusqu'à 186 jours.

Ces cas devront être vérifiés avant de décider s'ils doivent être corrigés, exclus ou simplement signalés.


Géolocalisation

stg_geolocation est la table qui présente le plus de problèmes de duplication :
- 1 000 163 lignes
- 19 015 préfixes de codes postaux
- 261 831 lignes supplémentaires identiques

29 lignes ont également des coordonnées qui semblent incompatibles avec une localisation au Brésil.


Produits

610 produits n'ont aucune information descriptive sur la catégorie, la longueur du nom, la description ou le nombre de photos.

Deux produits n'ont ni poids ni dimensions et 4 produits ont un poids enregistré à 0 g.

Deux catégories utilisées dans stg_products n'ont pas de traduction anglaise.


Paiements

La table des paiements est globalement complète mais contient quelques cas particuliers :
- 9 paiements à 0
- 3 paiements not_defined
- 2 paiements avec 0 échéance malgré un montant positif
- 1 commande livrée sans ligne de paiement

380 commandes présentent aussi un écart supérieur à 0,01 entre le montant payé et le total des articles + frais de livraison.

Ces écarts restent rares, mais ils sont plus fréquents parmi les commandes avec plusieurs échéances.


Expédition

10 423 lignes d'articles ont été remises au transporteur après leur date limite d'expédition.

Cela correspond à 8 861 commandes distinctes.

La majorité des retards sont inférieurs à 3 jours, mais 1 283 lignes dépassent une semaine.


Conclusion

Le dataset est globalement exploitable pour une analyse Data Analyst, mais certaines corrections et règles de gestion sont nécessaires avant de construire les KPI et le dashboard.

La prochaine étape sera de transformer les constats du profiling en règles de Data Quality, puis de créer des données nettoyées sans modifier les tables de staging d'origine.