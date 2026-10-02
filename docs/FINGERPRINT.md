# Lecteur d'empreinte sur le RMX3943

## Correctif validé

Ce correctif a été validé sur le Realme 14x `RMX3943 / RE6092` avec la GSI
LineageOS 22.2 Android 15 `lineage-22.2-20250621-UNOFFICIAL-gsi_arm64_gN`.
Il fonctionne avec SELinux en mode `Enforcing` et persiste après un redémarrage
normal. L'enregistrement d'une empreinte et le déverrouillage par le capteur
latéral (bouton marche) fonctionnent.

Prérequis sur l'hôte : `adb`, Java 17 ou plus (celui d'Android Studio est
détecté automatiquement), Android SDK build-tools (`zipalign`, `apksigner`),
`curl`, `shasum` et `perl`. Le script télécharge apktool `2.10.0` dans
`tools/` et vérifie son empreinte.

Exécuter avec le téléphone démarré et le débogage USB autorisé :

```sh
./scripts/06-install-fingerprint.sh
```

Après le redémarrage, définir un code de verrouillage puis ouvrir
Paramètres > Sécurité > Empreinte digitale.

Pour retirer uniquement ce correctif :

```sh
./scripts/07-uninstall-fingerprint.sh
```

## Cause exacte

Le capteur et le pilote Oplus fonctionnaient déjà : le service
`vendor.oplus.hardware.biometrics.fingerprint@2.1-service_uff` (dans `/odm`)
est démarré et enregistre l'interface AIDL
`android.hardware.biometrics.fingerprint.IFingerprint/default`. Malgré son nom,
il ne fournit aucune interface HIDL. Deux problèmes empêchaient Android de
l'utiliser :

1. **Fonctionnalité non déclarée.** Aucun fichier
   `android.hardware.fingerprint.xml` n'est présent dans `/vendor` ni dans la
   GSI. Sans la fonctionnalité `android.hardware.fingerprint`, le
   `FingerprintService` du framework ne démarre pas
   (`Can't find service: fingerprint`) et l'option n'apparaît pas dans les
   paramètres.
2. **Capteur HIDL fantôme.** L'overlay généré de la GSI
   `framework-res__lineage_gsi_arm64_gN__auto_generated_rro_product.apk`
   définit `config_biometric_sensors = ["0:2:15"]`. Sous Android 15,
   `AuthService` crée alors une `FingerprintSensorConfigurations` en mode HIDL :
   `FingerprintProvider` enveloppe le capteur AIDL dans un
   `HidlToAidlSensorAdapter`, qui cherche
   `android.hardware.biometrics.fingerprint@2.1::IBiometricsFingerprint/default`
   sans jamais le trouver. `FingerprintUpdateActiveUserClient` échoue en boucle
   (`HIDL daemon is null`), la file du capteur ne se vide jamais et l'écran
   d'enregistrement reste bloqué au bouton « J'accepte ».

Les corrections :

1. ajouter `fingerprint/android.hardware.fingerprint.xml` dans
   `/vendor/etc/permissions` ;
2. reconstruire, à partir de l'overlay GSI du téléphone, une copie identique
   dont seul `config_biometric_sensors` est vide ; elle est placée dans
   `/vendor/overlay/rmx3943-fingerprint-rro.bin` ;
3. au démarrage, `fingerprint/init.rmx3943-fingerprint.rc` monte cette copie
   par-dessus l'original, en `post-fs-data`, avant le démarrage de zygote.

Le journal doit alors indiquer `FingerprintProvider/default: Adding AIDL
configs` au lieu de `Adding HIDL configs`.

## Pistes écartées

Elles sont notées pour éviter de les retester :

- `settings put secure com.android.server.biometrics.AuthService.hidlDisabled 1` :
  sous Android 15, ce réglage ne concerne que l'iris ; la configuration HIDL de
  l'empreinte reste lue.
- overlay statique dans `/vendor/overlay` : l'ordre des overlays dépend d'abord
  de la partition (`system, vendor, odm, oem, product, system_ext`), donc celui
  de `/product` l'emporte toujours ;
- overlay mutable dans `/vendor/overlay` : il est appliqué à `system_server`
  après le démarrage d'`AuthService`, donc trop tard ;
- écrire dans `/system` : `system_a` est exposé en lecture seule
  (`'/dev/block/dm-0' is read-only`) et `adb remount` échoue pour `/` ;
- `mount ... bind` directement dans un `.rc` vendor : la commande s'exécute dans
  `vendor_init`, que SELinux empêche de monter sur `/system`
  (`mount() failed: Permission denied`). Le script passe donc par
  `exec u:r:su:s0`, domaine présent uniquement sur les GSI `userdebug` comme
  celle-ci ;
- l'overlay PHH `treble-overlay-xiaomi-mi14pro`, qui vide aussi ce tableau, mais
  modifie en même temps l'affichage, la luminosité et le taux de
  rafraîchissement.

## Vérification

```sh
adb root
adb shell 'pm list features | grep android.hardware.fingerprint'
adb shell 'grep auto_generated_rro_product /proc/mounts'
adb shell 'dumpsys fingerprint | grep -E "sensorId|Current operation|Pending operations"'
```

La première commande doit afficher `feature:android.hardware.fingerprint`, la
deuxième une ligne de montage. La dernière ne doit montrer aucun client
`...fingerprint.hidl...`, seulement des clients `...fingerprint.aidl...` (ou
`Current operation: null`).

Un reflashage de la ROM ou la suppression de l'overlayfs efface les trois
fichiers ajoutés sous `/vendor`. Il suffit alors de relancer le script
d'installation. Avec une autre GSI, l'empreinte de l'overlay d'origine change
et le script s'arrête au lieu de construire une copie inadaptée. Une GSI
`user` (sans domaine `su`) demanderait une autre méthode de montage.
