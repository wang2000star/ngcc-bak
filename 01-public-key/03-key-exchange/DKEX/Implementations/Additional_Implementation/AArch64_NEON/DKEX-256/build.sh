#!/usr/bin/env bash
# DKEX-256 Additional (arm64 DKE core; ML-DSA reference). Build on an arm64 host (or cross + qemu).
set -e
CC=${CC:-gcc}
CF="-O3 -fcommon -march=armv8.2-a -DDKM_AARCH64 -DDKE_USE_AARCH64 -DDKE_USE_AARCH64_NATIVE -DADKEX_MODE=256 -DDKE_MODE=256 -DDKE_HASH=0 -DDKE_RANDOM=0 -DADKEX_SIG_BACKEND_MLDSA -DADKEX_SIG_MLDSA_LEVEL=5 -DDILITHIUM_MODE=5 -std=c99 -Wpedantic -Wall -Wextra -flto -fomit-frame-pointer"
ASMF="-march=armv8.2-a"
rm -rf obj; mkdir -p obj; i=0
for f in sm3 dke_sm3 dke_hash reduce ntt poly polyvec random_sampling dke_utils packing verify dkecpa drng auxfunc; do $CC $CF   -c $f.c -o obj/c$i.o; i=$((i+1)); done
for s in aarch64/ntt_neon.c aarch64/poly_neon.c aarch64/poly_pack_neon.c aarch64/polyvec_neon.c aarch64/verify_neon.c aarch64/rejsample_neon.c  aarch64-native/dke_aarch64_zetas.c aarch64-native/dke_rej_uniform_table.c ; do $CC $CF   -c "$s" -o obj/c$i.o; i=$((i+1)); done
for s in aarch64-native/ntt_native.S aarch64-native/intt_native.S aarch64-native/poly_reduce_native.S aarch64-native/poly_tomont_native.S aarch64-native/poly_tobytes_native.S aarch64-native/mulcache_native.S aarch64-native/basemul_k2_native.S aarch64-native/basemul_k4_native.S aarch64-native/rej_uniform_native.S aarch64-native/ntt512_compiler.S   ;             do $CC $ASMF   -c "$s" -o obj/a$i.o; i=$((i+1)); done
for f in fips202 ntt packing poly polyvec reduce rounding sign symmetric-shake;   do $CC $CF -Idilithium -c dilithium/$f.c -o obj/d$i.o; i=$((i+1)); done
for f in adkex_derand adkex_sig_mldsa KEX_AlgorithmInstance KAT_KEX randombytes;   do $CC $CF -I.   -Idilithium -c $f.c -o obj/l$i.o; i=$((i+1)); done
case "$(uname -s)" in Linux) LRT=-lrt;; *) LRT=;; esac
$CC -O3 -flto -fomit-frame-pointer obj/*.o -o kat_DKEX-256 -lm $LRT
./kat_DKEX-256
echo "KAT -> output/KAT_KEX_DKEX-256.txt"
