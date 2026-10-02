#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
antumbra="$repo_dir/tools/penumbra/target/release/antumbra"

expected_da_sha=f862fc429e3f37e922d9c87c304295bc03b71e113d538159a0bf67601dca778e
expected_super_sha=ba99a0fa1918478a39f3d937c17c3d0f9603397c4b1cbd41c573f039bf5942f8
expected_super_size=13421772800
super_address=$((0x8D000000))
sample_size=1048576

usage() {
  printf 'Usage: RMX3943_WRITE=YES %s DA_BR.BIN SUPER_LINEAGE.BIN\n' "$0" >&2
  exit 2
}

[ "$#" -eq 2 ] || usage
[ "${RMX3943_WRITE:-NO}" = YES ] || {
  printf 'Écriture refusée. Lire docs/PROCEDURE.md puis définir RMX3943_WRITE=YES.\n' >&2
  exit 1
}

da_file=$1
super_file=$2
[ -x "$antumbra" ] || { printf 'Antumbra absent; lancer 00-build-tools.sh.\n' >&2; exit 1; }
[ -f "$da_file" ] || { printf 'DA absent: %s\n' "$da_file" >&2; exit 1; }
[ -f "$super_file" ] || { printf 'Super absent: %s\n' "$super_file" >&2; exit 1; }

check_sha() {
  file=$1
  expected=$2
  label=$3
  actual=$(shasum -a 256 "$file" | awk '{print $1}')
  if [ "$actual" != "$expected" ]; then
    printf '%s refusé: SHA-256 %s\n' "$label" "$actual" >&2
    exit 1
  fi
}

check_sha "$da_file" "$expected_da_sha" 'Download Agent'
check_sha "$super_file" "$expected_super_sha" 'Super Lineage'
actual_size=$(wc -c < "$super_file" | tr -d ' ')
[ "$actual_size" = "$expected_super_size" ] || {
  printf 'Taille super inattendue: %s\n' "$actual_size" >&2
  exit 1
}

printf 'ATTENTION: écriture de 12,5 Gio dans la partition super du RMX3943.\n'
printf 'Connecter maintenant le téléphone en BROM/DA avec les deux volumes maintenus.\n'

set +e
"$antumbra" --backend libusb --da "$da_file" download super "$super_file"
flash_status=$?
set -e

if [ "$flash_status" -ne 0 ]; then
  printf 'Antumbra a retourné %s. Le dernier ACK peut expirer; aucune réussite n’est supposée.\n' "$flash_status" >&2
fi

verify_tmp=$(mktemp -d "${TMPDIR:-/tmp}/rmx3943-verify.XXXXXX")
trap 'rm -rf "$verify_tmp"' EXIT HUP INT TERM

# Répartition validée pendant le flash réussi. Le dernier échantillon se trouve
# dans my_manifest_a, la dernière partition logique utilisée.
sample_offsets_mib='0 1025 2955 10398'
for offset_mib in $sample_offsets_mib; do
  relative_offset=$((offset_mib * 1048576))
  address=$((super_address + relative_offset))
  remote_file="$verify_tmp/remote-${offset_mib}.bin"
  printf -v address_hex '0x%X' "$address"

  "$antumbra" --backend libusb --da "$da_file" read-offset "$address_hex" "$sample_size" "$remote_file"
  local_sha=$(dd if="$super_file" bs=1048576 skip="$offset_mib" count=1 status=none | shasum -a 256 | awk '{print $1}')
  remote_sha=$(shasum -a 256 "$remote_file" | awk '{print $1}')
  if [ "$local_sha" != "$remote_sha" ]; then
    printf 'ÉCHEC à +%s Mio: local %s, appareil %s. NE PAS REDÉMARRER.\n' \
      "$offset_mib" "$local_sha" "$remote_sha" >&2
    exit 1
  fi
  printf 'Bloc +%s Mio validé: %s\n' "$offset_mib" "$remote_sha"
done

printf 'Les quatre lectures sont identiques. Arrêter avec:\n'
printf '  %q --backend libusb --da %q shutdown\n' "$antumbra" "$da_file"
printf 'Puis allumer, choisir Format data dans le recovery et Reboot device.\n'
