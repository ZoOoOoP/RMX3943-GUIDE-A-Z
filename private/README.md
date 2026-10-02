# Fichiers privés — ne pas publier

La copie locale minimale créée le 2 octobre 2026 conserve uniquement les petits
fichiers utilisés pour le déverrouillage/root : `DA_BR.bin`, `lk_a.bin`,
`lk_b.bin`, `misc.bin` et `seccfg.bin`. Avec le LK patché dans `work/`, cela
représente environ 58 Mio. Les images lourdes ne sont pas dans ce dossier.

Dans un clone public neuf, copier ici depuis ses propres sauvegardes ou sources
autorisées, pour reproduire le déverrouillage/root :

```text
DA_BR.bin
lk_a.bin
lk_b.bin
misc.bin
seccfg.bin
```

Pour refaire aussi la ROM complète, ajouter séparément `super-stock.bin` et
`lineage.img`. Ces deux images lourdes ne font pas partie du kit minimal.

Conserver ailleurs, sur un autre support, une sauvegarde complète des partitions
et au minimum PGPT, SGPT, preloader, boot, vendor_boot, vbmeta, super, seccfg,
misc, nvram, nvdata, nvcfg, persist, proinfo, protect1/2 et les partitions Oplus
propres à l'appareil. Les dumps RPMB sont sensibles et ne doivent jamais être
publiés.

Le `.gitignore` bloque ce contenu, mais `git add -f` contournerait cette
protection. Ne jamais l'utiliser sur ces fichiers.
