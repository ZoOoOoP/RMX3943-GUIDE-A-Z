# Versions et empreintes validées

Les empreintes ci-dessous identifient les entrées exactes utilisées. Une seule
différence signifie que les offsets et scripts spécifiques au RMX3943 ne
doivent pas être employés sans nouvelle analyse.

## Outils

| Élément | Version exacte |
|---|---|
| Penumbra / Antumbra | commit `f72152076bb4c0a3fd0f2febefdde40935a2e4c5` (`v2.0.0`) |
| android-lptools | commit `b7b5c09916ab88074692006db7dab34256da6e24`, branche `android-14` |
| apktool | `2.10.0`, SHA-256 `c0350abbab5314248dfe2ee0c907def4edd14f6faef1f5d372d3d4abd28f0431` |
| apktool | `2.10.0`, SHA-256 `c0350abbab5314248dfe2ee0c907def4edd14f6faef1f5d372d3d4abd28f0431` |

## Fichiers privés

| Fichier | Octets | SHA-256 |
|---|---:|---|
| `DA_BR.bin` | 803144 | `f862fc429e3f37e922d9c87c304295bc03b71e113d538159a0bf67601dca778e` |
| `lk_a.bin` stock | 16777216 | `88fbf2098fda11e6b29f6666877d5e80725ae8da88150bda0e8330c62322f8a6` |
| `lk_b.bin` stock | 16777216 | `080acf35a507ac9849cfcba47dc2ad83e01b75663a516279c8b9d243b719643e` |
| `seccfg.bin` stock | 8388608 | `173a9c0dc2f02eace7f60d5d11a21040c6d20567ed23d36ed4d9ece0fa81f10b` |
| `misc.bin` stock | 524288 | `2d88a620984164795412ffa7b0a346caa6e9c13ff6e8394fc6af42e496879300` |
| `super-stock.bin` | 13421772800 | `79ff4360fbe6e23ec96ba7cb197d9a2bd825ea9e05f4789d4a1c13390b9ef084` |
| Lineage GSI décompressée | 3096682496 | `f67b6e937de3365da6cd05d4c598c3de4c1d3323eb591eba06628e6326d6fc2d` |

La GSI validée est
`lineage-22.2-20250621-UNOFFICIAL-gsi_arm64_gN-signed.img` : ARM64 AB,
GApps (`g`), sans superutilisateur (`N`), signée par le mainteneur. Le fichier
compressé est disponible dans le dossier officiel
[Andy Yan GSI / lineage-22-light](https://sourceforge.net/projects/andyyan-gsi/files/lineage-22-light/).

## Fichier lu sur le téléphone

| Fichier | Octets | SHA-256 |
|---|---:|---|
| `framework-res__lineage_gsi_arm64_gN__auto_generated_rro_product.apk` (overlay GSI d'origine) | 4822392 | `a085389b07d81ad10a3ca465ecb3bb8c7a6e50d7df378e116f3631de147bd95b` |

`scripts/06-install-fingerprint.sh` refuse de continuer si cet overlay diffère.
La copie reconstruite n'a pas d'empreinte fixe : elle est signée avec une clé
jetable générée localement.

## Fichiers produits

| Fichier | Octets | SHA-256 |
|---|---:|---|
| LK temporaire RPMB-sync | 16777216 | `2440a9be5d1a545ac88f6adaa26e4764c6f1bbbd0c6d44c64f5c3a1d451e14ca` |
| `super-lineage.bin` | 13421772800 | `ba99a0fa1918478a39f3d937c17c3d0f9603397c4b1cbd41c573f039bf5942f8` |

Le patch LK est limité à quatre octets à l'offset brut `0x5857c` :
`fd 7b bd a9` devient `c0 03 5f d6` (`ret` AArch64). Il n'est valable que pour
le LK stock ayant l'empreinte indiquée ci-dessus.

Après déverrouillage réussi :

- `seccfg` observé : état brut `3`, SHA-256
  `497caa35b10d86ad7d098c444f97c1d9f87990818c8d84dab6ef43168dd6b121` ;
- propriétés de démarrage : `ro.boot.flash.locked=0`,
  `ro.boot.vbmeta.device_state=unlocked`, `ro.boot.verifiedbootstate=orange`.
