#!/usr/bin/env bash
# ADKEX-128 Reference (portable scalar C). drng/auxfunc are official API_PKC files.
set -e
CC=${CC:-gcc}
$CC -std=c99 -Wpedantic -Wall -Wextra -O2 -fcommon -DADKEX_MODE=128 -DDKE_MODE=128 -DDKE_HASH=0 -DDKE_RANDOM=0 -DDKE_FORCE_SCALAR \
   -I.   sm3.c dke_sm3.c dke_hash.c reduce.c ntt.c poly.c polyvec.c random_sampling.c dke_utils.c packing.c verify.c dkecpa.c dkecca.c randombytes.c  drng.c auxfunc.c adkex_derand.c KEX_AlgorithmInstance.c KAT_KEX.c  -o kat_ADKEX-128 -lm
./kat_ADKEX-128
echo "KAT -> output/KAT_KEX_ADKEX-128.txt"
