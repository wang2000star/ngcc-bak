# Self-contained NGCC build for Optimized Implementation of SHUTTLE-256.
#
#   make            build the KAT generator (kat_sig) -> ./kat_sig
#   make vectors    build + run it; writes output/KAT_SIG_SHUTTLE-256.txt
#   make clean
#
# This folder is self-contained: no symlinks, no include paths outside it.
# The compile flags are the NGCC-mandated set for this implementation tier.

CC      ?= gcc
MODE     = 256
QSET     = q61441n512
INSTANCE = SHUTTLE-256

CFLAGS  = -O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra -mbmi2 -mpopcnt -mno-avx512f -DUSE_AVX2_NTT -DUSE_AVX2_SAMPLER -DUSE_AVX2_SHAKE4X -DUSE_AVX2_XOF_NWAY
CPPFLAGS = -I. -Intt/$(QSET) -DSHUTTLE_MODE=$(MODE)

# Scheme + ICCS-infra scalar sources (the SM3 Hash-DRBG XOF backend).
SCHEME_SRCS = \
  SIG_AlgorithmInstance.c sign.c polyvec.c sampler.c sampler_u.c irs.c \
  rounding.c packing.c poly.c poly_ntt.c reduce.c rans.c approx_exp.c \
  approx_log.c symmetric.c drng.c auxfunc.c \
  ntt/$(QSET)/ntt_ref.c

# Backend SIMD kernels (vectorized NTT + N-way SM3 XOF).
SIMD_SRCS = $(QSET)/ntt.S $(QSET)/ntt_consts.c symmetric_avx2.c drng_avx2.c auxfunc_avx2.c

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
