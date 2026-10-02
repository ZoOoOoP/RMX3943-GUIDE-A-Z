#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
lpmake="$repo_dir/tools/android-lptools/bin/lpmake"
lpunpack="$repo_dir/tools/android-lptools/bin/lpunpack"
lpdump="$repo_dir/tools/android-lptools/bin/lpdump"

expected_stock_sha=79ff4360fbe6e23ec96ba7cb197d9a2bd825ea9e05f4789d4a1c13390b9ef084
expected_gsi_sha=f67b6e937de3365da6cd05d4c598c3de4c1d3323eb591eba06628e6326d6fc2d
expected_output_sha=ba99a0fa1918478a39f3d937c17c3d0f9603397c4b1cbd41c573f039bf5942f8
expected_output_size=13421772800

usage() {
  printf 'Usage: %s SUPER_STOCK LINEAGE_IMG SUPER_SORTIE\n' "$0" >&2
  exit 2
}

[ "$#" -eq 3 ] || usage
stock_super=$1
lineage_img=$2
output_img=$3

for tool in "$lpmake" "$lpunpack" "$lpdump"; do
  [ -x "$tool" ] || { printf 'Outil absent: %s (lancer 00-build-tools.sh)\n' "$tool" >&2; exit 1; }
done
[ -f "$stock_super" ] || { printf 'Super stock absent: %s\n' "$stock_super" >&2; exit 1; }
[ -f "$lineage_img" ] || { printf 'GSI absente: %s\n' "$lineage_img" >&2; exit 1; }
[ ! -e "$output_img" ] || { printf 'La sortie existe déjà: %s\n' "$output_img" >&2; exit 1; }

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

check_sha "$stock_super" "$expected_stock_sha" 'Super stock'
check_sha "$lineage_img" "$expected_gsi_sha" 'GSI Lineage'

build_tag=$(date +%Y%m%d-%H%M%S)
build_dir="$repo_dir/work/build-$build_tag"
parts_dir="$build_dir/stock-parts"
mkdir -p "$parts_dir" "$(dirname -- "$output_img")"

printf 'Extraction du super stock...\n'
"$lpunpack" "$stock_super" "$parts_dir"

required_parts='system_ext_a vendor_a product_a my_product_a odm_a my_engineering_a vendor_dlkm_a odm_dlkm_a system_dlkm_a my_stock_a my_heytap_a my_carrier_a my_region_a my_company_a my_preload_a my_bigball_a my_manifest_a'
for part in $required_parts; do
  [ -f "$parts_dir/$part.img" ] || { printf 'Partition extraite absente: %s\n' "$part" >&2; exit 1; }
done

args=(
  --metadata-size 65536
  --metadata-slots 3
  --super-name super
  --device super:13421772800:1048576:0
  --block-size 4096
  --virtual-ab
  --group main_a:13417578496
  --group main_b:13417578496
)

add_part() {
  name=$1
  group=$2
  image=${3:-}
  size=0
  if [ -n "$image" ]; then
    size=$(wc -c < "$image" | tr -d ' ')
  fi
  args+=(--partition "${name}:readonly:${size}:${group}")
}

add_part system_a main_a "$lineage_img"
add_part system_b main_b
for part in system_ext vendor product my_product odm my_engineering vendor_dlkm odm_dlkm system_dlkm my_stock my_heytap my_carrier my_region my_company my_preload my_bigball my_manifest; do
  add_part "${part}_a" main_a "$parts_dir/${part}_a.img"
  add_part "${part}_b" main_b
done

printf 'Création des métadonnées et de l’image de 12,5 Gio...\n'
"$lpmake" "${args[@]}" --force-full-image --output "$output_img"

write_at_sector() {
  image=$1
  sector=$2
  if [ $((sector % 2048)) -ne 0 ]; then
    printf 'Offset non aligné: %s\n' "$sector" >&2
    exit 1
  fi
  seek_mib=$((sector / 2048))
  dd if="$image" of="$output_img" bs=1048576 seek="$seek_mib" conv=notrunc status=none
}

write_at_sector "$lineage_img"                         2048
write_at_sector "$parts_dir/system_ext_a.img"       6051840
write_at_sector "$parts_dir/vendor_a.img"           8470528
write_at_sector "$parts_dir/product_a.img"          9289728
write_at_sector "$parts_dir/my_product_a.img"       9297920
write_at_sector "$parts_dir/odm_a.img"             11902976
write_at_sector "$parts_dir/my_engineering_a.img"  13654016
write_at_sector "$parts_dir/vendor_dlkm_a.img"     13656064
write_at_sector "$parts_dir/odm_dlkm_a.img"        13692928
write_at_sector "$parts_dir/system_dlkm_a.img"     13694976
write_at_sector "$parts_dir/my_stock_a.img"        13697024
write_at_sector "$parts_dir/my_heytap_a.img"       17090560
write_at_sector "$parts_dir/my_carrier_a.img"      17092608
write_at_sector "$parts_dir/my_region_a.img"       17094656
write_at_sector "$parts_dir/my_company_a.img"      17111040
write_at_sector "$parts_dir/my_preload_a.img"      17113088
write_at_sector "$parts_dir/my_bigball_a.img"      20164608
write_at_sector "$parts_dir/my_manifest_a.img"     21295104

actual_size=$(wc -c < "$output_img" | tr -d ' ')
[ "$actual_size" = "$expected_output_size" ] || {
  printf 'Taille super inattendue: %s\n' "$actual_size" >&2
  exit 1
}

"$lpdump" "$output_img" > "$build_dir/super-lineage-lpdump.txt"
check_sha "$output_img" "$expected_output_sha" 'Super reconstruit'

printf 'Super validé: %s\n' "$expected_output_sha"
printf 'Plan LP: %s\n' "$build_dir/super-lineage-lpdump.txt"
