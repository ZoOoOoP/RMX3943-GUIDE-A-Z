# Realme 14x RMX3943 — kit reproductible LineageOS

La partie versionnée et publiable de ce dossier conserve uniquement ce qui a
réellement permis l'installation : la procédure, les correctifs source, les
scripts de reconstruction et les empreintes SHA-256. Aucun firmware Realme,
Download Agent, GApps, sauvegarde du téléphone, clé ou donnée RPMB ne sera suivi
par Git. La copie locale ne conserve que les petits fichiers utiles au
déverrouillage/root dans des chemins ignorés ; les images `super` et GSI de
plusieurs gigaoctets restent hors de ce kit.

## Périmètre validé

- appareil : Realme 14x 5G `RMX3943 / RMX3943EEA`, nom de code `rado` ;
- SoC : MediaTek `MT6835` (Dimensity 6300), stockage eMMC 116,5 Gio ;
- disposition : Virtual A/B, slot `a`, partition `super` de 12,5 Gio ;
- hôte utilisé : macOS ;
- système installé : LineageOS 22.2 GSI, Android 15, ARM64, GApps, sans root ;
- résultat : démarrage de LineageOS après formatage de `data` dans le recovery.

Ce n'est pas une ROM spécifique au RMX3943. Le noyau, le vendor, les pilotes et
les autres partitions Realme restent ceux du firmware stock ; seule la
partition logique `system_a` est remplacée dans une copie reconstruite de
`super`.

## Contenu

- [Procédure complète](docs/PROCEDURE.md)
- [Récupération en cas d'échec](docs/RECOVERY.md)
- [Correctif double-tap-to-wake validé](docs/DT2W.md)
- [Correctif du lecteur d'empreinte validé](docs/FINGERPRINT.md)
- [Empreintes et versions exactes](CHECKSUMS.md)
- [Cadre légal et publication](docs/LEGAL-FR.md)
- [Attributions des projets amont](NOTICE.md)
- `scripts/` : compilation, patch LK, reconstruction et flash vérifié
- `patches/` : correctifs minimaux appliqués aux outils open source
- `dt2w/` et `scripts/04-*`/`05-*` : fichiers et automatisation du réveil par
  double appui, sans binaire lourd
- `fingerprint/` et `scripts/06-*`/`07-*` : activation du lecteur d'empreinte ;
  la copie d'overlay est reconstruite depuis le téléphone, sans binaire suivi

## Refaire l'installation

1. Lire entièrement `docs/PROCEDURE.md` et effectuer ses propres sauvegardes.
2. Dans un clone neuf, placer les fichiers privés dans `private/` comme indiqué
   dans `private/README.md`. Ce répertoire est ignoré par Git. Pour reflasher
   une ROM, fournir séparément sa propre sauvegarde `super` et son image GSI :
   elles ne sont volontairement pas conservées dans ce kit minimal.
3. Compiler les outils :

   ```sh
   ./scripts/00-build-tools.sh
   ```

4. Fabriquer le LK temporaire, si le bootloader doit encore être déverrouillé :

   ```sh
   ./scripts/01-patch-lk.sh private/lk_a.bin private/lk_a.rpmb-sync.bin
   ```

5. Après le déverrouillage décrit dans la procédure, reconstruire `super` :

   ```sh
   ./scripts/02-build-super.sh private/super-stock.bin private/lineage.img work/super-lineage.bin
   ```

6. Flasher uniquement après validation des empreintes et des sauvegardes :

   ```sh
   RMX3943_WRITE=YES ./scripts/03-flash-super.sh private/DA_BR.bin work/super-lineage.bin
   ```

Dans cette copie locale, seul `work/lk_a.rpmb-sync.bin` est déjà prêt et validé.
`super-stock.bin`, `lineage.img` et `work/super-lineage.bin` ne sont pas inclus :
les étapes de reconstruction les recréent à partir de fichiers fournis à part.

Pour revalider les fichiers locaux minimaux avant une nouvelle intervention :

```sh
shasum -a 256 -c LOCAL-SHA256SUMS
```

Chaque script refuse les entrées dont l'empreinte diffère de l'appareil et des
fichiers effectivement validés le 2 octobre 2026.

## Publication GitHub

Le dossier est conçu pour être publié tel quel. Vérifier avant chaque commit :

```sh
git status --short --ignored
git ls-files | grep -E '\.(bin|img|gz|zip|ofp)$' && echo "ERREUR: binaire suivi par Git"
```

Ne jamais forcer l'ajout d'un fichier ignoré. Les gros fichiers et les données
propres au téléphone doivent rester dans une sauvegarde privée chiffrée.

## Avertissement

Ces opérations peuvent effacer toutes les données ou rendre l'appareil
inutilisable. Elles ne sont documentées que pour un RMX3943 possédé par
l'opérateur, avec autorisation, sauvegardes vérifiées et possibilité de retour
stock. Ne jamais écrire directement dans RPMB ni dans les eFuses.
