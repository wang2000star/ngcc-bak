#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

all_bits=(512 768 1024)
bits_list=()
cc="${CC:-gcc}"
out=""
min_iterations=100
min_seconds=1.0
cpu_hz=""
build_only=0
extra_flags=()

usage() {
  cat <<'USAGE'
Usage: ./build_benchmark.sh [--bits 512|768|1024] [--cc CC] [-o OUTPUT]
                            [--min-iterations N] [--min-seconds SEC]
                            [--cpu-hz HZ] [--build-only]
                            [-- EXTRA_CFLAGS...]

Builds and runs the Cuishen x86-64 AVX2/BMI2 self-evaluation benchmarks.
Without --bits, all three instances (512, 768, 1024) are built and run.

The script prints performance results to the terminal. The only persistent
build artifact is the benchmark executable under bin/.
USAGE
}

die() {
  printf '%s\n' "$*" >&2
  exit 1
}

validate_bits() {
  case "$1" in
    512|768|1024) ;;
    *) die "Unsupported --bits value: $1" ;;
  esac
}

while (($#)); do
  case "$1" in
    --bits)
      (($# >= 2)) || die "Missing value after --bits"
      bits_list=("$2")
      shift 2
      ;;
    --cc)
      (($# >= 2)) || die "Missing value after --cc"
      cc="$2"
      shift 2
      ;;
    -o|--out)
      (($# >= 2)) || die "Missing value after $1"
      out="$2"
      shift 2
      ;;
    --min-iterations)
      (($# >= 2)) || die "Missing value after --min-iterations"
      min_iterations="$2"
      shift 2
      ;;
    --min-seconds)
      (($# >= 2)) || die "Missing value after --min-seconds"
      min_seconds="$2"
      shift 2
      ;;
    --cpu-hz)
      (($# >= 2)) || die "Missing value after --cpu-hz"
      cpu_hz="$2"
      shift 2
      ;;
    --build-only)
      build_only=1
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

if ((${#bits_list[@]} == 0)); then
  bits_list=("${all_bits[@]}")
fi

for bits in "${bits_list[@]}"; do
  validate_bits "$bits"
done

if [[ -n "$out" && ${#bits_list[@]} -ne 1 ]]; then
  die "-o/--out is only supported together with a single --bits value"
fi

bin_dir="$SCRIPT_DIR/bin"
mkdir -p "$bin_dir"

build_one() {
  local bits="$1"
  local exe="$2"
  local pkg="$SCRIPT_DIR/Cuishen-$bits"
  local main_src="$pkg/CryptHash_Cuishen-${bits}_x86.S"

  [[ -f "$main_src" ]] || die "Missing source file: $main_src"
  mkdir -p "$(dirname "$exe")"

  "$cc" -O3 -march=x86-64 -mavx2 -mbmi -mbmi2 -madx -mtune=native \
    -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra \
    "-DNGCC_HASH_BITS=$bits" ${extra_flags[@]+"${extra_flags[@]}"} -I "$pkg" \
    "$SCRIPT_DIR/ngcc_hash_benchmark.c" "$main_src" -o "$exe"
}

run_one() {
  local bits="$1"
  local exe="$2"
  local bench_args=(--min-iterations "$min_iterations" --min-seconds "$min_seconds")

  if [[ -n "$cpu_hz" ]]; then
    bench_args+=(--cpu-hz "$cpu_hz")
  fi

  printf '\n== Cuishen-%s x86 AVX2/BMI2 benchmark ==\n' "$bits"
  "$exe" "${bench_args[@]}"
}

for bits in "${bits_list[@]}"; do
  exe="${out:-$bin_dir/ngcc_cuishen_${bits}_x86_avx2_bmi2_benchmark}"
  printf '\n== Build Cuishen-%s x86 AVX2/BMI2 benchmark ==\n' "$bits"
  build_one "$bits" "$exe"
  printf 'Built benchmark: %s\n' "$exe"
  if ((build_only == 0)); then
    run_one "$bits" "$exe"
  fi
done

printf '\nSelf-evaluation directory: %s\n' "$SCRIPT_DIR"
printf 'Benchmark executable dir: %s\n' "$bin_dir"
