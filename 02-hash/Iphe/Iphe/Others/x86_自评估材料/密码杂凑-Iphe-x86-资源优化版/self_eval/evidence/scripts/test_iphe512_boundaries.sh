#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."
CC=${CC:-gcc}
REF_CFLAGS="-std=c99 -Wpedantic -Wall -Wextra -O2"
PERF_CFLAGS="-O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra"
BUILD="build/iphe512_boundaries"
REF_DIR="Implementations/Reference_Implementation/Iphe-512"
PERF_DIR="Implementations/Optimized_Implementation/Performance_Implementation/Iphe-512"

mkdir -p "$BUILD"

# shellcheck disable=SC2086
"$CC" $REF_CFLAGS -I"$REF_DIR" -include CryptHash_AlgorithmInstance.h scripts/test_iphe512_boundaries.c "$REF_DIR/CryptHash_AlgorithmInstance.c" -o "$BUILD/ref_iphe512_boundaries.exe"
# shellcheck disable=SC2086
"$CC" $PERF_CFLAGS -I"$PERF_DIR" -include CryptHash_AlgorithmInstance.h scripts/test_iphe512_boundaries.c "$PERF_DIR/CryptHash_AlgorithmInstance.c" -o "$BUILD/perf_iphe512_boundaries.exe"

"$BUILD/ref_iphe512_boundaries.exe" > "$BUILD/ref.out"
"$BUILD/perf_iphe512_boundaries.exe" > "$BUILD/perf.out"
cmp "$BUILD/ref.out" "$BUILD/perf.out"
echo "PASS Iphe-512 boundary consistency check"
