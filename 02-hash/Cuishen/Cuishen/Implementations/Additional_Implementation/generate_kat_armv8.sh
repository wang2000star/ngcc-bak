#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

bits_list=(512 768 1024)
cc="${CC:-gcc}"
out=""
run_kat=1
extra_flags=()

usage() {
  cat <<'USAGE'
Usage: generate_kat_armv8.sh [--bits 512|768|1024] [--cc CC] [-o OUTPUT]
                             [--build-only] [-- EXTRA_CFLAGS...]

Without --bits, builds and runs KAT generators for Cuishen-512, Cuishen-768,
and Cuishen-1024 in sequence. Generated files are written to
Cuishen-*/ARMv8/output/. Use --bits to run a single algorithm instance.
USAGE
}

while (($#)); do
  case "$1" in
    --bits)
      bits_list=("$2")
      shift 2
      ;;
    --cc)
      cc="$2"
      shift 2
      ;;
    -o|--out)
      out="$2"
      shift 2
      ;;
    --build-only|--no-run)
      run_kat=0
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      extra_flags+=("$@")
      break
      ;;
    *)
      extra_flags+=("$1")
      shift
      ;;
  esac
done

if [[ -n "$out" && "${#bits_list[@]}" -ne 1 ]]; then
  printf 'ERROR: -o/--out can only be used together with --bits.\n' >&2
  exit 1
fi

run_one() {
  local bits="$1"
  local pkg="$SCRIPT_DIR/Cuishen-$bits/ARMv8"
  local exe="$out"
  local build_dir

  case "$bits" in
    512|768|1024) ;;
    *)
      printf 'Unsupported --bits value: %s\n' "$bits" >&2
      exit 1
      ;;
  esac

  if [[ -z "$exe" ]]; then
    exe="/tmp/kat_cuishen_${bits}_armv8"
  fi

  build_dir="$(mktemp -d "${TMPDIR:-/tmp}/cuishen-kat-armv8.XXXXXX")"

  local sha3_flags=(-march=armv8.2-a+sha3)
  local nosha3_flags=(-march=armv8.2-a)
  if [[ "$(uname -s)" == "Darwin" ]]; then
    nosha3_flags=(-mcpu=apple-m1+nosha3 -U__ARM_FEATURE_SHA3)
  fi

  printf '\n== Cuishen-%s ARMv8 additional KAT ==\n' "$bits"
  "$cc" -O3 -std=c99 -Wpedantic -Wall -Wextra \
    ${extra_flags[@]+"${extra_flags[@]}"} -I "$pkg" \
    -c "$pkg/KAT_CryptHash.c" -o "$build_dir/kat.o"
  "$cc" -O3 -std=c99 -Wpedantic -Wall -Wextra \
    ${extra_flags[@]+"${extra_flags[@]}"} -I "$pkg" \
    -c "$pkg/drng.c" -o "$build_dir/drng.o"
  "$cc" -O3 -std=c99 -Wpedantic -Wall -Wextra \
    ${extra_flags[@]+"${extra_flags[@]}"} -I "$pkg" \
    -c "$pkg/CryptHash_Cuishen-${bits}_ARM_dispatch.c" \
    -o "$build_dir/dispatch.o"
  "$cc" -O3 -std=c99 -Wpedantic -Wall -Wextra "${sha3_flags[@]}" \
    ${extra_flags[@]+"${extra_flags[@]}"} -I "$pkg" \
    -c "$pkg/CryptHash_Cuishen-${bits}_ARM_sha3.c" -o "$build_dir/sha3.o"
  "$cc" -O3 -std=c99 -Wpedantic -Wall -Wextra "${nosha3_flags[@]}" \
    ${extra_flags[@]+"${extra_flags[@]}"} -I "$pkg" \
    -c "$pkg/CryptHash_Cuishen-${bits}_ARM_nosha3.c" \
    -o "$build_dir/nosha3.o"
  "$cc" "$build_dir/kat.o" "$build_dir/drng.o" "$build_dir/dispatch.o" \
    "$build_dir/sha3.o" "$build_dir/nosha3.o" -o "$exe"
  rm -rf "$build_dir"

  printf 'Built KAT generator: %s\n' "$exe"

  if [[ "$run_kat" -eq 1 ]]; then
    (cd "$pkg" && "$exe")
    printf 'Generated KAT files under: %s/output\n' "$pkg"
  fi
}

for bits in "${bits_list[@]}"; do
  run_one "$bits"
done

printf '\nARMv8 additional implementation KAT task finished.\n'
