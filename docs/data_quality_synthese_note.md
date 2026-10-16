Synthèse Data Quality - Olist

La phase Data Quality a permis de transformer les anomalies détectées pendant le profiling en contrôles SQL réutilisables.

Les données brutes n'ont pas été modifiées. Les tables stg_ sont conservées telles quelles et plusieurs vues vw_*_quality ont été créées pour ajouter des flags de qualité.

Principaux résultats
Les principales anomalies identifiées sont :

1 359 commandes remises au transporteur avant leur approbation ;

23 livraisons enregistrées avant la remise au transporteur ;

61 livraisons enregistrées avant l'approbation ;

5 127 avis créés avant la date de livraison enregistrée ;

610 produits sans informations descriptives ;

2 produits sans poids ni dimensions ;

4 produits avec un poids égal à 0 ;

9 paiements à 0 ;

2 paiements avec 0 échéance ;

3 paiements avec un type not_defined ;

380 commandes avec un écart supérieur à 0,01 entre le montant payé et le total articles + frais de livraison ;

261 831 lignes géographiques dupliquées en trop ;
29 coordonnées géographiques potentiellement hors du Brésil ;

13 produits concernés par une catégorie sans traduction, soit 2 catégories distinctes.

Choix retenus:

Les anomalies ne sont pas supprimées automatiquement.

La stratégie choisie est de conserver les données brutes et d'utiliser des flags pour identifier les lignes à surveiller. Cela permet de décider plus tard, selon le type d'analyse, s'il faut conserver ou exclure certaines lignes.

Les principaux traitements prévus pour la phase suivante sont :

transformer les poids à 0 en NULL ;

dédupliquer les données géographiques ;

exclure les coordonnées incohérentes des analyses cartographiques ;

utiliser un fallback pour les catégories sans traduction ;

garder les anomalies temporelles et de paiement sous forme de flags plutôt que de les corriger arbitrairement.

Conclusion

La couche Data Quality est maintenant validée.

Elle permet de passer à la phase de nettoyage et de transformation avec des règles claires, tout en conservant une trace complète des anomalies présentes dans les données d'origine.

