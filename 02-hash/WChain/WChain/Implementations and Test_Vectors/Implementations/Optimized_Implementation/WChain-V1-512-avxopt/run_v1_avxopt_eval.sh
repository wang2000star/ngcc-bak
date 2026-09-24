#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

CC="${CC:-gcc}"
BUILD_DIR="${BUILD_DIR:-build_avxopt}"
mkdir -p "$BUILD_DIR"

COMMON_FLAGS=(
  -O3
  -march=x86-64
  -mavx2
  -mtune=native
  -flto
  -fomit-frame-pointer
  -std=c99
  -Wall
  -Wextra
  -Wpedantic
)

NOSIMD_FLAGS=(
  -O3
  -DWCHAIN_DISABLE_SIMD
  -std=c99
  -Wall
  -Wextra
  -Wpedantic
)

{
  date -Is
  uname -a
  "$CC" --version | head -1
  lscpu 2>/dev/null || true
} > "$BUILD_DIR/env.log"

"$CC" "${COMMON_FLAGS[@]}" -DWCHAIN_NO_MAIN -I. \
  KAT_CryptHash.c drng.c CryptHash_AlgorithmInstance.c wchain_c.c \
  -o "$BUILD_DIR/kat_WChain-V1-512_avxopt"
"$BUILD_DIR/kat_WChain-V1-512_avxopt" > "$BUILD_DIR/kat.log"

"$CC" "${COMMON_FLAGS[@]}" -I. bench_v1_avxopt.c -o "$BUILD_DIR/bench_v1_avxopt"
"$BUILD_DIR/bench_v1_avxopt" > "$BUILD_DIR/bench.csv" 2> "$BUILD_DIR/bench.stderr"

"$CC" "${NOSIMD_FLAGS[@]}" -I. bench_v1_avxopt.c -o "$BUILD_DIR/bench_v1_avxopt_nosimd"
"$BUILD_DIR/bench_v1_avxopt_nosimd" > "$BUILD_DIR/bench_nosimd.csv" 2> "$BUILD_DIR/bench_nosimd.stderr"

size "$BUILD_DIR/bench_v1_avxopt" "$BUILD_DIR/bench_v1_avxopt_nosimd" > "$BUILD_DIR/size.log" 2>/dev/null || true
date -Is > "$BUILD_DIR/end.log"
echo "WChain-V1-512-avxopt evaluation artifacts written under $BUILD_DIR"
