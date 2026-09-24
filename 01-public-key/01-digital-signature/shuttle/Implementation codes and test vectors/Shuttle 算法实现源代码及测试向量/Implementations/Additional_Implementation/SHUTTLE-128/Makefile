# Self-contained NGCC build for Additional Implementation of SHUTTLE-128.
#
#   make            build the KAT generator (kat_sig) -> ./kat_sig
#   make vectors    build + run it; writes output/KAT_SIG_SHUTTLE-128.txt
#   make clean
#
# This folder is self-contained: no symlinks, no include paths outside it.
# The compile flags are the NGCC-mandated set for this implementation tier.

CC      ?= gcc
MODE     = 128
QSET     = q15361n256
INSTANCE = SHUTTLE-128

CFLAGS  = -O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra -mbmi2 -mpopcnt -mavx512f -mavx512bw -mavx512dq -mavx512vl -mavx512vbmi2 -DUSE_AVX512_NTT -DUSE_AVX512_SAMPLER -DUSE_AVX512_SHAKE8X -DUSE_AVX512_XOF_NWAY
CPPFLAGS = -I. -Intt/$(QSET) -DSHUTTLE_MODE=$(MODE)

# Scheme + ICCS-infra scalar sources (the SM3 Hash-DRBG XOF backend).
SCHEME_SRCS = \
  SIG_AlgorithmInstance.c sign.c polyvec.c sampler.c sampler_u.c irs.c \
  rounding.c packing.c poly.c poly_ntt.c reduce.c rans.c approx_exp.c \
  approx_log.c symmetric.c drng.c auxfunc.c \
  ntt/$(QSET)/ntt_ref.c

# Backend SIMD kernels (vectorized NTT + N-way SM3 XOF).
SIMD_SRCS = $(QSET)/ntt_avx512.S $(QSET)/ntt_consts_avx512.c symmetric_avx512.c drng_avx512.c auxfunc_avx512.c

ALL_SRCS = $(SCHEME_SRCS) $(SIMD_SRCS)

.PHONY: all vectors clean

all: kat_sig

kat_sig: KAT_SIG.c $(ALL_SRCS)
	$(CC) $(CFLAGS) $(CPPFLAGS) KAT_SIG.c $(ALL_SRCS) -o $@

vectors: kat_sig
	./kat_sig
	@echo "wrote output/KAT_SIG_$(INSTANCE).txt"

clean:
	rm -f kat_sig
	rm -rf output
