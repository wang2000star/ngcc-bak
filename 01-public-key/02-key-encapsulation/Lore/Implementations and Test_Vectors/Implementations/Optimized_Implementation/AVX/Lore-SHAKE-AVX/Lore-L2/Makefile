# ==============================================================================
# Lore build system
# - normal development targets: test / speed
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

LEVELS := 2

# Per-level flags
CFLAGS_1 := $(CFLAGS_BASE) -DLORE_LEVEL=1
CFLAGS_2 := $(CFLAGS_BASE) -DLORE_LEVEL=2

ifeq ($(LORE_USE_AVX2_SHAKE),1)
CFLAGS_1 += -DLORE_USE_AVX2_SHAKE -mavx2
CFLAGS_2 += -DLORE_USE_AVX2_SHAKE -mavx2
endif

# --- AVX2 poly_mul_ntt kernel (cross-family, L2 only) ---
ifeq ($(LORE_USE_AVX2_POLYMUL_NTT),1)
CFLAGS_1 += -DLORE_USE_AVX2_POLYMUL_NTT -mavx2
CFLAGS_2 += -DLORE_USE_AVX2_POLYMUL_NTT -mavx2
endif

# API_PKC KAT build:
# force Lore's randombytes() to use drng_algorithm instead of OS entropy
CFLAGS_KAT_1 := $(CFLAGS_1) -DLORE_USE_API_PKC_DRNG
CFLAGS_KAT_2 := $(CFLAGS_2) -DLORE_USE_API_PKC_DRNG

OBJROOT := obj
BINDIR  := .

# Search sources in current dir and test/ dir
VPATH := .:test

# ------------------------------------------------------------------------------
# Source file groups
# ------------------------------------------------------------------------------

# Lore core
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

# Development executables
SOURCES_TEST_MAIN := test_lore.c
SOURCES_SPEED_MAIN := test_speed.c cpucycles.c speed_print.c

# API_PKC submission KAT
SOURCES_APIKAT := \
	KEM_AlgorithmInstance.c \
	KAT_KEM.c \
	drng.c

# ------------------------------------------------------------------------------
# Derived paths
# ------------------------------------------------------------------------------

BASE_OBJS_1 := $(addprefix $(OBJROOT)/lvl1/,$(SOURCES_BASE:.c=.o))
BASE_OBJS_2 := $(addprefix $(OBJROOT)/lvl2/,$(SOURCES_BASE:.c=.o))

TEST_OBJS_1 := $(addprefix $(OBJROOT)/lvl1/,$(SOURCES_TEST_MAIN:.c=.o))
TEST_OBJS_2 := $(addprefix $(OBJROOT)/lvl2/,$(SOURCES_TEST_MAIN:.c=.o))

SPEED_OBJS_1 := $(addprefix $(OBJROOT)/lvl1/,$(SOURCES_SPEED_MAIN:.c=.o))
SPEED_OBJS_2 := $(addprefix $(OBJROOT)/lvl2/,$(SOURCES_SPEED_MAIN:.c=.o))

KAT_BASE_OBJS_1 := $(addprefix $(OBJROOT)/kat1/,$(SOURCES_BASE:.c=.o))
KAT_BASE_OBJS_2 := $(addprefix $(OBJROOT)/kat2/,$(SOURCES_BASE:.c=.o))

KAT_API_OBJS_1 := $(addprefix $(OBJROOT)/kat1/,$(SOURCES_APIKAT:.c=.o))
KAT_API_OBJS_2 := $(addprefix $(OBJROOT)/kat2/,$(SOURCES_APIKAT:.c=.o))

# ------------------------------------------------------------------------------
# Final targets
# ------------------------------------------------------------------------------

TEST_BINS  := test_lore_1 test_lore_2
SPEED_BINS := test_speed_1 test_speed_2
KAT_BINS   := KAT_KEM_1 KAT_KEM_2

all: kat_api

test: $(TEST_BINS)

speed: $(SPEED_BINS)

kat_api: $(KAT_BINS)

# ------------------------------------------------------------------------------
# Link rules: development
# ------------------------------------------------------------------------------

test_lore_1: $(BASE_OBJS_1) $(TEST_OBJS_1)
	$(CC) $(CFLAGS_1) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

test_lore_2: $(BASE_OBJS_2) $(TEST_OBJS_2)
	$(CC) $(CFLAGS_2) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

test_speed_1: $(BASE_OBJS_1) $(SPEED_OBJS_1)
	$(CC) $(CFLAGS_1) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

test_speed_2: $(BASE_OBJS_2) $(SPEED_OBJS_2)
	$(CC) $(CFLAGS_2) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

# ------------------------------------------------------------------------------
# Link rules: API_PKC KAT
# ------------------------------------------------------------------------------

KAT_KEM_1: $(KAT_BASE_OBJS_1) $(KAT_API_OBJS_1)
	$(CC) $(CFLAGS_KAT_1) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

KAT_KEM_2: $(KAT_BASE_OBJS_2) $(KAT_API_OBJS_2)
	$(CC) $(CFLAGS_KAT_2) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

# ------------------------------------------------------------------------------
# Object directory creation
# ------------------------------------------------------------------------------

$(OBJROOT):
	mkdir -p $(OBJROOT)

$(OBJROOT)/lvl1:
	mkdir -p $@

$(OBJROOT)/lvl2:
	mkdir -p $@

$(OBJROOT)/kat1:
	mkdir -p $@

$(OBJROOT)/kat2:
	mkdir -p $@

# ------------------------------------------------------------------------------
# Compile rules: normal builds
# ------------------------------------------------------------------------------

$(OBJROOT)/lvl1/%.o: %.c | $(OBJROOT) $(OBJROOT)/lvl1
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS_1) $(CPPFLAGS) -c $< -o $@

$(OBJROOT)/lvl2/%.o: %.c | $(OBJROOT) $(OBJROOT)/lvl2
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS_2) $(CPPFLAGS) -c $< -o $@

# ------------------------------------------------------------------------------
# Compile rules: API_PKC KAT builds
# ------------------------------------------------------------------------------

$(OBJROOT)/kat1/%.o: %.c | $(OBJROOT) $(OBJROOT)/kat1
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS_KAT_1) $(CPPFLAGS) -c $< -o $@

$(OBJROOT)/kat2/%.o: %.c | $(OBJROOT) $(OBJROOT)/kat2
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS_KAT_2) $(CPPFLAGS) -c $< -o $@

ifeq ($(LORE_USE_AVX2_POLYMUL_NTT),1)
$(OBJROOT)/kat2/simd/%.o: simd/%.c | $(OBJROOT) $(OBJROOT)/kat2
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS_KAT_2) $(CPPFLAGS) -c $< -o $@
endif

# ------------------------------------------------------------------------------
# Convenience targets
# ------------------------------------------------------------------------------

run_kat_1: KAT_KEM_1
	./KAT_KEM_1

run_kat_2: KAT_KEM_2
	./KAT_KEM_2

clean:
	rm -rf $(OBJROOT)
	rm -f $(TEST_BINS) $(SPEED_BINS) $(KAT_BINS)
	rm -rf output

.PHONY: all test speed kat_api clean run_kat_1 run_kat_2
