# ==============================================================================
# Lore build system
# - normal development targets: test / speed
# - API_PKC submission target: kat_api
# ==============================================================================

CC      := gcc
LDFLAGS :=
CPPFLAGS :=
CFLAGS_BASE := -O3 -DNDEBUG -Wall -Wextra -Wpedantic -Wmissing-prototypes -Wredundant-decls -Wshadow -Wpointer-arith -fomit-frame-pointer -I.
CFLAGS_ARCH ?=

ARCH := $(shell uname -m)
ifeq ($(filter x86_64 amd64 i386 i686,$(ARCH)),)
LORE_USE_AVX2 ?= 0
else
LORE_USE_AVX2 ?= 1
endif

CFLAGS_AVX2 :=
ifeq ($(LORE_USE_AVX2),1)
CFLAGS_AVX2 += -DLORE_USE_AVX2 -mavx2
endif

LORE_USE_AVX2_SM3 ?= $(LORE_USE_AVX2)
CFLAGS_AVX2_SM3 :=
ifeq ($(LORE_USE_AVX2_SM3),1)
CFLAGS_AVX2_SM3 += -DLORE_USE_AVX2_SM3 -mavx2
endif

LEVELS := 1 2 3 4

# Per-level flags
CFLAGS_1 := $(CFLAGS_BASE) $(CFLAGS_AVX2) $(CFLAGS_AVX2_SM3) -DLORE_LEVEL=1
CFLAGS_2 := $(CFLAGS_BASE) $(CFLAGS_AVX2) $(CFLAGS_AVX2_SM3) -DLORE_LEVEL=2
CFLAGS_3 := $(CFLAGS_BASE) $(CFLAGS_AVX2) $(CFLAGS_AVX2_SM3) -DLORE_LEVEL=3
CFLAGS_4 := $(CFLAGS_BASE) $(CFLAGS_AVX2) $(CFLAGS_AVX2_SM3) -DLORE_LEVEL=4

# API_PKC KAT build:
# force Lore's randombytes() to use drng_algorithm instead of OS entropy

CFLAGS_KAT_1 := $(CFLAGS_1) -DLORE_USE_API_PKC_DRNG
CFLAGS_KAT_2 := $(CFLAGS_2) -DLORE_USE_API_PKC_DRNG
CFLAGS_KAT_3 := $(CFLAGS_3) -DLORE_USE_API_PKC_DRNG
CFLAGS_KAT_4 := $(CFLAGS_4) -DLORE_USE_API_PKC_DRNG

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
	symmetric-sm3.c \
	sm3_xof.c \
	sm3.c \
	toomcook.c \
	verify.c \
	bch_codec.c \
	randombytes.c \
	auxfunc.c

ifeq ($(LORE_USE_AVX2_SM3),1)
SOURCES_BASE += simd/sm3_avx2.c
endif

ifeq ($(LORE_USE_AVX2_POLYMUL_NTT),1)
SOURCES_BASE += simd/poly_mul_ntt_avx2.c
CFLAGS_1 += -DLORE_USE_AVX2_POLYMUL_NTT -mavx2
CFLAGS_2 += -DLORE_USE_AVX2_POLYMUL_NTT -mavx2
CFLAGS_3 += -DLORE_USE_AVX2_POLYMUL_NTT -mavx2
CFLAGS_KAT_1 += -DLORE_USE_AVX2_POLYMUL_NTT -mavx2
CFLAGS_KAT_2 += -DLORE_USE_AVX2_POLYMUL_NTT -mavx2
CFLAGS_KAT_3 += -DLORE_USE_AVX2_POLYMUL_NTT -mavx2
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
BASE_OBJS_3 := $(addprefix $(OBJROOT)/lvl3/,$(SOURCES_BASE:.c=.o))
BASE_OBJS_4 := $(addprefix $(OBJROOT)/lvl4/,$(SOURCES_BASE:.c=.o))

TEST_OBJS_1 := $(addprefix $(OBJROOT)/lvl1/,$(SOURCES_TEST_MAIN:.c=.o))
TEST_OBJS_2 := $(addprefix $(OBJROOT)/lvl2/,$(SOURCES_TEST_MAIN:.c=.o))
TEST_OBJS_3 := $(addprefix $(OBJROOT)/lvl3/,$(SOURCES_TEST_MAIN:.c=.o))
TEST_OBJS_4 := $(addprefix $(OBJROOT)/lvl4/,$(SOURCES_TEST_MAIN:.c=.o))

SPEED_OBJS_1 := $(addprefix $(OBJROOT)/lvl1/,$(SOURCES_SPEED_MAIN:.c=.o))
SPEED_OBJS_2 := $(addprefix $(OBJROOT)/lvl2/,$(SOURCES_SPEED_MAIN:.c=.o))
SPEED_OBJS_3 := $(addprefix $(OBJROOT)/lvl3/,$(SOURCES_SPEED_MAIN:.c=.o))
SPEED_OBJS_4 := $(addprefix $(OBJROOT)/lvl4/,$(SOURCES_SPEED_MAIN:.c=.o))

KAT_BASE_OBJS_1 := $(addprefix $(OBJROOT)/kat1/,$(SOURCES_BASE:.c=.o))
KAT_BASE_OBJS_2 := $(addprefix $(OBJROOT)/kat2/,$(SOURCES_BASE:.c=.o))
KAT_BASE_OBJS_3 := $(addprefix $(OBJROOT)/kat3/,$(SOURCES_BASE:.c=.o))
KAT_BASE_OBJS_4 := $(addprefix $(OBJROOT)/kat4/,$(SOURCES_BASE:.c=.o))

KAT_API_OBJS_1 := $(addprefix $(OBJROOT)/kat1/,$(SOURCES_APIKAT:.c=.o))
KAT_API_OBJS_2 := $(addprefix $(OBJROOT)/kat2/,$(SOURCES_APIKAT:.c=.o))
KAT_API_OBJS_3 := $(addprefix $(OBJROOT)/kat3/,$(SOURCES_APIKAT:.c=.o))
KAT_API_OBJS_4 := $(addprefix $(OBJROOT)/kat4/,$(SOURCES_APIKAT:.c=.o))

# ------------------------------------------------------------------------------
# Final targets
# ------------------------------------------------------------------------------

TEST_BINS  := test_lore_1 test_lore_2 test_lore_3 test_lore_4
SPEED_BINS := test_speed_1 test_speed_2 test_speed_3 test_speed_4
KAT_BINS   := KAT_KEM_1 KAT_KEM_2 KAT_KEM_3 KAT_KEM_4

all: kat_api

test: $(TEST_BINS)

speed: $(SPEED_BINS)

kat_api: $(KAT_BINS)

# ------------------------------------------------------------------------------
# Link rules: development
# ------------------------------------------------------------------------------

test_lore_1: $(BASE_OBJS_1) $(TEST_OBJS_1)
	$(CC) $(CFLAGS_1) $(CFLAGS_ARCH) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

test_lore_2: $(BASE_OBJS_2) $(TEST_OBJS_2)
	$(CC) $(CFLAGS_2) $(CFLAGS_ARCH) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

test_lore_3: $(BASE_OBJS_3) $(TEST_OBJS_3)
	$(CC) $(CFLAGS_3) $(CFLAGS_ARCH) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

test_lore_4: $(BASE_OBJS_4) $(TEST_OBJS_4)
	$(CC) $(CFLAGS_4) $(CFLAGS_ARCH) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

test_speed_1: $(BASE_OBJS_1) $(SPEED_OBJS_1)
	$(CC) $(CFLAGS_1) $(CFLAGS_ARCH) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

test_speed_2: $(BASE_OBJS_2) $(SPEED_OBJS_2)
	$(CC) $(CFLAGS_2) $(CFLAGS_ARCH) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

test_speed_3: $(BASE_OBJS_3) $(SPEED_OBJS_3)
	$(CC) $(CFLAGS_3) $(CFLAGS_ARCH) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

test_speed_4: $(BASE_OBJS_4) $(SPEED_OBJS_4)
	$(CC) $(CFLAGS_4) $(CFLAGS_ARCH) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

# ------------------------------------------------------------------------------
# Link rules: API_PKC KAT
# ------------------------------------------------------------------------------

KAT_KEM_1: $(KAT_BASE_OBJS_1) $(KAT_API_OBJS_1)
	$(CC) $(CFLAGS_KAT_1) $(CFLAGS_ARCH) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

KAT_KEM_2: $(KAT_BASE_OBJS_2) $(KAT_API_OBJS_2)
	$(CC) $(CFLAGS_KAT_2) $(CFLAGS_ARCH) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

KAT_KEM_3: $(KAT_BASE_OBJS_3) $(KAT_API_OBJS_3)
	$(CC) $(CFLAGS_KAT_3) $(CFLAGS_ARCH) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

KAT_KEM_4: $(KAT_BASE_OBJS_4) $(KAT_API_OBJS_4)
	$(CC) $(CFLAGS_KAT_4) $(CFLAGS_ARCH) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

# ------------------------------------------------------------------------------
# Object directory creation
# ------------------------------------------------------------------------------

$(OBJROOT):
	mkdir -p $(OBJROOT)

$(OBJROOT)/lvl1:
	mkdir -p $@

$(OBJROOT)/lvl2:
	mkdir -p $@

$(OBJROOT)/lvl3:
	mkdir -p $@

$(OBJROOT)/lvl4:
	mkdir -p $@

$(OBJROOT)/kat1:
	mkdir -p $@

$(OBJROOT)/kat2:
	mkdir -p $@

$(OBJROOT)/kat2/simd:
	mkdir -p $@

$(OBJROOT)/kat3:
	mkdir -p $@

$(OBJROOT)/kat4:
	mkdir -p $@

# ------------------------------------------------------------------------------
# Compile rules: normal builds
# ------------------------------------------------------------------------------

$(OBJROOT)/lvl1/%.o: %.c | $(OBJROOT) $(OBJROOT)/lvl1
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS_1) $(CFLAGS_ARCH) $(CPPFLAGS) -c $< -o $@

$(OBJROOT)/lvl2/%.o: %.c | $(OBJROOT) $(OBJROOT)/lvl2
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS_2) $(CFLAGS_ARCH) $(CPPFLAGS) -c $< -o $@

$(OBJROOT)/lvl3/%.o: %.c | $(OBJROOT) $(OBJROOT)/lvl3
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS_3) $(CFLAGS_ARCH) $(CPPFLAGS) -c $< -o $@

$(OBJROOT)/lvl4/%.o: %.c | $(OBJROOT) $(OBJROOT)/lvl4
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS_4) $(CFLAGS_ARCH) $(CPPFLAGS) -c $< -o $@

# ------------------------------------------------------------------------------
# Compile rules: API_PKC KAT builds
# ------------------------------------------------------------------------------

$(OBJROOT)/kat1/%.o: %.c | $(OBJROOT) $(OBJROOT)/kat1
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS_KAT_1) $(CFLAGS_ARCH) $(CPPFLAGS) -c $< -o $@

$(OBJROOT)/kat2/%.o: %.c | $(OBJROOT) $(OBJROOT)/kat2 $(OBJROOT)/kat2/simd
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS_KAT_2) $(CFLAGS_ARCH) $(CPPFLAGS) -c $< -o $@


$(OBJROOT)/kat3/%.o: %.c | $(OBJROOT) $(OBJROOT)/kat3
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS_KAT_3) $(CFLAGS_ARCH) $(CPPFLAGS) -c $< -o $@

$(OBJROOT)/kat4/%.o: %.c | $(OBJROOT) $(OBJROOT)/kat4
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS_KAT_4) $(CFLAGS_ARCH) $(CPPFLAGS) -c $< -o $@

# ------------------------------------------------------------------------------
# Convenience targets
# ------------------------------------------------------------------------------

run_kat_1: KAT_KEM_1
	./KAT_KEM_1

run_kat_2: KAT_KEM_2
	./KAT_KEM_2

run_kat_3: KAT_KEM_3
	./KAT_KEM_3

run_kat_4: KAT_KEM_4
	./KAT_KEM_4

clean:
	rm -rf $(OBJROOT)
	rm -f $(TEST_BINS) $(SPEED_BINS) $(KAT_BINS)
	rm -rf output

.PHONY: all test speed kat_api clean run_kat_1 run_kat_2 run_kat_3 run_kat_4
