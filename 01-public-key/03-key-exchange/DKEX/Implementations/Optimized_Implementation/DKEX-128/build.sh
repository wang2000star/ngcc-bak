#!/usr/bin/env bash
# DKEX-128 Optimized (DKE core AVX2; ML-DSA NIST reference). DKE hashing via auxfunc (sm3x8 removed).
#  and dilithium/ have colliding header basenames -> separate -I groups.
set -e
CC=${CC:-gcc}
CF="-O3 -mavx2 -fcommon -DDKM_LINUX -DDKE_AVX2_NTT256_ASM -DDKE_NTT512_PACKED -DADKEX_MODE=128 -DDKE_MODE=128 -DDKE_HASH=0 -DDKE_RANDOM=0 -DADKEX_SIG_BACKEND_MLDSA -DADKEX_SIG_MLDSA_LEVEL=2 -DDILITHIUM_MODE=2 -std=c99 -Wpedantic -Wall -Wextra -flto -fomit-frame-pointer -march=x86-64 -mtune=native"
AIF="-Iavx2-linux -Iavx2 -Iavx2-dkek -Iavx2-512p -DDKEK_K=3"
rm -rf obj; mkdir -p obj; i=0
for f in sm3 dke_sm3 dke_hash reduce ntt poly polyvec random_sampling dke_utils packing verify dkecpa drng auxfunc; do $CC $CF   -c $f.c -o obj/c$i.o; i=$((i+1)); done
for s in avx2/ntt_avx2.c avx2/poly_avx2.c avx2/consts_avx2.c avx2/consts512_avx2.c avx2/verify_avx2.c avx2/rejsample_avx2.c avx2-512p/consts.c avx2-dkek/consts.c ;  do $CC $CF   -c "$s" -o obj/c$i.o; i=$((i+1)); done
for s in avx2-linux/ntt256_avx2.S avx2-linux/ntt_dkek_avx2.S avx2-linux/ntt_tobytes_avx2.S avx2-linux/invntt256_avx2.S avx2-linux/invntt_dkek_avx2.S avx2-linux/ntt512_avx2.S avx2-linux/invntt512_avx2.S avx2-linux/basemul_avx2.S avx2-linux/basemul_dkek_avx2.S avx2-linux/basemul512_avx2.S avx2-512/ntt512.S avx2-512p/ntt.S avx2-512p/invntt.S avx2-512p/basemul.S avx2-512p/shuffle.S avx2-512p/fq.S avx2-linux/poly_ops_avx2.S avx2-linux/ntt_large_avx2.S avx2-linux/ntt_large512_avx2.S avx2-linux/ntt_unrolled_avx2.S avx2-dkek/ntt.S avx2-dkek/invntt.S avx2-dkek/basemul.S avx2-dkek/shuffle.S avx2-dkek/fq.S ;  do $CC $CF $AIF   -c "$s" -o obj/a$i.o; i=$((i+1)); done
for f in fips202 ntt packing poly polyvec reduce rounding sign symmetric-shake;    do $CC $CF -Idilithium -c dilithium/$f.c -o obj/d$i.o; i=$((i+1)); done
for f in adkex_derand adkex_sig_mldsa KEX_AlgorithmInstance KAT_KEX randombytes;    do $CC $CF -I.   -Idilithium -c $f.c -o obj/l$i.o; i=$((i+1)); done
$CC -O3 -flto -fomit-frame-pointer obj/*.o -o kat_DKEX-128 -lm
./kat_DKEX-128
echo "KAT -> output/KAT_KEX_DKEX-128.txt"
