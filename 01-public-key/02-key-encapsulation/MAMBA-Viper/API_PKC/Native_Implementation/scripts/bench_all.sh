#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

ROUNDS="${ROUNDS:-1000}"
BENCH_REPEATS="${BENCH_REPEATS:-3}"
RUN_SMOKE="${RUN_SMOKE:-1}"
CC_BIN="${CC:-gcc}"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
RESULTS="$TMPDIR/results.csv"
CSV_OUT="${CSV_OUT:-scripts/results/viper_benchmark_results.csv}"
mkdir -p "$(dirname "$CSV_OUT")"
printf 'scheme,profile,level,backend,implementation,operation_group,operation,cycles,iterations,status,notes,pk_bytes,ct_bytes,sk_bytes,ss_bytes\n' > "$CSV_OUT"
: > "$RESULTS"

REF_FLAGS="-O3 -fomit-frame-pointer -march=native -std=gnu99 -Wall -Wextra"
AVX_FLAGS="-O3 -fomit-frame-pointer -msse2avx -mavx2 -march=native -fno-common -std=gnu99 -Wall -Wextra"

cat > "$TMPDIR/bench_viper.c" <<'C'
#include "api.h"
#include "rng.h"
#include "viper.h"
#include "viper_arith.h"
#include "viper_message_codec.h"
#include "cpucycles.h"
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef ROUNDS
#define ROUNDS 1000
#endif
#if ROUNDS < 1
#error "ROUNDS must be positive"
#endif
#ifndef BENCH_REPEATS
#define BENCH_REPEATS 3
#endif
#if BENCH_REPEATS < 1
#error "BENCH_REPEATS must be positive"
#endif

static unsigned char pk[CRYPTO_PUBLICKEYBYTES], sk[CRYPTO_SECRETKEYBYTES], ct[CRYPTO_CIPHERTEXTBYTES];
static unsigned char ss1[CRYPTO_BYTES], ss2[CRYPTO_BYTES], msg[VIPER_MSGBYTES], rho[32], seed[32], omega[VIPER_FALLBACK_KEY_BYTES + VIPER_MU_BYTES];
static vpoly A[VIPER_K][VIPER_K], p0, p1, pout, msg_poly;
static uint16_t dpk[VIPER_K][VIPER_N];
static vpolyvec sec, mv;

static int cmp_u64(const void *a, const void *b)
{
  uint64_t x = *(const uint64_t *)a, y = *(const uint64_t *)b;
  return (x > y) - (x < y);
}

static uint64_t median(uint64_t *v, size_t n)
{
  qsort(v, n, sizeof(uint64_t), cmp_u64);
  return v[n / 2];
}

#define MEASURE_CYCLES(...) ({ \
  uint64_t best = UINT64_MAX; \
  for (int ri = 0; ri < BENCH_REPEATS; ri++) { \
    uint64_t cyc[ROUNDS]; \
    for (int wi = 0; wi < 16; wi++) { __VA_ARGS__; } \
    for (int mi = 0; mi < ROUNDS; mi++) { \
      uint64_t t0 = cpucycles(); \
      __VA_ARGS__; \
      uint64_t t1 = cpucycles(); \
      cyc[mi] = t1 - t0; \
    } \
    uint64_t med = median(cyc, ROUNDS); \
    if (med < best) best = med; \
  } \
  best; \
})
#define MEASURE(NAME, ...) printf("%s=%llu\n", NAME, (unsigned long long)MEASURE_CYCLES(__VA_ARGS__))

int main(int argc, char **argv)
{
  const char *backend = argc > 1 ? argv[1] : "unknown";
  for (int i = 0; i < VIPER_MSGBYTES; i++) msg[i] = (unsigned char)(i * 3 + 1);
  for (int i = 0; i < 32; i++) {
    rho[i] = (unsigned char)(i + 7);
    seed[i] = (unsigned char)(i * 5 + 9);
  }
  for (size_t i = 0; i < sizeof(omega); i++) omega[i] = (unsigned char)(i * 11 + 3);
  for (size_t i = 0; i < VIPER_N; i++) {
    p0[i] = (uint16_t)(i & VIPER_Q_MASK);
    p1[i] = (uint16_t)((int)(i % (2 * VIPER_ETA_S + 1)) - VIPER_ETA_S) & VIPER_Q_MASK;
  }

  viper_msg_encode(msg_poly, msg);
  viper_msg_decode(msg, msg_poly);
  viper_pke_keypair(pk, sk, rho, seed);
  viper_pke_enc(ct, pk, msg, omega);
  viper_pke_dec(msg, sk, ct);
  crypto_kem_keypair(pk, sk);
  crypto_kem_enc(ct, ss1, pk);
  crypto_kem_dec(ss2, ct, sk);
  if (memcmp(ss1, ss2, CRYPTO_BYTES) != 0) {
    fprintf(stderr, "Viper KEM correctness failed before benchmark\n");
    return 1;
  }
  viper_gen_public(A, dpk, rho);
  viper_sample_secret(sec, seed, VIPER_ETA_S);

  printf("BEGIN,%s,%s,%s,%s,%d,%d,%d\n", CRYPTO_ALGNAME, "Viper", backend, viper_message_codec_name(), VIPER_USE_E8_CODEC, ROUNDS, BENCH_REPEATS);
  viper_backend_report(stdout);
  MEASURE("KEM_KeyGen", crypto_kem_keypair(pk, sk));
  crypto_kem_keypair(pk, sk);
  MEASURE("KEM_Encaps", crypto_kem_enc(ct, ss1, pk));
  crypto_kem_enc(ct, ss1, pk);
  MEASURE("KEM_Decaps", crypto_kem_dec(ss2, ct, sk));
  MEASURE("PKE_KeyGen", viper_pke_keypair(pk, sk, rho, seed));
  viper_pke_keypair(pk, sk, rho, seed);
  MEASURE("PKE_Enc", viper_pke_enc(ct, pk, msg, omega));
  viper_pke_enc(ct, pk, msg, omega);
  MEASURE("PKE_Dec", viper_pke_dec(msg, sk, ct));
  MEASURE("msg_encode", viper_msg_encode(msg_poly, msg));
  viper_msg_encode(msg_poly, msg);
  MEASURE("msg_decode", viper_msg_decode(msg, msg_poly));
  MEASURE("poly_mul", viper_poly_mul(pout, p0, p1));
  MEASURE("A_times_s", viper_matvec(mv, A, sec));
  MEASURE("AT_times_r", viper_matTvec(mv, A, sec));
  MEASURE("bhatT_times_r", viper_dot(pout, mv, sec));
  MEASURE("sT_times_u", viper_dot(pout, sec, mv));
  printf("END\n");
  return 0;
}
C

write_csv_from_log() {
  local log="$1" scheme family backend codec use_e8 rounds repeats
  scheme=$(awk -F, '/^BEGIN/{print $2}' "$log")
  family=$(awk -F, '/^BEGIN/{print $3}' "$log")
  backend=$(awk -F, '/^BEGIN/{print $4}' "$log")
  codec=$(awk -F, '/^BEGIN/{print $5}' "$log")
  use_e8=$(awk -F, '/^BEGIN/{print $6}' "$log")
  rounds=$(awk -F, '/^BEGIN/{print $7}' "$log")
  repeats=$(awk -F, '/^BEGIN/{print $8}' "$log")
  awk -v scheme="$scheme" -v family="$family" -v backend="$backend" -v codec="$codec" -v use_e8="$use_e8" -v rounds="$rounds" -v repeats="$repeats" \
    -F= '/=/{print family "," scheme "," backend "," codec "," use_e8 "," rounds "," repeats "," $1 "," $2}' "$log" >> "$RESULTS"
}

profile_csv_fields() {
  case "$1" in
    128) printf '4096,2,2,2,9,9,4,1,2048,16,16,16,608,736,1424' ;;
    192) printf '4096,3,3,3,10,9,6,1,2048,24,24,24,992,1088,2200' ;;
    256) printf '4096,4,3,3,10,10,5,1,2048,32,32,32,1312,1472,2912' ;;
    384) printf '8192,7,1,1,11,11,5,2,2048,24,48,48,2496,2656,5488' ;;
    512) printf '8192,9,1,1,11,11,8,2,2048,32,64,64,3200,3456,7040' ;;
  esac
}

backend_csv_name() {
  case "$1" in
    "Ref current") printf 'REF' ;;
    "AVX2 current") printf 'AVX2_DEFAULT' ;;
    "AVX2 TCHES2021 NTT all") printf 'AVX2_TCHES2021_NTT' ;;
  esac
}

codec_label() { [[ "$1" == "1" ]] && printf 'E8' || printf 'scalar'; }

getv() {
  local scheme="$1" backend="$2" use_e8="$3" metric="$4"
  awk -F, -v s="$scheme" -v b="$backend" -v c="$use_e8" -v m="$metric" '$2==s && $3==b && $5==c && $8==m {print $9; found=1} END{if(!found) print "n/a"}' "$RESULTS"
}

ratio() {
  awk -v e="$1" -v s="$2" 'BEGIN { if (e == "n/a" || s == "n/a" || s == 0) print "n/a"; else printf "%.2fx", e / s }'
}

write_wide_csv() {
  for level in 128 192 256 384 512; do
    local scheme="MAMBA-Viper-$level"
    local prof="$(profile_csv_fields "$level")"
    IFS=, read -r q k eta_s eta_r t_pk t_u t_v e8_rate e8_alpha active msg_bytes ss_bytes pk_bytes ct_bytes sk_bytes <<< "$prof"
    for backend in "Ref current" "AVX2 current" "AVX2 TCHES2021 NTT all"; do
      local bcsv="$(backend_csv_name "$backend")"
      local impl="Reference"
      [[ "$bcsv" == AVX2* ]] && impl="AVX2"
      for use_e8 in 0 1; do
        local codec="$(codec_label "$use_e8")"
        local notes="codec=$codec use_e8=$use_e8 q=$q k=$k eta_s=$eta_s eta_r=$eta_r t_pk=$t_pk t_u=$t_u t_v=$t_v e8_rate=$e8_rate e8_alpha=$e8_alpha e8_active_blocks=$active msg_bytes=$msg_bytes"
        [[ "$bcsv" == "AVX2_TCHES2021_NTT" ]] && notes="$notes auxiliary-prime-CRT-NTT"
        for op in KEM_KeyGen KEM_Encaps KEM_Decaps PKE_KeyGen PKE_Enc PKE_Dec msg_encode msg_decode poly_mul A_times_s AT_times_r bhatT_times_r sT_times_u; do
          local group="arithmetic"
          [[ "$op" == KEM_* ]] && group="KEM"
          [[ "$op" == PKE_* ]] && group="PKE"
          [[ "$op" == msg_* ]] && group="message_codec"
          local cycles="$(getv "$scheme" "$backend" "$use_e8" "$op")"
          local status="ok"
          [[ "$cycles" == "n/a" ]] && status="skipped" && notes="$notes benchmark unavailable"
          printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
            "$scheme" "Viper-$level" "$level" "$bcsv" "$impl" "$group" "$op" "$cycles" "$ROUNDS" "$status" "$notes" "$pk_bytes" "$ct_bytes" "$sk_bytes" "$ss_bytes" >> "$CSV_OUT"
        done
      done
    done
  done
}

build_ref_current() {
  local level="$1" use_e8="$2" out="$TMPDIR/ref_current_${level}_${use_e8}"
  "$CC_BIN" $REF_FLAGS -DVIPER_LEVEL="$level" -DVIPER_USE_E8_CODEC="$use_e8" -DROUNDS="$ROUNDS" -DBENCH_REPEATS="$BENCH_REPEATS" \
    -IReference_Implementation_KEM -IReference_Implementation_KEM/test \
    -o "$out" \
    Reference_Implementation_KEM/viper.c Reference_Implementation_KEM/viper_arith.c \
    Reference_Implementation_KEM/viper_message_codec.c Reference_Implementation_KEM/viper_e8.c \
    Reference_Implementation_KEM/fips202.c Reference_Implementation_KEM/verify.c \
    Reference_Implementation_KEM/rng.c Reference_Implementation_KEM/kem.c \
    Reference_Implementation_KEM/test/cpucycles.c "$TMPDIR/bench_viper.c" -lcrypto
  printf '%s\n' "$out"
}

build_avx_current() {
  local level="$1" use_e8="$2" out="$TMPDIR/avx_current_${level}_${use_e8}"
  "$CC_BIN" $AVX_FLAGS -DVIPER_LEVEL="$level" -DVIPER_USE_E8_CODEC="$use_e8" -DVIPER_ARITH_AVX -DROUNDS="$ROUNDS" -DBENCH_REPEATS="$BENCH_REPEATS" \
    -IAVX_Implementation_KEM -IAVX_Implementation_KEM/test \
    -o "$out" \
    AVX_Implementation_KEM/viper.c AVX_Implementation_KEM/viper_arith.c \
    AVX_Implementation_KEM/viper_message_codec.c AVX_Implementation_KEM/viper_e8.c \
    AVX_Implementation_KEM/polymul/toom-cook_4way.c \
    AVX_Implementation_KEM/fips202x4.c AVX_Implementation_KEM/keccak4x/KeccakP-1600-times4-SIMD256.c \
    AVX_Implementation_KEM/fips202.c AVX_Implementation_KEM/verify.c \
    AVX_Implementation_KEM/rng.c AVX_Implementation_KEM/kem.c \
    AVX_Implementation_KEM/test/cpucycles.c "$TMPDIR/bench_viper.c" -lcrypto
  printf '%s\n' "$out"
}

build_avx_tches_ntt_all() {
  local level="$1" use_e8="$2" out="$TMPDIR/avx_tches_ntt_all_${level}_${use_e8}"
  "$CC_BIN" $AVX_FLAGS -DVIPER_LEVEL="$level" -DVIPER_USE_E8_CODEC="$use_e8" -DVIPER_ARITH_AVX \
    -DVIPER_EXPERIMENTAL_TCHES2021_NTT=1 -DROUNDS="$ROUNDS" -DBENCH_REPEATS="$BENCH_REPEATS" \
    -IAVX_Implementation_KEM -IAVX_Implementation_KEM/test -IAVX_Implementation_KEM/tches2021_ntt \
    -o "$out" \
    AVX_Implementation_KEM/viper.c AVX_Implementation_KEM/viper_arith.c \
    AVX_Implementation_KEM/viper_message_codec.c AVX_Implementation_KEM/viper_e8.c \
    AVX_Implementation_KEM/polymul/toom-cook_4way.c \
    AVX_Implementation_KEM/tches2021_ntt/viper_tches2021_ntt.c \
    AVX_Implementation_KEM/tches2021_ntt/poly.c AVX_Implementation_KEM/tches2021_ntt/polyvec.c \
    AVX_Implementation_KEM/tches2021_ntt/aes256ctr.c AVX_Implementation_KEM/tches2021_ntt/cbd.c \
    AVX_Implementation_KEM/tches2021_ntt/ntt256n.S AVX_Implementation_KEM/tches2021_ntt/invntt256n.S \
    AVX_Implementation_KEM/tches2021_ntt/basemul256x1.S \
    AVX_Implementation_KEM/tches2021_ntt/consts256n7681.c AVX_Implementation_KEM/tches2021_ntt/consts256n10753.c \
    AVX_Implementation_KEM/fips202x4.c AVX_Implementation_KEM/keccak4x/KeccakP-1600-times4-SIMD256.c \
    AVX_Implementation_KEM/fips202.c AVX_Implementation_KEM/verify.c \
    AVX_Implementation_KEM/rng.c AVX_Implementation_KEM/kem.c \
    AVX_Implementation_KEM/test/cpucycles.c "$TMPDIR/bench_viper.c" -lcrypto
  printf '%s\n' "$out"
}

smoke_correctness() {
  for use_e8 in 0 1; do
    for level in 128 192 256 384 512; do
      echo "== Smoke validation codec=$use_e8 LEVEL $level ==" >&2
      make -C Reference_Implementation_KEM clean >/dev/null
      make -C Reference_Implementation_KEM LEVEL="$level" VIPER_USE_E8_CODEC="$use_e8" test/viper_validation test/viper_codec_validation >/dev/null
      Reference_Implementation_KEM/test/viper_codec_validation >/dev/null
      Reference_Implementation_KEM/test/viper_validation 10 >/dev/null
      make -C AVX_Implementation_KEM clean >/dev/null
      make -C AVX_Implementation_KEM LEVEL="$level" VIPER_USE_E8_CODEC="$use_e8" test/viper_validation test/viper_codec_validation >/dev/null
      AVX_Implementation_KEM/test/viper_codec_validation >/dev/null
      AVX_Implementation_KEM/test/viper_validation 10 >/dev/null
      make -C AVX_Implementation_KEM clean >/dev/null
      make -C AVX_Implementation_KEM LEVEL="$level" VIPER_USE_E8_CODEC="$use_e8" VIPER_EXPERIMENTAL_TCHES2021_NTT=1 \
        test/viper_validation test/viper_codec_validation test/viper_ntt_validation >/dev/null
      AVX_Implementation_KEM/test/viper_codec_validation >/dev/null
      AVX_Implementation_KEM/test/viper_validation 10 >/dev/null
      AVX_Implementation_KEM/test/viper_ntt_validation 1000 8 >/dev/null
    done
  done
}

run_backend() {
  local level="$1" backend="$2" use_e8="$3" exe="$4"
  local log="$TMPDIR/${backend}_${level}_${use_e8}.log"
  echo "== Benchmark LEVEL $level codec=$use_e8: $backend ==" >&2
  "$exe" "$backend" > "$log"
  write_csv_from_log "$log"
}

emit_env_report() {
  printf '# Viper scalar vs E8 codec benchmark report\n\n'
  printf '## Environment\n\n'
  printf '* CPU: %s\n' "$(lscpu 2>/dev/null | awk -F: '/Model name/{gsub(/^[ \t]+/,"",$2); print $2; exit}' || true)"
  printf '* OS/kernel: %s\n' "$(uname -srvmo 2>/dev/null || true)"
  printf '* Compiler: %s\n' "$($CC_BIN --version | head -n1)"
  printf '* Reference flags: `%s`\n' "$REF_FLAGS"
  printf '* AVX2 flags: `%s`\n' "$AVX_FLAGS"
  printf '* Timing source: `cpucycles()`; statistic: best median across repeats.\n'
  printf '* ROUNDS=%s, BENCH_REPEATS=%s\n' "$ROUNDS" "$BENCH_REPEATS"
  printf '* CPU frequency/turbo: not fixed by this script; results are development-machine relative numbers, not final paper numbers.\n\n'
}

emit_profile_table() {
  printf '## Profile and E8 settings\n\n'
  printf '| Level | q | k | eta | t_pk/t_u/t_v | msg bytes | ss bytes | pk bytes | ct bytes | sk bytes | E8 rate | E8 active blocks | E8 alpha |\n'
  printf '|---:|---:|---:|---|---|---:|---:|---:|---:|---:|---:|---:|---:|\n'
  printf '| 128 | 4096 | 2 | 2/2 | 9/9/4 | 16 | 16 | 608 | 736 | 1424 | 1 | 16 | 2048 |\n'
  printf '| 192 | 4096 | 3 | 3/3 | 10/9/6 | 24 | 24 | 992 | 1088 | 2200 | 1 | 24 | 2048 |\n'
  printf '| 256 | 4096 | 4 | 3/3 | 10/10/5 | 32 | 32 | 1312 | 1472 | 2912 | 1 | 32 | 2048 |\n'
  printf '| 384 | 8192 | 7 | 1/1 | 11/11/5 | 48 | 48 | 2496 | 2656 | 5488 | 2 | 24 | 2048 |\n'
  printf '| 512 | 8192 | 9 | 1/1 | 11/11/8 | 64 | 64 | 3200 | 3456 | 7040 | 2 | 32 | 2048 |\n\n'
}

emit_kem_table() {
  local backend="$1" title="$2"
  printf '## %s KEM scalar vs E8\n\n' "$title"
  printf '| Level | scalar KeyGen | E8 KeyGen | E8/scalar | scalar Encaps | E8 Encaps | E8/scalar | scalar Decaps | E8 Decaps | E8/scalar |\n'
  printf '|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n'
  for level in 128 192 256 384 512; do
    scheme="MAMBA-Viper-$level"
    skg="$(getv "$scheme" "$backend" 0 KEM_KeyGen)"; ekg="$(getv "$scheme" "$backend" 1 KEM_KeyGen)"
    sen="$(getv "$scheme" "$backend" 0 KEM_Encaps)"; een="$(getv "$scheme" "$backend" 1 KEM_Encaps)"
    sde="$(getv "$scheme" "$backend" 0 KEM_Decaps)"; ede="$(getv "$scheme" "$backend" 1 KEM_Decaps)"
    printf '| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n' "$level" "$skg" "$ekg" "$(ratio "$ekg" "$skg")" "$sen" "$een" "$(ratio "$een" "$sen")" "$sde" "$ede" "$(ratio "$ede" "$sde")"
  done
  printf '\n'
}

emit_pke_table() {
  local backend="$1" title="$2"
  printf '## %s PKE scalar vs E8\n\n' "$title"
  printf '| Level | scalar KeyGen | E8 KeyGen | E8/scalar | scalar Enc | E8 Enc | E8/scalar | scalar Dec | E8 Dec | E8/scalar |\n'
  printf '|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|\n'
  for level in 128 192 256 384 512; do
    scheme="MAMBA-Viper-$level"
    skg="$(getv "$scheme" "$backend" 0 PKE_KeyGen)"; ekg="$(getv "$scheme" "$backend" 1 PKE_KeyGen)"
    sen="$(getv "$scheme" "$backend" 0 PKE_Enc)"; een="$(getv "$scheme" "$backend" 1 PKE_Enc)"
    sde="$(getv "$scheme" "$backend" 0 PKE_Dec)"; ede="$(getv "$scheme" "$backend" 1 PKE_Dec)"
    printf '| %s | %s | %s | %s | %s | %s | %s | %s | %s | %s |\n' "$level" "$skg" "$ekg" "$(ratio "$ekg" "$skg")" "$sen" "$een" "$(ratio "$een" "$sen")" "$sde" "$ede" "$(ratio "$ede" "$sde")"
  done
  printf '\n'
}

emit_codec_table() {
  printf '## Message codec microbenchmark\n\n'
  printf '| Level | Backend | scalar encode | E8 encode | E8/scalar encode | scalar decode | E8 decode | E8/scalar decode |\n'
  printf '|---:|---|---:|---:|---:|---:|---:|---:|\n'
  for level in 128 192 256 384 512; do
    scheme="MAMBA-Viper-$level"
    for backend in "Ref current" "AVX2 current" "AVX2 TCHES2021 NTT all"; do
      se="$(getv "$scheme" "$backend" 0 msg_encode)"; ee="$(getv "$scheme" "$backend" 1 msg_encode)"
      sd="$(getv "$scheme" "$backend" 0 msg_decode)"; ed="$(getv "$scheme" "$backend" 1 msg_decode)"
      printf '| %s | %s | %s | %s | %s | %s | %s | %s |\n' "$level" "$backend" "$se" "$ee" "$(ratio "$ee" "$se")" "$sd" "$ed" "$(ratio "$ed" "$sd")"
    done
  done
  printf '\n'
}

emit_arith_table() {
  printf '## Arithmetic breakdown sanity\n\n'
  printf '| Level | Backend | Codec | poly_mul | matvec | matTvec | dot |\n'
  printf '|---:|---|---|---:|---:|---:|---:|\n'
  for level in 128 192 256 384 512; do
    scheme="MAMBA-Viper-$level"
    for backend in "Ref current" "AVX2 current" "AVX2 TCHES2021 NTT all"; do
      for use_e8 in 0 1; do
        printf '| %s | %s | %s | %s | %s | %s | %s |\n' "$level" "$backend" "$(codec_label "$use_e8")" \
          "$(getv "$scheme" "$backend" "$use_e8" poly_mul)" "$(getv "$scheme" "$backend" "$use_e8" A_times_s)" \
          "$(getv "$scheme" "$backend" "$use_e8" AT_times_r)" "$(getv "$scheme" "$backend" "$use_e8" bhatT_times_r)"
      done
    done
  done
  printf '\nArithmetic should be essentially unchanged across scalar/E8; differences here should be treated as benchmark noise unless a build path changes.\n\n'
}

emit_summary() {
  python3 - "$CSV_OUT" <<'PY'
import csv, sys
path=sys.argv[1]
rows=list(csv.DictReader(open(path)))
print('## Benchmark CSV summary\n')
print(f'* Wrote {len(rows)} operation rows to `{path}`.')
print('* Canonical CSV columns: scheme, profile, level, backend, implementation, operation_group, operation, cycles, iterations, status, notes, pk_bytes, ct_bytes, sk_bytes, ss_bytes.')
PY
}

if [[ "$RUN_SMOKE" != "0" ]]; then
  smoke_correctness
fi

for level in 128 192 256 384 512; do
  for use_e8 in 0 1; do
    make -C Reference_Implementation_KEM clean >/dev/null
    run_backend "$level" "Ref current" "$use_e8" "$(build_ref_current "$level" "$use_e8")"
    make -C AVX_Implementation_KEM clean >/dev/null
    run_backend "$level" "AVX2 current" "$use_e8" "$(build_avx_current "$level" "$use_e8")"
    make -C AVX_Implementation_KEM clean >/dev/null
    run_backend "$level" "AVX2 TCHES2021 NTT all" "$use_e8" "$(build_avx_tches_ntt_all "$level" "$use_e8")"
  done
done

write_wide_csv
emit_env_report
printf 'CSV written to `%s`\n\n' "$CSV_OUT"
emit_profile_table
emit_kem_table "Ref current" "Reference"
emit_kem_table "AVX2 current" "AVX2 default"
emit_kem_table "AVX2 TCHES2021 NTT all" "AVX2 TCHES2021 NTT"
emit_pke_table "Ref current" "Reference"
emit_pke_table "AVX2 current" "AVX2 default"
emit_pke_table "AVX2 TCHES2021 NTT all" "AVX2 TCHES2021 NTT"
emit_codec_table
emit_arith_table
emit_summary
