# Procédure reproduite avec succès

## 1. Conditions indispensables

Cette procédure est strictement liée au firmware dont les empreintes figurent
dans `CHECKSUMS.md`. Elle suppose un Realme 14x `RMX3943/RMX3943EEA`, un câble
fiable, une batterie chargée, environ 45 Gio libres et l'autorisation d'effacer
le téléphone.

Vérifier le modèle depuis Android avant toute écriture :

```sh
adb shell getprop ro.product.model
adb shell getprop ro.product.device
adb shell getprop ro.build.fingerprint
```

Installer les outils avec `scripts/00-build-tools.sh`. Le correctif Penumbra
ajoute le chemin Oplus XML DA et rend libusb utilisable sur macOS. Le correctif
android-lptools permet la compilation non statique sur macOS.

## 2. Entrer en BROM/DA

Séquence qui s'est montrée fiable :

1. débrancher le câble ;
2. maintenir **Power + Volume haut** ;
3. à la vibration, relâcher seulement **Power** ;
4. continuer Volume haut et ajouter **Volume bas** ;
5. brancher immédiatement le câble et maintenir les deux volumes environ
   10 secondes pendant qu'Antumbra attend le périphérique.

Le périphérique vu pendant la procédure était `22d9:0006`. Si Android est
encore fonctionnel, `adb reboot edl` a également permis d'entrer dans le mode
attendu.

Variables utilisées dans les exemples :

```sh
ANTUMBRA=tools/penumbra/target/release/antumbra
DA=private/DA_BR.bin
```

## 3. Sauvegarder avant toute écriture

Le plus sûr est une lecture complète vers un disque disposant d'assez de place :

```sh
"$ANTUMBRA" --backend libusb --da "$DA" read-all sauvegarde-complete
```

À défaut, sauvegarder chaque partition critique citée dans
`private/README.md`, puis créer et vérifier un manifeste :

```sh
find sauvegarde-complete -type f -exec shasum -a 256 {} \; | sort > SHA256SUMS.txt
shasum -a 256 -c SHA256SUMS.txt
```

Conserver deux copies hors du dépôt Git. Ne jamais continuer sans `lk_a`,
`lk_b`, `seccfg`, `misc`, `super` et les données radio uniques de l'appareil.

## 4. Déverrouillage persistant du bootloader

Le simple `seccfg unlock` ne suffisait pas : le LK Oplus rétablissait l'état de
verrouillage stocké dans RPMB. Le patch temporaire fait retourner la fonction
qui écrase l'état avant que le chemin sécurisé stock ne synchronise lui-même
l'état déverrouillé et son authentification RPMB.

Créer l'image temporaire :

```sh
./scripts/01-patch-lk.sh private/lk_a.bin private/lk_a.rpmb-sync.bin
```

Puis, en mode DA :

```sh
"$ANTUMBRA" --backend libusb --da "$DA" seccfg unlock
"$ANTUMBRA" --backend libusb --da "$DA" download lk_a private/lk_a.rpmb-sync.bin
"$ANTUMBRA" --backend libusb --da "$DA" reboot normal
```

Accepter l'effacement/déverrouillage sur l'écran du téléphone si celui-ci le
demande. Laisser le cycle de démarrage aller jusqu'à l'état Orange ou au
recovery. Le patch LK est temporaire : dès que l'état déverrouillé a été pris
en compte, revenir en DA et restaurer immédiatement le LK original :

```sh
"$ANTUMBRA" --backend libusb --da "$DA" download lk_a private/lk_a.bin
"$ANTUMBRA" --backend libusb --da "$DA" upload lk_a work/lk_a.readback.bin
shasum -a 256 work/lk_a.readback.bin
```

La dernière empreinte doit être celle du LK stock dans `CHECKSUMS.md`. Ne
jamais patcher `lk_b`, écrire directement RPMB ou toucher aux eFuses. Si
l'appareil ne montre pas l'état Orange, arrêter et restaurer `lk_a`, `seccfg`
et le firmware stock ; ne pas répéter aveuglément.

Une fois Android démarré, les trois propriétés suivantes confirmaient le
succès :

```sh
adb shell getprop ro.boot.flash.locked
adb shell getprop ro.boot.vbmeta.device_state
adb shell getprop ro.boot.verifiedbootstate
```

Résultat attendu : `0`, `unlocked`, `orange`.

## 5. Reconstruire `super`

Télécharger la GSI indiquée dans `CHECKSUMS.md`, la décompresser en
`private/lineage.img`, puis lancer :

```sh
./scripts/02-build-super.sh \
  private/super-stock.bin \
  private/lineage.img \
  work/super-lineage.bin
```

Le script vérifie les deux entrées, extrait le `super` stock, reproduit ses
métadonnées Virtual A/B, remplace uniquement `system_a`, conserve les 17 autres
partitions actives Realme et exige l'empreinte exacte du `super` qui a démarré.

## 6. Flasher et vérifier avant redémarrage

Revenir en DA, fermer les autres outils USB, puis lancer explicitement :

```sh
RMX3943_WRITE=YES ./scripts/03-flash-super.sh \
  private/DA_BR.bin \
  work/super-lineage.bin
```

Le transfert de 12,5 Gio a expiré une fois sur le dernier accusé de réception,
après environ 6 min 40 s, alors que les données étaient intégralement écrites.
Le script ne considère donc pas le code retour seul : il relit quatre blocs de
1 Mio répartis dans `super`, dont un dans la dernière partition utilisée, et
les compare au fichier local. Ne jamais redémarrer si une comparaison échoue.

Après les quatre validations, arrêter proprement le mode DA :

```sh
"$ANTUMBRA" --backend libusb --da "$DA" shutdown
```

Allumer normalement. Au premier recovery, choisir **Format data**, confirmer,
puis **Reboot device**. Le premier démarrage peut durer jusqu'à dix minutes.

## 7. Contrôles après installation

Vérifier au minimum l'affichage et le tactile, Wi-Fi, Bluetooth, SIM/appels et
données, caméras, microphones, haut-parleurs, USB, capteurs, chiffrement et
veille. Garder la sauvegarde stock tant que tous ces contrôles ne sont pas
terminés.
