# Double-tap-to-wake sur le RMX3943

## Correctif validé

Ce correctif a été validé sur le Realme 14x `RMX3943 / RE6092` avec la GSI
LineageOS 22.2 Android 15 `lineage-22.2-20250621-UNOFFICIAL-gsi_arm64_gN`.
Il fonctionne avec SELinux en mode `Enforcing` et persiste après un redémarrage
normal.

Exécuter avec le téléphone démarré, le débogage USB autorisé et `adb` dans le
`PATH` :

```sh
./scripts/04-install-dt2w.sh
```

Après le redémarrage, rechercher « double appui » dans les paramètres ou ouvrir
Affichage > Écran de verrouillage. Le geste est également activé directement
par le script.

Pour retirer uniquement ce correctif :

```sh
./scripts/05-uninstall-dt2w.sh
```

## Cause exacte

Le matériel et le pilote Oplus reconnaissaient déjà le geste. Avec l'écran
éteint, `/dev/input/event2` émettait `KEY_F4` (scan code 62), mais la GSI
chargeait `/system/usr/keylayout/Generic.kl`, où le code 62 est une touche F4
ordinaire. Le geste arrivait donc à Android sans être traité comme un réveil.

Trois corrections sont nécessaires :

1. activer le nœud du pilote `/proc/touchpanel/double_tap_enable` après chaque
   démarrage ;
2. mapper le scan code 62 vers `WAKEUP WAKE` ;
3. activer l'overlay PHH déjà livré dans la GSI avec
   `persist.sys.overlay.dt2w=true`. Il remplace
   `config_supportDoubleTapWake=false` par `true` et rend l'option visible.

Les fichiers d'entrée sont placés dans `/data/system/devices`, emplacement
officiellement pris en charge par Android. Sur cette GSI, leurs équivalents
ajoutés à `/vendor/usr` étaient ignorés sous SELinux strict ; ils n'étaient lus
qu'en mode permissif. Il ne faut donc pas déplacer ces deux fichiers dans
`/vendor/usr`.

## Vérification

```sh
adb root
adb shell 'cmd overlay lookup android android:bool/config_supportDoubleTapWake'
adb shell 'cat /proc/touchpanel/double_tap_enable'
adb shell 'dumpsys input | grep -A12 "Path: /dev/input/event2"'
```

Les deux premières commandes doivent afficher `true` puis `1`. La dernière doit
indiquer :

```text
KeyLayoutFile: /data/system/devices/keylayout/rmx3943_touchpanel.kl
ConfigurationFile: /data/system/devices/idc/touchpanel.idc
```

Un formatage des données supprime les deux fichiers sous `/data`. Un reflashage
de ROM ou la suppression de l'overlayfs peut supprimer le fragment sous
`/vendor`. Dans ces cas, il suffit de relancer le script d'installation.
