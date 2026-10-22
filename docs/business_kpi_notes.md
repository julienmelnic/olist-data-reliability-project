Notes — KPI SQL & analyse métier Olist

Cette étape vient après la construction du modèle analytique.

L'objectif est d'utiliser les tables de faits et les dimensions pour calculer des KPI métier, analyser l'activité et préparer les futurs indicateurs du dashboard Power BI.

Les calculs sont réalisés principalement à partir de :
fact_orders
fact_order_items
fact_payments
dim_products
dim_sellers
dim_customers
dim_date
vw_reviews_clean

Une distinction importante est conservée pendant toute l'analyse :
gross_order_value représente la valeur commerciale des produits + frais de livraison ;
validated_total_paid représente le montant payé uniquement pour les commandes dont les données financières ont été réconciliées.

Le terme « chiffre d'affaires » n'est donc pas utilisé comme terme comptable officiel.

1. Vue d'ensemble des commandes

Résultats :
commandes totales : 99 441
commandes livrées : 96 478
commandes annulées : 625
taux d'annulation : 0,63 %

2. Valeur commerciale et paiements validés/Valeur commerciale des commandes livrées

valeur des produits : 13 221 498,11
frais de livraison : 2 198 275,64
valeur brute produits + livraison : 15 419 773,75
panier moyen brut : 159,83
Montants payés validés
commandes livrées : 96 478
commandes livrées avec montant financier validé : 96 103
montant payé validé : 15 349 784,01
montant payé moyen validé : 159,72

Sur ces mêmes 96 103 commandes :
valeur des commandes : 15 349 784,44
montant payé validé : 15 349 784,01
écart cumulé restant : -0,43

L'écart restant est très faible par rapport au montant total, ce qui confirme que la logique de réconciliation est cohérente.

3. Évolution temporelle

Les montants et commandes ont été analysés par mois et par année.

Paiements validés par année
2016 : 45 794,18
2017 : 6 893 028,66
2018 : 8 410 961,17

Attention :
2016 est une année partielle, les données commencent en septembre ;
2018 est également partielle, les données s'arrêtent en octobre.
Une comparaison directe entre les trois années doit donc être interprétée avec prudence.

L'évolution mensuelle est conservée dans le fichier SQL pour être utilisée plus tard dans Power BI, mais tous les mois ne sont pas repris dans ces notes.

4. Produits, catégories et vendeurs

Top catégories

L'analyse porte sur les commandes livrées et financièrement validées.

Les principales catégories en valeur commerciale sont :
health_beauty
watches_gifts
bed_bath_table
sports_leisure
computers_accessories

La catégorie health_beauty arrive en tête avec environ 1,41 million de valeur commerciale.

Top vendeurs

Le classement vendeur montre que les vendeurs réalisant le plus de valeur ne sont pas forcément ceux vendant le plus d'articles.

Répartition par État vendeur

L'activité vendeur est fortement concentrée dans l'État de São Paulo.
La part de SP dans la valeur commerciale totale analysée est de 64,54 %.

5. Clients et fidélisation

Pour analyser les vrais clients, customer_unique_id est utilisé à la place de customer_id.

Résultats :
clients avec au moins une commande livrée : 93 358
clients ayant commandé une seule fois : 90 557
clients récurrents : 2 801
taux de clients récurrents : 3,00 %
nombre moyen de commandes par client : 1,03
maximum de commandes observé pour un client : 15
La fidélisation est donc faible.

Valeur commerciale par client

Sur les commandes livrées et financièrement validées :
valeur commerciale moyenne par client : 165,03
valeur commerciale maximale observée pour un client : 13 664,08

Le Top 10 clients montre que les clients générant les montants les plus élevés correspondent principalement à des achats ponctuels importants.

6. Livraison et performance opérationnelle

Performance globale
commandes livrées : 96 478
commandes avec date de livraison exploitable : 96 386
délai moyen de livraison : 12,56 jours
commandes livrées à temps : 88 562
commandes en retard : 7 824
taux de retard : 8,12 %

Retards

Parmi les commandes arrivées en retard :
retard moyen : 9,55 jours
retard maximum observé : 188,98 jours
Le maximum est un cas extrême et ne représente pas le comportement habituel.

Performance par État client

Pour éviter de surinterpréter les États avec très peu de commandes, une analyse complémentaire a été réalisée uniquement sur les États avec au moins 500 commandes.

Quelques taux de retard observés :
MA : 19,67 %
CE : 15,34 %
BA : 14,04 %
RJ : 13,48 %
SP : 5,90 %
MG : 5,61 %
PR : 4,98 %

La performance logistique varie donc fortement selon les régions.

7. Paiements

Répartition par moyen de paiement

Part du montant total payé :
carte bancaire : 78,45 %
boleto : 17,97 %
voucher : 2,23 %
carte de débit : 1,35 %

Paiements en plusieurs fois

Sur les paiements avec un nombre d'échéances exploitable :
lignes de paiement analysées : 100 359
paiements en une fois : 50 845
paiements en plusieurs fois : 49 514
taux de paiement en plusieurs fois : 49,34 %
nombre moyen d'échéances : 2,84
maximum observé : 24

8. Satisfaction et avis

Satisfaction globale
avis : 99 224
note moyenne : 4,09 / 5
avis positifs (4 ou 5) : 76 470
avis négatifs (1 ou 2) : 14 575
taux d'avis positifs : 77,07 %
taux d'avis négatifs : 14,69 %

Satisfaction et retard de livraison

Commandes livrées à l'heure :
note moyenne : 4,29 / 5
avis positifs : 82,78 %
avis négatifs : 9,23 %

Commandes livrées en retard :
note moyenne : 2,57 / 5
avis positifs : 34,61 %
avis négatifs : 54,03 %

Il existe donc une forte association entre retard de livraison et insatisfaction client. Cette analyse montre une relation entre les deux variables, mais ne permet pas à elle seule de conclure à une causalité.

9. Principaux constats

Les analyses SQL font ressortir plusieurs points importants :

le taux d'annulation est faible ;
la fidélisation client est faible avec seulement 3 % de clients récurrents ;
l'activité vendeur est très concentrée dans l'État de SP ;
les performances logistiques sont très différentes selon les régions ;
près d'un paiement sur deux est réalisé en plusieurs fois ;
la satisfaction globale est élevée ;
les retards de livraison sont fortement associés à une dégradation des avis clients.
Ces résultats serviront de base pour les mesures DAX et les visualisations Power BI.

