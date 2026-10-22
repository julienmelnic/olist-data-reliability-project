Synthèse — KPI SQL & analyse métier Olist
La partie KPI permet de transformer le modèle analytique en informations métier directement exploitables.

--Activité

Le dataset contient 99 441 commandes, dont 96 478 livrées. Le taux d'annulation est faible avec 0,63 %.

La valeur brute des commandes livrées, calculée comme la somme des produits et des frais de livraison, atteint 15 419 773,75, pour un panier moyen de 159,83.

Sur les commandes financièrement réconciliées, le montant payé validé atteint 15 349 784,01. La comparaison entre la valeur des commandes et les paiements validés sur le même périmètre ne laisse qu'un écart cumulé de 0,43, ce qui confirme la cohérence de la réconciliation financière.

--Évolution temporelle

Les montants payés validés par année sont :
2016 : 45 794,18
2017 : 6 893 028,66
2018 : 8 410 961,17

2016 et 2018 étant des années partielles dans le dataset, ces montants ne doivent pas être comparés comme trois années complètes.

L'évolution mensuelle sera utilisée dans Power BI pour visualiser plus précisément la tendance de l'activité.

--Produits et vendeurs

Les catégories générant le plus de valeur commerciale incluent notamment health_beauty, watches_gifts, bed_bath_table, sports_leisure et computers_accessories.

L'activité vendeur est fortement concentrée géographiquement : les vendeurs situés dans l'État de São Paulo représentent environ 64,54 % de la valeur commerciale analysée.

--Clients

La fidélisation apparaît faible.

Parmi les clients ayant au moins une commande livrée :
90 557 n'ont commandé qu'une fois ;
2 801 sont récurrents ;
le taux de clients récurrents est de 3,00 % ;
le nombre moyen de commandes par client est de 1,03.

Les clients à plus forte valeur correspondent surtout à des achats ponctuels importants plutôt qu'à une forte fréquence d'achat.

--Livraison

Le délai moyen de livraison est de 12,56 jours.

Le taux de retard est de 8,12 %. Lorsqu'une commande est en retard, le retard moyen atteint 9,55 jours.

Les performances varient fortement selon les États. Parmi les zones avec un volume significatif, certains États comme MA, CE, BA et RJ ont des taux de retard nettement supérieurs à ceux de SP, MG ou PR.

--Paiements

La carte bancaire domine largement les paiements avec 78,45 % du montant total payé, devant le boleto avec 17,97 %.

Le paiement en plusieurs fois est également très fréquent : 49,34 % des paiements exploitables utilisent plus d'une échéance. Le nombre moyen d'échéances est de 2,84.

--Satisfaction

La satisfaction globale est élevée :
note moyenne : 4,09 / 5
avis positifs : 77,07 %
avis négatifs : 14,69 %

Le résultat le plus marquant concerne la livraison.

Les commandes livrées à l'heure ont une note moyenne de 4,29 / 5, contre 2,57 / 5 pour les commandes en retard.

Le taux d'avis négatifs passe de 9,23 % pour les livraisons à l'heure à 54,03 % pour les livraisons en retard.

Les retards de livraison sont donc fortement associés à une baisse de la satisfaction client.

--Conclusion

Les principaux enjeux identifiés sont :
améliorer la fidélisation client ;
réduire les écarts de performance logistique entre les régions ;
limiter les retards de livraison ;
surveiller la forte concentration géographique des vendeurs ;
exploiter la forte utilisation de la carte bancaire et du paiement fractionné.
Ces résultats serviront de base à la construction du dashboard Power BI et des mesures DAX.

