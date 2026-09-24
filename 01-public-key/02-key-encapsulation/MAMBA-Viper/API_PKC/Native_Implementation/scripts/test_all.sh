#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

LEVELS=(128 192 256 384 512)
NTT_LEVELS=(128 192 256 384 512)
VALIDATION_TRIALS=1000
ARITH_POLY_TRIALS=100000
ARITH_MAT_TRIALS=256
NTT_POLY_TRIALS=100000
NTT_MAT_TRIALS=64
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

check_tches_report() {
  local level="$1"
  local src="$TMPDIR/tches_report_$level.c"
  local exe="$TMPDIR/tches_report_$level"
  cat > "$src" <<'C'
#include "viper_arith.h"
int main(void) {
  viper_backend_report(stdout);
  return 0;
}
C
  cc -std=gnu99 -DVIPER_LEVEL="$level" -DVIPER_ARITH_AVX -DVIPER_EXPERIMENTAL_TCHES2021_NTT=1 \
    -IAVX_Implementation_KEM -o "$exe" "$src"
  "$exe" > "$TMPDIR/tches_report_$level.txt"
  grep -q '^REPORT,VIPER_EXPERIMENTAL_TCHES2021_NTT,1$' "$TMPDIR/tches_report_$level.txt"
  grep -q '^REPORT,resolved_poly_mul_route,poly_mul_tches2021_ntt_avx$' "$TMPDIR/tches_report_$level.txt"
  grep -q '^REPORT,resolved_matvec_route,matvec_tches2021_ntt_avx$' "$TMPDIR/tches_report_$level.txt"
  grep -q '^REPORT,resolved_matTvec_route,matTvec_tches2021_ntt_avx$' "$TMPDIR/tches_report_$level.txt"
  grep -q '^REPORT,resolved_dot_route,dot_tches2021_ntt_avx$' "$TMPDIR/tches_report_$level.txt"
}

echo "== Ref current correctness =="
for level in "${LEVELS[@]}"; do
  make -C Reference_Implementation_KEM clean >/dev/null
  make -C Reference_Implementation_KEM LEVEL="$level" test/viper_validation >/dev/null
  Reference_Implementation_KEM/test/viper_validation "$VALIDATION_TRIALS"
done

echo "== AVX2 current correctness =="
for level in "${LEVELS[@]}"; do
  make -C AVX_Implementation_KEM clean >/dev/null
  make -C AVX_Implementation_KEM LEVEL="$level" test/viper_validation test/viper_arith_compare >/dev/null
  AVX_Implementation_KEM/test/viper_validation "$VALIDATION_TRIALS"
  AVX_Implementation_KEM/test/viper_arith_compare "$ARITH_POLY_TRIALS" "$ARITH_MAT_TRIALS"
done

echo "== Ref current vs AVX2 current fixed-seed dumps =="
for level in "${LEVELS[@]}"; do
  make -C Reference_Implementation_KEM clean >/dev/null
  make -C AVX_Implementation_KEM clean >/dev/null
  make -C Reference_Implementation_KEM LEVEL="$level" test/viper_validation >/dev/null
  make -C AVX_Implementation_KEM LEVEL="$level" test/viper_validation >/dev/null
  Reference_Implementation_KEM/test/viper_validation 1 > "$TMPDIR/ref-$level.txt"
  AVX_Implementation_KEM/test/viper_validation 1 > "$TMPDIR/avx-$level.txt"
  cmp "$TMPDIR/ref-$level.txt" "$TMPDIR/avx-$level.txt"
  echo "MAMBA-Viper-$level ref-vs-avx fixed-seed dump identical"
done

echo "== AVX2 TCHES2021 NTT all correctness =="
for level in "${NTT_LEVELS[@]}"; do
  make -C AVX_Implementation_KEM clean >/dev/null
  make -C AVX_Implementation_KEM LEVEL="$level" VIPER_EXPERIMENTAL_TCHES2021_NTT=1 \
    test/viper_validation test/viper_ntt_validation >/dev/null
  AVX_Implementation_KEM/test/viper_validation "$VALIDATION_TRIALS"
  AVX_Implementation_KEM/test/viper_ntt_validation "$NTT_POLY_TRIALS" "$NTT_MAT_TRIALS"
  check_tches_report "$level"
done

echo "All correctness checks passed."
