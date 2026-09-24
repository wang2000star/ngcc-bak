CC = gcc
CPPFLAGS ?= -I. -DBWKEM_C512_USE_ICCS_AUXFUNC
CFLAGS ?= -Os -march=x86-64 -mavx2 -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra
ASFLAGS ?= -Wa,-I.
LDFLAGS ?=
LDLIBS ?=

BUILD_DIR := build
TEST_DIR := ../../../test
KAT_TARGET := ../../../Test_Vector/resource-optimized/KAT_KEX_AFS_KEX_C512_AVX2.txt
KAT_LOCAL := $(BUILD_DIR)/output/KAT_KEX_AFS_KEX_C512_AVX2.txt

CORE_SRC := \
	BWcoding.c \
	cbd.c \
	consts.c \
	indcpa.c \
	kem.c \
	poly.c \
	polyvec.c \
	randombytes_api.c \
	reduce.c \
	symmetric-iccs.c \
	verify.c \
	rejsample.c

API_COMMON_SRC := \
	auxfunc.c \
	drng.c \
	KEX_AlgorithmInstance.c

KAT_SRC := KAT_KEX.c

ASM_SRC := \
	basemul_avx.S \
	invntt_avx.S \
	ntt_avx.S

COMMON_OBJS := $(addprefix $(BUILD_DIR)/,$(CORE_SRC:.c=.o)) \
	$(addprefix $(BUILD_DIR)/,$(API_COMMON_SRC:.c=.o)) \
	$(addprefix $(BUILD_DIR)/,$(ASM_SRC:.S=.o))
KAT_OBJS := $(COMMON_OBJS) $(addprefix $(BUILD_DIR)/,$(KAT_SRC:.c=.o))

.PHONY: all kat speed selfeval clean
.PHONY: resource-test selfeval

all: $(BUILD_DIR)/kat_kex

kat: $(BUILD_DIR)/kat_kex
	cd $(BUILD_DIR) && ./kat_kex
	mkdir -p $(dir $(KAT_TARGET))
	cp $(KAT_LOCAL) $(KAT_TARGET)
	$(MAKE) clean

speed: $(BUILD_DIR)/test_speed
	./$(BUILD_DIR)/test_speed

selfeval: $(BUILD_DIR)/selfeval
	./$(BUILD_DIR)/selfeval

$(BUILD_DIR)/selfeval: $(COMMON_OBJS) $(TEST_DIR)/selfeval_kex.c $(TEST_DIR)/cpucycles.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $(COMMON_OBJS) $(TEST_DIR)/selfeval_kex.c $(TEST_DIR)/cpucycles.c $(LDLIBS) -o $@

resource-test: $(BUILD_DIR)/resource_test
	./$(BUILD_DIR)/resource_test

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.S | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) $(ASFLAGS) -c $< -o $@

$(BUILD_DIR)/kat_kex: $(KAT_OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $(KAT_OBJS) $(LDLIBS) -o $@

$(BUILD_DIR)/test_speed: $(COMMON_OBJS) test_speed.c $(TEST_DIR)/cpucycles.c $(TEST_DIR)/speed_print.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $(COMMON_OBJS) test_speed.c $(TEST_DIR)/cpucycles.c $(TEST_DIR)/speed_print.c $(LDLIBS) -o $@

$(BUILD_DIR)/resource_test: $(COMMON_OBJS) $(TEST_DIR)/resource_kex.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $(COMMON_OBJS) $(TEST_DIR)/resource_kex.c $(LDLIBS) -o $@

clean:
	rm -rf $(BUILD_DIR)
