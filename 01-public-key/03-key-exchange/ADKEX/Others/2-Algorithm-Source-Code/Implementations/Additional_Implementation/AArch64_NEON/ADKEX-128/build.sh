#!/usr/bin/env bash
# ADKEX-128 Additional (arm64, ARMv8.4-A native). Build on an arm64 host (or cross + qemu).
set -e
CC=${CC:-gcc}
CF="-O3 -fcommon -march=armv8.2-a -DDKM_AARCH64 -DDKE_USE_AARCH64 -DDKE_USE_AARCH64_NATIVE -DADKEX_MODE=128 -DDKE_MODE=128 -DDKE_HASH=0 -DDKE_RANDOM=0 -I. -std=c99 -Wpedantic -Wall -Wextra -flto -fomit-frame-pointer"
ASMF="-march=armv8.2-a"
rm -rf build; mkdir -p build; i=0
for s in sm3.c dke_sm3.c dke_hash.c reduce.c ntt.c poly.c polyvec.c random_sampling.c dke_utils.c packing.c verify.c dkecpa.c dkecca.c randombytes.c  drng.c auxfunc.c adkex_derand.c KEX_AlgorithmInstance.c KAT_KEX.c  aarch64/ntt_neon.c aarch64/poly_neon.c aarch64/poly_pack_neon.c aarch64/polyvec_neon.c aarch64/verify_neon.c aarch64/rejsample_neon.c  aarch64-native/dke_aarch64_zetas.c aarch64-native/dke_rej_uniform_table.c ; do $CC $CF -c "$s" -o build/c$i.o; i=$((i+1)); done
for s in aarch64-native/ntt_native.S aarch64-native/intt_native.S aarch64-native/poly_reduce_native.S aarch64-native/poly_tomont_native.S aarch64-native/poly_tobytes_native.S aarch64-native/mulcache_native.S aarch64-native/basemul_k2_native.S aarch64-native/basemul_k4_native.S aarch64-native/rej_uniform_native.S aarch64-native/ntt512_compiler.S   ;                                    do $CC $ASMF -c "$s" -o build/a$i.o; i=$((i+1)); done
case "$(uname -s)" in Linux) LRT=-lrt;; *) LRT=;; esac
$CC -O3 -flto -fomit-frame-pointer build/*.o -o kat_ADKEX-128 -lm $LRT
./kat_ADKEX-128
echo "KAT -> output/KAT_KEX_ADKEX-128.txt"
