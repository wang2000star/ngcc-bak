CC = gcc
CPPFLAGS ?= -I. -DBWKEM_C512_USE_ICCS_AUXFUNC
CFLAGS ?= -Os -march=x86-64 -mavx2 -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra
LDFLAGS ?=
LDLIBS ?=

BUILD_DIR := build
TEST_DIR := ../../../test
KAT_DIR := ../../../../Test_Vector/resource-optimized
KAT_TARGET := $(KAT_DIR)/KAT_KEM_BW_KEM_C512_AVX2.txt
KAT_LOCAL := $(BUILD_DIR)/output/KAT_KEM_BW_KEM_C512_AVX2.txt

CORE_SRC :=  consts.c	BWcoding.c 	cbd.c 	indcpa.c 	kem.c 	poly.c 	polyvec.c 	randombytes_api.c 	reduce.c 	symmetric-iccs.c 	verify.c 	rejsample.c

API_COMMON_SRC := 	auxfunc.c 	drng.c 	KEM_AlgorithmInstance.c

KAT_SRC := KAT_KEM.c

ASM_SRC := ntt_avx.S invntt_avx.S basemul_avx.S

COMMON_OBJS := $(addprefix $(BUILD_DIR)/,$(CORE_SRC:.c=.o)) 	$(addprefix $(BUILD_DIR)/,$(API_COMMON_SRC:.c=.o)) 	$(addprefix $(BUILD_DIR)/,$(ASM_SRC:.S=.o))
KAT_OBJS := $(COMMON_OBJS) $(addprefix $(BUILD_DIR)/,$(KAT_SRC:.c=.o))

.PHONY: all kat speed test_bwcoding test_polymsg test_bdd_layers test_cbd test_polyvec test_poly_core test_iccs test_gen_matrix codec-test iccs-test clean
.PHONY: resource-test selfeval

all: $(BUILD_DIR)/kat_kem

kat: $(BUILD_DIR)/kat_kem
	cd $(BUILD_DIR) && ./kat_kem
	mkdir -p $(KAT_DIR)
	cp $(KAT_LOCAL) $(KAT_TARGET)
	$(MAKE) clean

speed: $(BUILD_DIR)/test_speed
	./$(BUILD_DIR)/test_speed

selfeval: $(BUILD_DIR)/selfeval
	./$(BUILD_DIR)/selfeval

$(BUILD_DIR)/selfeval: $(COMMON_OBJS) $(TEST_DIR)/selfeval_kem.c $(TEST_DIR)/cpucycles.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $(COMMON_OBJS) $(TEST_DIR)/selfeval_kem.c $(TEST_DIR)/cpucycles.c $(LDLIBS) -o $@

resource-test: $(BUILD_DIR)/resource_test
	./$(BUILD_DIR)/resource_test

test_bwcoding: $(BUILD_DIR)/test_bwcoding
	./$(BUILD_DIR)/test_bwcoding

test_polymsg: $(BUILD_DIR)/test_polymsg
	./$(BUILD_DIR)/test_polymsg

test_bdd_layers: $(BUILD_DIR)/test_bdd_layers
	./$(BUILD_DIR)/test_bdd_layers

test_cbd: $(BUILD_DIR)/test_cbd
	./$(BUILD_DIR)/test_cbd

test_polyvec: $(BUILD_DIR)/test_polyvec
	./$(BUILD_DIR)/test_polyvec

test_poly_core: $(BUILD_DIR)/test_poly_core
	./$(BUILD_DIR)/test_poly_core

codec-test: test_bdd_layers test_bwcoding test_polymsg test_cbd test_polyvec test_poly_core

test_iccs: $(BUILD_DIR)/test_iccs
	./$(BUILD_DIR)/test_iccs

test_gen_matrix: $(BUILD_DIR)/test_gen_matrix
	./$(BUILD_DIR)/test_gen_matrix

iccs-test: test_iccs test_gen_matrix

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.S | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) $(ASFLAGS) -c $< -o $@

$(BUILD_DIR)/kat_kem: $(KAT_OBJS)
	$(CC) $(CFLAGS) $(LDFLAGS) $(KAT_OBJS) $(LDLIBS) -o $@

$(BUILD_DIR)/test_speed: $(COMMON_OBJS) test_speed.c $(TEST_DIR)/cpucycles.c $(TEST_DIR)/speed_print.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $(COMMON_OBJS) test_speed.c $(TEST_DIR)/cpucycles.c $(TEST_DIR)/speed_print.c $(LDLIBS) -o $@

$(BUILD_DIR)/resource_test: $(COMMON_OBJS) $(TEST_DIR)/resource_kem.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $(COMMON_OBJS) $(TEST_DIR)/resource_kem.c $(LDLIBS) -o $@

$(BUILD_DIR)/test_bwcoding: $(COMMON_OBJS) test_bwcoding.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $(COMMON_OBJS) test_bwcoding.c $(LDLIBS) -o $@

$(BUILD_DIR)/test_polymsg: $(COMMON_OBJS) test_polymsg.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $(COMMON_OBJS) test_polymsg.c $(LDLIBS) -o $@

$(BUILD_DIR)/test_bdd_layers: test_bdd_layers.c BWcoding.c | $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) test_bdd_layers.c $(LDLIBS) -o $@

$(BUILD_DIR)/test_cbd: $(COMMON_OBJS) test_cbd.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $(COMMON_OBJS) test_cbd.c $(LDLIBS) -o $@

$(BUILD_DIR)/test_polyvec: $(COMMON_OBJS) test_polyvec.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $(COMMON_OBJS) test_polyvec.c $(LDLIBS) -o $@

$(BUILD_DIR)/test_poly_core: $(COMMON_OBJS) test_poly_core.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $(COMMON_OBJS) test_poly_core.c $(LDLIBS) -o $@

$(BUILD_DIR)/test_iccs: $(COMMON_OBJS) test_iccs.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $(COMMON_OBJS) test_iccs.c $(LDLIBS) -o $@

$(BUILD_DIR)/test_gen_matrix: $(COMMON_OBJS) test_gen_matrix.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) $(COMMON_OBJS) test_gen_matrix.c $(LDLIBS) -o $@

clean:
	rm -rf $(BUILD_DIR)
