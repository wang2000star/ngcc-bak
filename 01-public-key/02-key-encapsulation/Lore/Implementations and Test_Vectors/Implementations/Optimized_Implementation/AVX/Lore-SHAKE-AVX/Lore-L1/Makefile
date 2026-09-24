# ==============================================================================
# Lore build system
# - API_PKC submission target: kat_api
# ==============================================================================

CC      := gcc
LDFLAGS :=
CPPFLAGS :=
CFLAGS_BASE := -O3 -Wall -Wextra -Wpedantic -Wmissing-prototypes -Wredundant-decls -Wshadow -Wpointer-arith -fomit-frame-pointer -I.

ARCH := $(shell uname -m)
ifeq ($(filter x86_64 amd64 i386 i686,$(ARCH)),)
LORE_USE_AVX2 ?= 0
else
LORE_USE_AVX2 ?= 1
endif

LORE_USE_AVX2_SHAKE ?= $(LORE_USE_AVX2)

CFLAGS_1 := $(CFLAGS_BASE) -DLORE_LEVEL=1

ifeq ($(LORE_USE_AVX2_SHAKE),1)
CFLAGS_1 += -DLORE_USE_AVX2_SHAKE -mavx2
endif

ifeq ($(LORE_USE_AVX2_POLYMUL_NTT),1)
CFLAGS_1 += -DLORE_USE_AVX2_POLYMUL_NTT -mavx2
endif

CFLAGS_KAT_1 := $(CFLAGS_1) -DLORE_USE_API_PKC_DRNG

OBJROOT := obj
VPATH := .

SOURCES_BASE := \
	kem.c \
	pke.c \
	indcpa.c \
	polyvec.c \
	poly.c \
	ntt.c \
	sampler.c \
	reduce.c \
	symmetric-shake.c \
	fips202.c \
	toomcook.c \
	verify.c \
	bch_codec.c \
	randombytes.c

ifeq ($(LORE_USE_AVX2_SHAKE),1)
SOURCES_BASE += simd/shake_avx2.c
endif

ifeq ($(LORE_USE_AVX2_POLYMUL_NTT),1)
SOURCES_BASE += simd/poly_mul_ntt_avx2.c
endif

SOURCES_APIKAT := \
	KEM_AlgorithmInstance.c \
	KAT_KEM.c \
	drng.c

KAT_BASE_OBJS_1 := $(addprefix $(OBJROOT)/kat1/,$(SOURCES_BASE:.c=.o))
KAT_API_OBJS_1 := $(addprefix $(OBJROOT)/kat1/,$(SOURCES_APIKAT:.c=.o))

KAT_BINS := KAT_KEM_1

all: kat_api

kat_api: $(KAT_BINS)

KAT_KEM_1: $(KAT_BASE_OBJS_1) $(KAT_API_OBJS_1)
	$(CC) $(CFLAGS_KAT_1) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

$(OBJROOT):
	mkdir -p $(OBJROOT)

$(OBJROOT)/kat1:
	mkdir -p $@

$(OBJROOT)/kat1/%.o: %.c | $(OBJROOT) $(OBJROOT)/kat1
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS_KAT_1) $(CPPFLAGS) -c $< -o $@

run_kat_1: KAT_KEM_1
	./KAT_KEM_1

clean:
	rm -rf $(OBJROOT)
	rm -f $(KAT_BINS)
	rm -rf output

.PHONY: all kat_api clean run_kat_1
