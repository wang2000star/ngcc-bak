CC ?= cc
CPPFLAGS ?= -I. -DBWKEM_C256_USE_ICCS_AUXFUNC
CFLAGS ?= -O2 -Wall -Wextra -Wpedantic -std=c99
LDFLAGS ?=
LDLIBS ?=

BUILD_DIR := build

CORE_SRC := \
	BWcoding.c \
	cbd.c \
	indcpa.c \
	kem.c \
	ntt.c \
	poly.c \
	polyvec.c \
	randombytes_api.c \
	reduce.c \
	symmetric-iccs.c \
	verify.c

API_SRC := \
	auxfunc.c \
	drng.c \
	KEX_AlgorithmInstance.c

# Number of measurements used for the median cycle count
NTESTS ?= 1000

OBJS := $(addprefix $(BUILD_DIR)/,$(CORE_SRC:.c=.o)) \
	$(addprefix $(BUILD_DIR)/,$(API_SRC:.c=.o))

KAT_OBJS   := $(OBJS) $(BUILD_DIR)/KAT_KEX.o

.PHONY: all kat clean

all: $(BUILD_DIR)/kat_kex

kat: $(BUILD_DIR)/kat_kex
	cd $(BUILD_DIR) && ./kat_kex
	$(MAKE) clean

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/kat_kex: $(KAT_OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $(KAT_OBJS) $(LDLIBS) -o $@

clean:
	rm -rf $(BUILD_DIR)
