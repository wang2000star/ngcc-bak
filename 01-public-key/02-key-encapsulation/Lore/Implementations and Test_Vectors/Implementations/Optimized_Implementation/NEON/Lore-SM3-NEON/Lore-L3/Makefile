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
ifeq ($(filter arm64 aarch64 armv7l armv8l,$(ARCH)),)
LORE_USE_NEON ?= 0
else
LORE_USE_NEON ?= 1
endif
LORE_USE_NEON_SM3 ?= $(LORE_USE_NEON)
LORE_USE_NEON_CORE ?= $(LORE_USE_NEON)
CFLAGS_NEON :=
ifeq ($(LORE_USE_NEON_SM3),1)
CFLAGS_NEON += -DLORE_USE_NEON_SM3
endif
ifeq ($(LORE_USE_NEON_CORE),1)
CFLAGS_NEON += -DLORE_USE_NEON_CORE
endif

LEVELS := 1 2 3 4

# Per-level flags
CFLAGS_1 := $(CFLAGS_BASE) $(CFLAGS_NEON) -DLORE_LEVEL=1
CFLAGS_2 := $(CFLAGS_BASE) $(CFLAGS_NEON) -DLORE_LEVEL=2
CFLAGS_3 := $(CFLAGS_BASE) $(CFLAGS_NEON) -DLORE_LEVEL=3
CFLAGS_4 := $(CFLAGS_BASE) $(CFLAGS_NEON) -DLORE_LEVEL=4

# API_PKC KAT build:
# force Lore's randombytes() to use drng_algorithm instead of OS entropy
CFLAGS_KAT_1 := $(CFLAGS_1) -DLORE_USE_API_PKC_DRNG
CFLAGS_KAT_2 := $(CFLAGS_2) -DLORE_USE_API_PKC_DRNG
CFLAGS_KAT_3 := $(CFLAGS_3) -DLORE_USE_API_PKC_DRNG
CFLAGS_KAT_4 := $(CFLAGS_4) -DLORE_USE_API_PKC_DRNG

OBJROOT := obj
BINDIR  := .

# Search sources in current dir and test/ dir
VPATH := .:test:simd

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

ifeq ($(LORE_USE_NEON_SM3),1)
SOURCES_BASE += sm3_neon.c
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
	$(CC) $(CFLAGS_1) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

test_lore_2: $(BASE_OBJS_2) $(TEST_OBJS_2)
	$(CC) $(CFLAGS_2) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

test_lore_3: $(BASE_OBJS_3) $(TEST_OBJS_3)
	$(CC) $(CFLAGS_3) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

test_lore_4: $(BASE_OBJS_4) $(TEST_OBJS_4)
	$(CC) $(CFLAGS_4) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

test_speed_1: $(BASE_OBJS_1) $(SPEED_OBJS_1)
	$(CC) $(CFLAGS_1) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

test_speed_2: $(BASE_OBJS_2) $(SPEED_OBJS_2)
	$(CC) $(CFLAGS_2) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

test_speed_3: $(BASE_OBJS_3) $(SPEED_OBJS_3)
	$(CC) $(CFLAGS_3) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

test_speed_4: $(BASE_OBJS_4) $(SPEED_OBJS_4)
	$(CC) $(CFLAGS_4) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

# ------------------------------------------------------------------------------
# Link rules: API_PKC KAT
# ------------------------------------------------------------------------------

KAT_KEM_1: $(KAT_BASE_OBJS_1) $(KAT_API_OBJS_1)
	$(CC) $(CFLAGS_KAT_1) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

KAT_KEM_2: $(KAT_BASE_OBJS_2) $(KAT_API_OBJS_2)
	$(CC) $(CFLAGS_KAT_2) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

KAT_KEM_3: $(KAT_BASE_OBJS_3) $(KAT_API_OBJS_3)
	$(CC) $(CFLAGS_KAT_3) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

KAT_KEM_4: $(KAT_BASE_OBJS_4) $(KAT_API_OBJS_4)
	$(CC) $(CFLAGS_KAT_4) $(CPPFLAGS) $^ -o $@ $(LDFLAGS)

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

$(OBJROOT)/kat3:
	mkdir -p $@

$(OBJROOT)/kat4:
	mkdir -p $@

# ------------------------------------------------------------------------------
# Compile rules: normal builds
# ------------------------------------------------------------------------------

$(OBJROOT)/lvl1/%.o: %.c | $(OBJROOT) $(OBJROOT)/lvl1
	$(CC) $(CFLAGS_1) $(CPPFLAGS) -c $< -o $@

$(OBJROOT)/lvl2/%.o: %.c | $(OBJROOT) $(OBJROOT)/lvl2
	$(CC) $(CFLAGS_2) $(CPPFLAGS) -c $< -o $@

$(OBJROOT)/lvl3/%.o: %.c | $(OBJROOT) $(OBJROOT)/lvl3
	$(CC) $(CFLAGS_3) $(CPPFLAGS) -c $< -o $@

$(OBJROOT)/lvl4/%.o: %.c | $(OBJROOT) $(OBJROOT)/lvl4
	$(CC) $(CFLAGS_4) $(CPPFLAGS) -c $< -o $@

# ------------------------------------------------------------------------------
# Compile rules: API_PKC KAT builds
# ------------------------------------------------------------------------------

$(OBJROOT)/kat1/%.o: %.c | $(OBJROOT) $(OBJROOT)/kat1
	$(CC) $(CFLAGS_KAT_1) $(CPPFLAGS) -c $< -o $@

$(OBJROOT)/kat2/%.o: %.c | $(OBJROOT) $(OBJROOT)/kat2
	$(CC) $(CFLAGS_KAT_2) $(CPPFLAGS) -c $< -o $@

$(OBJROOT)/kat3/%.o: %.c | $(OBJROOT) $(OBJROOT)/kat3
	$(CC) $(CFLAGS_KAT_3) $(CPPFLAGS) -c $< -o $@

$(OBJROOT)/kat4/%.o: %.c | $(OBJROOT) $(OBJROOT)/kat4
	$(CC) $(CFLAGS_KAT_4) $(CPPFLAGS) -c $< -o $@

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