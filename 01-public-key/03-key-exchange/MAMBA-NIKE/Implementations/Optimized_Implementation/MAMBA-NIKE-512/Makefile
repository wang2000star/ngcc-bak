# Makefile for MAMBA-NIKE KAT KEX — Optimized Implementation
#
# Two build modes:
#   make           — auto-detect AVX2, falls back to portable
#   make AVX2=1    — force AVX2 on (requires x86_64 + AVX2 CPU)
#   make AVX2=0    — portable C only (ARM, generic x86_64, etc.)

CC = /usr/bin/gcc
AR = ar

# --- Choose AVX2 or portable ---
# Auto-enable only when the host reports AVX2.  Unknown hosts use the safe
# portable fallback; callers may explicitly select AVX2=1 after checking CPU
# support, or AVX2=0 for a portable build.
HOST_AVX2 := $(shell   if [ -r /proc/cpuinfo ] && grep -qiw avx2 /proc/cpuinfo; then echo 1;   elif command -v sysctl >/dev/null 2>&1 && sysctl -a 2>/dev/null | grep -qiw avx2; then echo 1;   else echo 0; fi)
AVX2 ?= $(HOST_AVX2)

ifeq ($(AVX2),1)
  CFLAGS   = -std=c99 -Wall -Wextra -O3 -fomit-frame-pointer -DKAT_BUILD -mavx2 -march=native
  ASFLAGS  = -mavx2
  CHACHA_SRC = crypto_stream_chacha20.c
  CHACHA_OBJ = chacha.o
else
  CFLAGS   = -std=c99 -Wall -Wextra -O3 -fomit-frame-pointer -DKAT_BUILD
  CHACHA_SRC = crypto_stream_chacha20.c
  CHACHA_OBJ =
endif

# --- Algorithm source files ---
ALGO_SRC = KEX_AlgorithmInstance.c
CORE_OBJ = poly.o toom.o error_correction.o nike.o reduce.o fips202.o \
           crypto_stream_chacha20.o

# --- KAT framework files ---
KAT_SRC  = KAT_KEX.c auxfunc.c drng.c

all: KAT_KEX

KAT_KEX: $(CORE_OBJ) $(CHACHA_OBJ) $(ALGO_SRC) $(KAT_SRC)
	$(CC) $(CFLAGS) -o KAT_KEX $(ALGO_SRC) $(CORE_OBJ) $(CHACHA_OBJ) $(KAT_SRC) -lm

# --- Core object rules ---
crypto_stream_chacha20.o: crypto_stream_chacha20.c crypto_stream_chacha20.h
	$(CC) $(CFLAGS) -c crypto_stream_chacha20.c

poly.o: poly.c poly.h params.h reduce.h toom.h
	$(CC) $(CFLAGS) -c poly.c

toom.o: toom.c toom.h params.h
	$(CC) $(CFLAGS) -c toom.c

error_correction.o: error_correction.c error_correction.h params.h poly.h
	$(CC) $(CFLAGS) -c error_correction.c

nike.o: nike.c nike.h poly.h error_correction.h fips202.h
	$(CC) $(CFLAGS) -c nike.c

reduce.o: reduce.c reduce.h params.h
	$(CC) $(CFLAGS) -c reduce.c

fips202.o: fips202.c fips202.h
	$(CC) $(CFLAGS) -c fips202.c

# --- Assembly rule (AVX2 only) ---
chacha.o: chacha.S
	$(CC) $(ASFLAGS) -c chacha.S -o chacha.o

run: KAT_KEX
	./KAT_KEX

clean:
	rm -rf KAT_KEX *.o output

.PHONY: all run clean
