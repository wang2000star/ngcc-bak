#!/usr/bin/env bash
# DKEX-128 Reference (portable scalar C). drng/auxfunc are official API_PKC files.
#  and dilithium/ have colliding header basenames -> separate -I groups.
set -e
CC=${CC:-gcc}
CF="-std=c99 -Wpedantic -Wall -Wextra -O2 -fcommon -DDKE_FORCE_SCALAR -DADKEX_MODE=128 -DDKE_MODE=128 -DDKE_HASH=0 -DDKE_RANDOM=0 -DADKEX_SIG_BACKEND_MLDSA -DADKEX_SIG_MLDSA_LEVEL=2 -DDILITHIUM_MODE=2"
rm -rf obj; mkdir -p obj
for f in sm3 dke_sm3 dke_hash reduce ntt poly polyvec random_sampling dke_utils packing verify dkecpa drng auxfunc; do $CC $CF   -c $f.c -o obj/core_$f.o; done
for f in fips202 ntt packing poly polyvec reduce rounding sign symmetric-shake;    do $CC $CF -Idilithium -c dilithium/$f.c -o obj/dil_$f.o; done
for f in adkex_derand adkex_sig_mldsa KEX_AlgorithmInstance KAT_KEX randombytes;    do $CC $CF -I.   -Idilithium -c $f.c -o obj/lay_$f.o; done
$CC obj/*.o -o kat_DKEX-128 -lm
./kat_DKEX-128
echo "KAT -> output/KAT_KEX_DKEX-128.txt"
