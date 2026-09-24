CC = gcc
CPPFLAGS ?= -I. -DBWKEM_C256_USE_ICCS_AUXFUNC
CFLAGS ?= -std=c99 -Wpedantic -Wall -Wextra -O2
LDFLAGS ?=
LDLIBS ?=

BUILD_DIR := build
TEST_DIR := ../../test
KAT_TARGET := ../../../Test_Vector/KAT_KEX_AFS_KEX_C256.txt

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

API_COMMON_SRC := \
	auxfunc.c \
	drng.c \
	KEX_AlgorithmInstance.c

KAT_SRC := KAT_KEX.c

COMMON_OBJS := $(addprefix $(BUILD_DIR)/,$(CORE_SRC:.c=.o)) \
	$(addprefix $(BUILD_DIR)/,$(API_COMMON_SRC:.c=.o))
KAT_OBJS := $(COMMON_OBJS) $(addprefix $(BUILD_DIR)/,$(KAT_SRC:.c=.o))

.PHONY: all kat speed selfeval clean

all: $(BUILD_DIR)/kat_kex

kat: $(BUILD_DIR)/kat_kex
	cd $(BUILD_DIR) && ./kat_kex
	$(MAKE) clean

speed: $(BUILD_DIR)/test_speed
	./$(BUILD_DIR)/test_speed

selfeval: $(BUILD_DIR)/selfeval
	./$(BUILD_DIR)/selfeval

$(BUILD_DIR)/selfeval: $(COMMON_OBJS) $(TEST_DIR)/selfeval_kex.c $(TEST_DIR)/cpucycles.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $(COMMON_OBJS) $(TEST_DIR)/selfeval_kex.c $(TEST_DIR)/cpucycles.c $(LDLIBS) -o $@

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/kat_kex: $(KAT_OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $(KAT_OBJS) $(LDLIBS) -o $@

$(BUILD_DIR)/test_speed: $(COMMON_OBJS) test_speed.c $(TEST_DIR)/cpucycles.c $(TEST_DIR)/speed_print.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $(COMMON_OBJS) test_speed.c $(TEST_DIR)/cpucycles.c $(TEST_DIR)/speed_print.c $(LDLIBS) -o $@

clean:
	rm -rf $(BUILD_DIR)
