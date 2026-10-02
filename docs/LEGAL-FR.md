# Cadre légal et publication en France

> Synthèse pratique, pas un avis juridique individualisé. État vérifié le
> 2 octobre 2026.

## Ce qui est raisonnablement publiable

Modifier ou réparer un téléphone que l'on possède, ou pour lequel le
propriétaire a donné son autorisation, n'est pas en soi interdit. Le droit
français permet notamment à l'utilisateur légitime d'un logiciel les actes
nécessaires à son utilisation, la copie de sauvegarde nécessaire, ainsi que
l'observation, l'étude ou le test de son fonctionnement dans certaines
conditions. Il prévoit aussi une exception étroite pour les actes indispensables
à l'interopérabilité d'un logiciel créé de façon indépendante :
[CPI, article L122-6-1](https://www.legifrance.gouv.fr/loda/article_lc/LEGIARTI000044365559/2022-06-19).

Le fait que l'appareil soit abîmé n'est pas le critère juridique décisif. Les
points importants sont la propriété ou l'autorisation, l'origine licite des
fichiers, le but de réparation/interopérabilité et le respect des licences et
du droit d'auteur.

Ce dépôt peut donc contenir avec un risque nettement moindre :

- une procédure rédigée par son auteur ;
- des scripts originaux ;
- des empreintes cryptographiques et métadonnées factuelles ;
- des correctifs appliqués à du code open source, avec attribution et licence ;
- des liens vers les téléchargements officiels, plutôt que leurs binaires.

## Ce qu'il ne faut pas publier ici

- firmware stock Realme/Oplus ou partitions extraites ;
- `DA_BR.bin` si sa licence de redistribution n'est pas établie ;
- image GSI incluant les GApps Google ;
- LK stock ou LK déjà patché ;
- sauvegardes `nvram`, `nvdata`, `persist`, `proinfo`, RPMB ou toute donnée
  propre à un appareil ;
- numéros de série, IMEI, clés, jetons ou journaux contenant ces informations.

Les GApps restent des composants propriétaires : le kit donne l'URL et
l'empreinte de la version utilisée, mais ne la remirrore pas. Même logique pour
le firmware et le Download Agent : chaque utilisateur doit les obtenir d'une
source à laquelle il a légitimement accès.

## Limites relatives au contournement

Ce n'est pas une autorisation générale de contourner n'importe quelle mesure de
protection. Le régime des mesures techniques de l'article L331-5 vise les
œuvres « autres qu'un logiciel » ; pour le logiciel, il faut notamment raisonner
avec le régime spécial des articles L122-6 et L122-6-1 :
[CPI, article L331-5](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000044259273).
Les droits exclusifs sur les logiciels sont définis à
[l'article L122-6](https://www.legifrance.gouv.fr/loda/article_lc/LEGIARTI000006278919/2022-02-06).

Le patch de quatre octets et le correctif Oplus servent ici à l'interopérabilité
et à la réparation d'un appareil autorisé, sans fournir de clés propriétaires.
Cela réduit le risque, mais ne garantit pas qu'un constructeur ou une
plateforme n'émettra jamais de contestation. GitHub examine spécifiquement les
réclamations visant les technologies de contournement et peut demander une
modification ou retirer un dépôt après une plainte valable :
[politique DMCA de GitHub](https://docs.github.com/en/site-policy/content-removal-policies/dmca-takedown-policy).

## Licences du code

Penumbra est sous AGPL-3.0. Les modifications correspondantes sont fournies
sous forme de patch, avec le commit amont exact et la licence AGPL incluse dans
ce dossier. `android-lptools` reprend principalement du code AOSP sous Apache
2.0 ; son petit correctif macOS conserve les avis amont. Le code et les textes
originaux de ce kit sont proposés sous AGPL-3.0-or-later.

Avant publication commerciale, sur un appareil d'autrui sans autorisation
écrite, ou si un titulaire de droits conteste le dépôt, demander l'avis d'un
juriste français spécialisé en propriété intellectuelle.
