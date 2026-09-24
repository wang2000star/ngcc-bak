#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CC="${CC:-/usr/bin/gcc}"
BASE_CFLAGS="-std=c99 -Wall -Wextra -Werror"
TMPDIR="$(mktemp -d)"
export PYTHONDONTWRITEBYTECODE=1
trap 'rm -rf "$TMPDIR"' EXIT

cd "$ROOT"
PARAMETERS_SHA256="$(shasum -a 256 "$ROOT/parameters.json" | awk '{print $1}')"

check_parameters_unchanged() {
  local current
  current="$(shasum -a 256 "$ROOT/parameters.json" | awk '{print $1}')"
  if [ "$current" != "$PARAMETERS_SHA256" ]; then
    echo "parameters.json changed during release_check" >&2
    echo "before: $PARAMETERS_SHA256" >&2
    echo "after:  $current" >&2
    return 1
  fi
}

profile_rows() {
  PYTHONPATH="$ROOT" python3 - <<'PY'
from tools.profile_manifest import load_profiles
for p in load_profiles():
    print(f"{p.name} {p.kat_suffix}")
PY
}

build_kat_instance() {
  local dir="$1"
  local extra_make="${2:-}"
  make -C "$dir" clean >/dev/null
  if [ -n "$extra_make" ]; then
    make -C "$dir" CC="$CC" CFLAGS="$BASE_CFLAGS -O3 -fomit-frame-pointer -DKAT_BUILD" $extra_make
  else
    make -C "$dir" CC="$CC" CFLAGS="$BASE_CFLAGS -O3 -fomit-frame-pointer -DKAT_BUILD"
  fi
}

have_avx2() {
  "$CC" -mavx2 -E -x c /dev/null >/dev/null 2>&1 &&     grep -qw avx2 /proc/cpuinfo 2>/dev/null
}

build_optimized_kat_instance() {
  local dir="$1"
  local mode="$2"
  local flags="$BASE_CFLAGS -O3 -fomit-frame-pointer -DKAT_BUILD"
  if [ "$mode" = "1" ]; then
    flags="$flags -mavx2 -march=native"
  fi
  make -C "$dir" clean >/dev/null
  make -C "$dir" CC="$CC" CFLAGS="$flags" AVX2="$mode"
}

compile_sampler_check() {
  local name="$1"
  local dir="$ROOT/API_PKC/Implementations/Reference_Implementation/$name"
  local bin="$TMPDIR/sampler_$name"
  "$CC" $BASE_CFLAGS -O2 -I"$dir" \
    "$ROOT/tests/sampler_check.c" \
    "$dir/poly.c" "$dir/toom.c" "$dir/fips202.c" "$dir/crypto_stream_chacha20.c" \
    -o "$bin" -lm
  "$bin"
}


prepare_poly_mul_check() {
  cat > "$TMPDIR/poly_mul_check.c" <<'EOF'
#include "poly.h"
#include "params.h"
#include <stdint.h>
#include <stdio.h>
#include <string.h>

static uint32_t st = 0x7f4a7c15u;
static uint32_t rnd32(void)
{
  uint32_t x = st;
  x ^= x << 13;
  x ^= x >> 17;
  x ^= x << 5;
  st = x;
  return x;
}

static uint16_t encode_small(int x)
{
  return (uint16_t)((x + PARAM_Q) & (PARAM_Q - 1));
}

static int check_equal(const poly *a, const poly *b, int trial, const char *kind)
{
  int i;
  for(i = 0; i < PARAM_N; i++) {
    if(a->coeffs[i] != b->coeffs[i]) {
      fprintf(stderr, "%s mismatch trial=%d i=%d ref=%u avx2=%u\n",
              kind, trial, i, (unsigned)a->coeffs[i], (unsigned)b->coeffs[i]);
      return 0;
    }
  }
  return 1;
}

int main(void)
{
  poly a, small, ref, got, alias;
  int t;
  int i;

  memset(&a, 0, sizeof(a));
  memset(&small, 0, sizeof(small));
  a.coeffs[0] = 1;
  small.coeffs[PARAM_N - 1] = encode_small(1);
  poly_convolution(&ref, &a, &small);
  poly_mul_small(&got, &a, &small);
  if(!check_equal(&ref, &got, -1, "basis-wrap"))
    return 1;

  for(t = 0; t < 24; t++) {
    for(i = 0; i < PARAM_N; i++) {
      int sv = (int)(rnd32() % (2u * PARAM_K + 1u)) - PARAM_K;
      a.coeffs[i] = (uint16_t)(rnd32() & (PARAM_Q - 1));
      small.coeffs[i] = encode_small(sv);
    }

    poly_convolution(&ref, &a, &small);
    poly_mul_small(&got, &a, &small);
    if(!check_equal(&ref, &got, t, "normal"))
      return 1;

    alias = a;
    poly_mul_small(&alias, &alias, &small);
    if(!check_equal(&ref, &alias, t, "alias-a"))
      return 1;

    alias = small;
    poly_mul_small(&alias, &a, &alias);
    if(!check_equal(&ref, &alias, t, "alias-small"))
      return 1;
  }

  printf("poly_mul_small differential: n=%d eta=%d trials=24 PASS\n",
         PARAM_N, PARAM_K);
  return 0;
}
EOF
}

compile_poly_mul_check() {
  local name="$1"
  local sanitize="${2:-0}"
  local dir="$ROOT/API_PKC/Implementations/Optimized_Implementation/$name"
  local bin="$TMPDIR/poly_mul_${name}_${sanitize}"
  local flags="$BASE_CFLAGS -O3 -mavx2 -march=native"
  if [ "$sanitize" = "1" ]; then
    flags="$BASE_CFLAGS -O1 -g -mavx2 -march=native -fsanitize=address,undefined -fno-omit-frame-pointer"
  fi
  "$CC" $flags -I"$dir" \
    "$TMPDIR/poly_mul_check.c" \
    "$dir/poly.c" "$dir/toom.c" "$dir/fips202.c" \
    "$dir/crypto_stream_chacha20.c" "$dir/chacha.S" \
    -o "$bin" -lm
  ASAN_OPTIONS=detect_leaks=0 "$bin"
}

compile_api_check() {
  local name="$1"
  local compiler="$2"
  local flags="$3"
  local suffix="$4"
  local dir="$ROOT/API_PKC/Implementations/Reference_Implementation/$name"
  local bin="$TMPDIR/api_${name}_${suffix}"
  "$compiler" $flags -I"$dir" \
    "$dir/KEX_AlgorithmInstance.c" "$dir/crypto_stream_chacha20.c" \
    "$dir/poly.c" "$dir/toom.c" "$dir/error_correction.c" "$dir/nike.c" \
    "$dir/reduce.c" "$dir/fips202.c" "$dir/drng.c" \
    "$ROOT/API_PKC/Internal_Tests/NGCC_API/api_check.c" \
    -o "$bin" -lm
  "$bin"
}

check_kat_files() {
  PYTHONPATH="$ROOT" python3 - <<'PY'
from pathlib import Path
from tools.profile_manifest import load_profiles
root = Path("API_PKC")
for p in load_profiles():
    for ext in ("req", "rsp"):
        path = root / "KAT" / p.name / f"PQCkexKAT_{p.kat_suffix}.{ext}"
        if not path.exists():
            raise SystemExit(f"missing {path}")
    raw = root / "Test_Vectors" / f"KAT_KEX_{p.name}.txt"
    if not raw.exists():
        raise SystemExit(f"missing {raw}")
print("KAT filenames: ok")
PY
}

compare_optimized_kats() {
  local mode="$1"
  while read -r name suffix; do
    local opt_dir="$ROOT/API_PKC/Implementations/Optimized_Implementation/$name"
    local ref_log="$ROOT/API_PKC/Test_Vectors/KAT_KEX_${name}.txt"
    local opt_log="$opt_dir/output/KAT_KEX_${name}.txt"
    echo "Ref/Opt KAT compare (AVX2=$mode): $name"
    build_optimized_kat_instance "$opt_dir" "$mode"
    rm -rf "$opt_dir/output"
    (cd "$opt_dir" && ./KAT_KEX >/dev/null)
    cmp "$ref_log" "$opt_log"
    make -C "$opt_dir" clean >/dev/null
  done < <(profile_rows)
}

release_hygiene_check() {
  local bad
  bad="$(
    find "$ROOT" \
      -path "$ROOT/.git" -prune -o \
      \( -name '.DS_Store' -o -name '__MACOSX' -o -name '__pycache__' -o -name '*.pyc' -o -name '*.o' -o -name '*.exe' -o -name 'KAT_KEX' -o -name '*~' -o -name '*.bak' \) \
      -print
  )"
  if [ -n "$bad" ]; then
    echo "release hygiene failed: generated/backup files remain" >&2
    echo "$bad" >&2
    return 1
  fi
  if [ -d "$ROOT/estimator/backups" ]; then
    echo "release hygiene failed: estimator/backups remains" >&2
    return 1
  fi
  if [ -e "$ROOT/API_PKC/run_kat.sh" ] || [ -e "$ROOT/API_PKC/run_kat_new.sh" ]; then
    echo "release hygiene failed: old run_kat scripts remain" >&2
    return 1
  fi
  if find "$ROOT/API_PKC/KAT" -mindepth 1 -maxdepth 1 -type d ! -name 'MAMBA-NIKE-*' | grep -q .; then
    echo "release hygiene failed: old KAT profile directories remain" >&2
    find "$ROOT/API_PKC/KAT" -mindepth 1 -maxdepth 1 -type d ! -name 'MAMBA-NIKE-*' >&2
    return 1
  fi
  if find "$ROOT" -type f -print0 | xargs -0 file | grep -E 'ELF|Mach-O|PE32' >/tmp/mamba_nike_binary_hits.txt; then
    echo "release hygiene failed: binary files remain" >&2
    cat /tmp/mamba_nike_binary_hits.txt >&2
    return 1
  fi
  echo "release hygiene: ok"
}

echo "== 1. manifest consistency =="
python3 tools/profile_manifest.py
check_parameters_unchanged
cat docs/generated/parameters.csv

echo "== 2. Reference clean builds =="
while read -r name suffix; do
  echo "Reference build: $name"
  build_kat_instance "$ROOT/API_PKC/Implementations/Reference_Implementation/$name"
  make -C "$ROOT/API_PKC/Implementations/Reference_Implementation/$name" clean >/dev/null
done < <(profile_rows)

echo "== 3. Optimized clean builds =="
while read -r name suffix; do
  echo "Optimized portable build: $name"
  build_optimized_kat_instance "$ROOT/API_PKC/Implementations/Optimized_Implementation/$name" 0
  make -C "$ROOT/API_PKC/Implementations/Optimized_Implementation/$name" clean >/dev/null
  if have_avx2; then
    echo "Optimized AVX2 build: $name"
    build_optimized_kat_instance "$ROOT/API_PKC/Implementations/Optimized_Implementation/$name" 1
    make -C "$ROOT/API_PKC/Implementations/Optimized_Implementation/$name" clean >/dev/null
  fi
done < <(profile_rows)

echo "== 4. sampler tests =="
while read -r name suffix; do
  compile_sampler_check "$name"
done < <(profile_rows)

echo "== 5. polynomial multiplication differential tests =="
if have_avx2; then
  prepare_poly_mul_check
  while read -r name suffix; do
    compile_poly_mul_check "$name"
  done < <(profile_rows)
  compile_poly_mul_check "MAMBA-NIKE-256" 1
  compile_poly_mul_check "MAMBA-NIKE-512" 1
else
  echo "AVX2 unavailable: differential AVX2 tests skipped"
fi

echo "== 6. API negative/normal tests =="
while read -r name suffix; do
  compile_api_check "$name" "$CC" "$BASE_CFLAGS -O2 -DKAT_BUILD" "o2"
done < <(profile_rows)

echo "== 7. ASan/UBSan tests =="
compile_api_check "MAMBA-NIKE-256" "$CC" "$BASE_CFLAGS -O1 -g -DKAT_BUILD -fsanitize=address,undefined -fno-omit-frame-pointer" "asan"
compile_api_check "MAMBA-NIKE-512" "$CC" "$BASE_CFLAGS -O1 -g -DKAT_BUILD -fsanitize=address,undefined -fno-omit-frame-pointer" "asan"

echo "== 8. compiler/optimization smoke matrix =="
for opt in O0 O2 O3; do
  compile_api_check "MAMBA-NIKE-128" "$CC" "$BASE_CFLAGS -${opt} -DKAT_BUILD" "${opt}_${CC##*/}"
done
if command -v clang >/dev/null 2>&1; then
  for opt in O0 O2 O3; do
    compile_api_check "MAMBA-NIKE-128" clang "$BASE_CFLAGS -${opt} -DKAT_BUILD" "${opt}_clang"
  done
fi

echo "== 9. Reference KAT generation =="
(cd "$ROOT/API_PKC" && CC="$CC" bash generate_all_kats.sh)
cp "$ROOT/API_PKC/KAT_MANIFEST.sha256" "$TMPDIR/KAT_MANIFEST.first"
check_kat_files

echo "== 10. Ref/Opt byte comparison =="
compare_optimized_kats 0
if have_avx2; then
  compare_optimized_kats 1
fi

echo "== 11. KAT reproducibility =="
(cd "$ROOT/API_PKC" && CC="$CC" bash generate_all_kats.sh >/dev/null)
cmp "$TMPDIR/KAT_MANIFEST.first" "$ROOT/API_PKC/KAT_MANIFEST.sha256"

echo "== 12. release tree hygiene =="
check_parameters_unchanged
release_hygiene_check

echo "release_check: PASS"
