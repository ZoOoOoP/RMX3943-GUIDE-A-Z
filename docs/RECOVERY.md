# Récupération et limites connues

## Règle générale

Ne jamais improviser une écriture dans RPMB ou une eFuse. Tant que BROM/DA est
accessible et que les sauvegardes sont valides, restaurer uniquement les
partitions connues, une à la fois, et relire après écriture.

## Écran noir après le logo

Cela indique souvent une GSI incompatible avec le vendor ou le pilote
d'affichage, même si Android semble démarrer en arrière-plan. Attendre dix
minutes au premier démarrage ; si l'écran reste noir, revenir en DA et restaurer
le `super` stock :

```sh
ANTUMBRA=tools/penumbra/target/release/antumbra
DA=private/DA_BR.bin
"$ANTUMBRA" --backend libusb --da "$DA" download super private/super-stock.bin
```

La GSI Google Android 16 testée pendant la recherche a produit ce symptôme et
n'est donc pas retenue dans ce kit.

## Boucle recovery / fastbootd

Une commande résiduelle dans `misc` peut forcer le prochain mode. Restaurer
uniquement son propre `misc.bin` stock, puis relire et vérifier son empreinte :

```sh
"$ANTUMBRA" --backend libusb --da "$DA" download misc private/misc.bin
"$ANTUMBRA" --backend libusb --da "$DA" upload misc work/misc.readback.bin
shasum -a 256 work/misc.readback.bin
```

## Boucle de chiffrement ou retour recovery après changement de système

Dans le recovery stock, sélectionner **Format data**, confirmer, puis
**Reboot device**. Cette opération efface toutes les données utilisateur.

## Problème pendant le déverrouillage

Restaurer en priorité le LK original vérifié :

```sh
"$ANTUMBRA" --backend libusb --da "$DA" download lk_a private/lk_a.bin
```

`lk_b` est resté stock pendant toute l'opération. Ne restaurer `seccfg` que
depuis la sauvegarde du même téléphone. Un dump RPMB n'est pas une image de
partition ordinaire et ne doit pas être réécrit comme telle.

## Retour complet à Realme UI

Restaurer `super-stock.bin`, le `misc.bin` d'origine et, si nécessaire,
uniquement les autres partitions provenant de la sauvegarde exacte du même
appareil et du même firmware. Terminer par un formatage de `data`. Relire les
partitions restaurées et comparer leurs SHA-256 avant le redémarrage.
