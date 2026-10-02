#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
set -euo pipefail

expected_input_sha=88fbf2098fda11e6b29f6666877d5e80725ae8da88150bda0e8330c62322f8a6
expected_output_sha=2440a9be5d1a545ac88f6adaa26e4764c6f1bbbd0c6d44c64f5c3a1d451e14ca
expected_size=16777216
patch_offset=$((0x5857c))

usage() {
  printf 'Usage: %s LK_A_STOCK SORTIE_PATCHÉE\n' "$0" >&2
  exit 2
}

[ "$#" -eq 2 ] || usage
input=$1
output=$2

[ -f "$input" ] || { printf 'Entrée absente: %s\n' "$input" >&2; exit 1; }
[ ! -e "$output" ] || { printf 'La sortie existe déjà: %s\n' "$output" >&2; exit 1; }

actual_input_sha=$(shasum -a 256 "$input" | awk '{print $1}')
[ "$actual_input_sha" = "$expected_input_sha" ] || {
  printf 'LK refusé: SHA-256 inattendu (%s).\n' "$actual_input_sha" >&2
  exit 1
}

actual_size=$(wc -c < "$input" | tr -d ' ')
[ "$actual_size" = "$expected_size" ] || {
  printf 'LK refusé: taille inattendue (%s).\n' "$actual_size" >&2
  exit 1
}

original_bytes=$(xxd -p -s "$patch_offset" -l 4 "$input")
[ "$original_bytes" = fd7bbda9 ] || {
  printf 'LK refusé: octets inattendus à 0x5857c (%s).\n' "$original_bytes" >&2
  exit 1
}

cp "$input" "$output"
printf '\300\003\137\326' | dd of="$output" bs=1 seek="$patch_offset" conv=notrunc status=none

actual_output_sha=$(shasum -a 256 "$output" | awk '{print $1}')
if [ "$actual_output_sha" != "$expected_output_sha" ]; then
  printf 'Échec de validation du LK patché: %s\n' "$actual_output_sha" >&2
  exit 1
fi

printf 'LK temporaire validé: %s\n' "$actual_output_sha"
printf 'Il doit être restauré avec le LK stock dès la synchronisation RPMB terminée.\n'
