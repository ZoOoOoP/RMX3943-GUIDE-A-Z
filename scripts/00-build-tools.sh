#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
set -euo pipefail

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_dir=$(CDPATH= cd -- "$script_dir/.." && pwd)
tools_dir="$repo_dir/tools"
penumbra_dir="$tools_dir/penumbra"
lptools_dir="$tools_dir/android-lptools"

penumbra_commit=f72152076bb4c0a3fd0f2febefdde40935a2e4c5
lptools_commit=b7b5c09916ab88074692006db7dab34256da6e24

for command_name in git cargo clang make; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf 'Commande manquante: %s\n' "$command_name" >&2
    exit 1
  fi
done

mkdir -p "$tools_dir"

if [ ! -e "$penumbra_dir" ]; then
  git clone https://github.com/shomykohai/penumbra.git "$penumbra_dir"
fi
if [ ! -d "$penumbra_dir/.git" ]; then
  printf 'Le chemin existe mais ne contient pas Penumbra: %s\n' "$penumbra_dir" >&2
  exit 1
fi

git -C "$penumbra_dir" fetch --tags origin
git -C "$penumbra_dir" checkout --detach "$penumbra_commit"
if git -C "$penumbra_dir" apply --check "$repo_dir/patches/penumbra-rmx3943-macos-oplus.patch"; then
  git -C "$penumbra_dir" apply "$repo_dir/patches/penumbra-rmx3943-macos-oplus.patch"
elif ! git -C "$penumbra_dir" apply --reverse --check "$repo_dir/patches/penumbra-rmx3943-macos-oplus.patch"; then
  printf 'Le correctif Penumbra ne correspond pas au commit attendu.\n' >&2
  exit 1
fi

(
  cd "$penumbra_dir"
  RUSTC_BOOTSTRAP=1 cargo build --release --bin antumbra
)

if [ ! -e "$lptools_dir" ]; then
  git clone --branch android-14 https://github.com/itsNileshHere/android-lptools.git "$lptools_dir"
fi
if [ ! -d "$lptools_dir/.git" ]; then
  printf 'Le chemin existe mais ne contient pas android-lptools: %s\n' "$lptools_dir" >&2
  exit 1
fi

git -C "$lptools_dir" fetch origin android-14
git -C "$lptools_dir" checkout --detach "$lptools_commit"
if git -C "$lptools_dir" apply --check "$repo_dir/patches/android-lptools-macos.patch"; then
  git -C "$lptools_dir" apply "$repo_dir/patches/android-lptools-macos.patch"
elif ! git -C "$lptools_dir" apply --reverse --check "$repo_dir/patches/android-lptools-macos.patch"; then
  printf 'Le correctif android-lptools ne correspond pas au commit attendu.\n' >&2
  exit 1
fi

(
  cd "$lptools_dir"
  ./make.sh
)

for output in \
  "$penumbra_dir/target/release/antumbra" \
  "$lptools_dir/bin/lpdump" \
  "$lptools_dir/bin/lpmake" \
  "$lptools_dir/bin/lpunpack"; do
  if [ ! -x "$output" ]; then
    printf 'Compilation incomplète, exécutable absent: %s\n' "$output" >&2
    exit 1
  fi
done

printf 'Outils prêts dans %s\n' "$tools_dir"
