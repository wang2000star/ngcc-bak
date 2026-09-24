CC ?= gcc
CFLAGS ?= -std=c99 -O2 -Wall -Wextra

REF_SIG_DIR := Reference_Implementation/Sigurd-128
REF_SIG256_DIR := Reference_Implementation/Sigurd-256
REF_SIG512_DIR := Reference_Implementation/Sigurd-512
OPT_SIG_DIR := Optimized_Implementation/Sigurd-128
OPT_SIG256_DIR := Optimized_Implementation/Sigurd-256
OPT_SIG512_DIR := Optimized_Implementation/Sigurd-512
VECTOR_DIR := ../Test_Vectors
BUILD_DIR := build
BENCHMARK_TIMING_HDR := ../benchmark_timing.h
OPT_CFLAGS := -std=c99 -O3 -DNDEBUG -Wall -Wextra -mavx2 -march=native -mtune=native -flto -fomit-frame-pointer -funroll-loops -falign-functions=32 -falign-loops=32 -fno-semantic-interposition -pthread

BENCHMARK_BIN := $(BUILD_DIR)/benchmark
KAT_SIG_BIN := $(BUILD_DIR)/kat_sig
BENCHMARK256_BIN := $(BUILD_DIR)/benchmark256
KAT_SIG256_BIN := $(BUILD_DIR)/kat_sig256
BENCHMARK512_BIN := $(BUILD_DIR)/benchmark512
KAT_SIG512_BIN := $(BUILD_DIR)/kat_sig512
BENCHMARK_OPT_BIN := $(BUILD_DIR)/benchmark_opt
BENCHMARK_OPT256_BIN := $(BUILD_DIR)/benchmark_opt256
KAT_SIG_OPT256_BIN := $(BUILD_DIR)/kat_sig_opt256
BENCHMARK_OPT_STEPS_BIN := $(BUILD_DIR)/benchmark_opt_steps
BENCHMARK_OPT256_STEPS_BIN := $(BUILD_DIR)/benchmark_opt256_steps
BENCHMARK_OPT512_STEPS_BIN := $(BUILD_DIR)/benchmark_opt512_steps
KAT_SIG_OPT_BIN := $(BUILD_DIR)/kat_sig_opt
BENCHMARK_OPT512_BIN := $(BUILD_DIR)/benchmark_opt512
KAT_SIG_OPT512_BIN := $(BUILD_DIR)/kat_sig_opt512

.PHONY: all benchmark kat_sig benchmark256 kat_sig256 benchmark512 kat_sig512 benchmark_opt benchmark_opt256 kat_sig_opt256 benchmark_opt_steps benchmark_opt256_steps benchmark_opt512_steps kat_sig_opt benchmark_opt512 kat_sig_opt512 test_vectors test_vectors256 test_vectors512 test_vectors_opt test_vectors_opt256 test_vectors_opt512 clean FORCE

REF_SIG_SRCS := \
	$(REF_SIG_DIR)/SIG_AlgorithmInstance.c \
	$(REF_SIG_DIR)/sig_core.c \
	$(REF_SIG_DIR)/rsencode.c \
	$(REF_SIG_DIR)/rsencode_common.c \
	$(REF_SIG_DIR)/auxfunc.c \
	$(REF_SIG_DIR)/drng.c

REF_SIG256_SRCS := \
	$(REF_SIG256_DIR)/SIG_AlgorithmInstance.c \
	$(REF_SIG256_DIR)/sig_core.c \
	$(REF_SIG256_DIR)/rsencode.c \
	$(REF_SIG256_DIR)/rsencode_common.c \
	$(REF_SIG256_DIR)/auxfunc.c \
	$(REF_SIG256_DIR)/drng.c

REF_SIG512_SRCS := \
	$(REF_SIG512_DIR)/SIG_AlgorithmInstance.c \
	$(REF_SIG512_DIR)/sig_core.c \
	$(REF_SIG512_DIR)/rsencode.c \
	$(REF_SIG512_DIR)/rsencode_common.c \
	$(REF_SIG512_DIR)/auxfunc.c \
	$(REF_SIG512_DIR)/drng.c

OPT_SIG_SRCS := \
	$(OPT_SIG_DIR)/SIG_AlgorithmInstance.c \
	$(OPT_SIG_DIR)/sig_core.c \
	$(OPT_SIG_DIR)/rsencode.c \
	$(OPT_SIG_DIR)/rsencode_common.c \
	$(OPT_SIG_DIR)/auxfunc.c \
	$(OPT_SIG_DIR)/drng.c

OPT_SIG256_SRCS := \
	$(OPT_SIG256_DIR)/SIG_AlgorithmInstance.c \
	$(OPT_SIG256_DIR)/sig_core.c \
	$(OPT_SIG256_DIR)/rsencode.c \
	$(OPT_SIG256_DIR)/rsencode_common.c \
	$(OPT_SIG256_DIR)/auxfunc.c \
	$(OPT_SIG256_DIR)/drng.c

OPT_SIG512_SRCS := \
	$(OPT_SIG512_DIR)/SIG_AlgorithmInstance.c \
	$(OPT_SIG512_DIR)/sig_core.c \
	$(OPT_SIG512_DIR)/rsencode.c \
	$(OPT_SIG512_DIR)/rsencode_common.c \
	$(OPT_SIG512_DIR)/auxfunc.c \
	$(OPT_SIG512_DIR)/drng.c

all: benchmark kat_sig

$(BUILD_DIR):
	mkdir -p $@

benchmark: $(BENCHMARK_BIN)

$(BENCHMARK_BIN): ../benchmark_sig128_ref.c $(BENCHMARK_TIMING_HDR) $(REF_SIG_SRCS) | $(BUILD_DIR)
	$(CC) $(CFLAGS) -I.. -I. -I$(REF_SIG_DIR) $(filter %.c,$^) -o $@

kat_sig: $(KAT_SIG_BIN)

$(KAT_SIG_BIN): $(REF_SIG_DIR)/KAT_SIG.c $(REF_SIG_SRCS) $(REF_SIG_DIR)/SIG_AlgorithmInstance.h FORCE | $(BUILD_DIR)
	$(CC) $(CFLAGS) -I.. -I. -I$(REF_SIG_DIR) $(filter %.c,$^) -o $@

benchmark256: $(BENCHMARK256_BIN)

$(BENCHMARK256_BIN): ../benchmark_sig256_ref.c $(BENCHMARK_TIMING_HDR) $(REF_SIG256_SRCS) | $(BUILD_DIR)
	$(CC) $(CFLAGS) -I.. -I. -I$(REF_SIG256_DIR) $(filter %.c,$^) -o $@

kat_sig256: $(KAT_SIG256_BIN)

$(KAT_SIG256_BIN): $(REF_SIG256_DIR)/KAT_SIG.c $(REF_SIG256_SRCS) $(REF_SIG256_DIR)/SIG_AlgorithmInstance.h FORCE | $(BUILD_DIR)
	$(CC) $(CFLAGS) -I.. -I. -I$(REF_SIG256_DIR) $(filter %.c,$^) -o $@

benchmark512: $(BENCHMARK512_BIN)

$(BENCHMARK512_BIN): ../benchmark_sig512_ref.c $(BENCHMARK_TIMING_HDR) $(REF_SIG512_SRCS) | $(BUILD_DIR)
	$(CC) $(CFLAGS) -I.. -I. -I$(REF_SIG512_DIR) $(filter %.c,$^) -o $@

kat_sig512: $(KAT_SIG512_BIN)

$(KAT_SIG512_BIN): $(REF_SIG512_DIR)/KAT_SIG.c $(REF_SIG512_SRCS) $(REF_SIG512_DIR)/SIG_AlgorithmInstance.h FORCE | $(BUILD_DIR)
	$(CC) $(CFLAGS) -I.. -I. -I$(REF_SIG512_DIR) $(filter %.c,$^) -o $@

benchmark_opt: $(BENCHMARK_OPT_BIN)

$(BENCHMARK_OPT_BIN): ../benchmark_sig128_opt.c $(BENCHMARK_TIMING_HDR) $(OPT_SIG_SRCS) | $(BUILD_DIR)
	$(CC) $(OPT_CFLAGS) -I.. -I. -I$(OPT_SIG_DIR) $(filter %.c,$^) -o $@

benchmark_opt256: $(BENCHMARK_OPT256_BIN)

$(BENCHMARK_OPT256_BIN): ../benchmark_sig256_opt.c $(BENCHMARK_TIMING_HDR) $(OPT_SIG256_SRCS) | $(BUILD_DIR)
	$(CC) $(OPT_CFLAGS) -I.. -I. -I$(OPT_SIG256_DIR) $(filter %.c,$^) -o $@

kat_sig_opt256: $(KAT_SIG_OPT256_BIN)

$(KAT_SIG_OPT256_BIN): $(OPT_SIG256_DIR)/KAT_SIG.c $(OPT_SIG256_SRCS) $(OPT_SIG256_DIR)/SIG_AlgorithmInstance.h FORCE | $(BUILD_DIR)
	$(CC) $(OPT_CFLAGS) -I.. -I. -I$(OPT_SIG256_DIR) $(filter %.c,$^) -o $@

benchmark_opt_steps: $(BENCHMARK_OPT_STEPS_BIN)

$(BENCHMARK_OPT_STEPS_BIN): ../benchmark_sig128_opt_steps.c $(OPT_SIG_SRCS) | $(BUILD_DIR)
	$(CC) $(OPT_CFLAGS) -DSIG_PROFILE_STEPS -I.. -I. -I$(OPT_SIG_DIR) $^ -o $@

benchmark_opt256_steps: $(BENCHMARK_OPT256_STEPS_BIN)

$(BENCHMARK_OPT256_STEPS_BIN): ../benchmark_sig256_opt_steps.c $(OPT_SIG256_SRCS) | $(BUILD_DIR)
	$(CC) $(OPT_CFLAGS) -DSIG_PROFILE_STEPS -I.. -I. -I$(OPT_SIG256_DIR) $^ -o $@

benchmark_opt512_steps: $(BENCHMARK_OPT512_STEPS_BIN)

$(BENCHMARK_OPT512_STEPS_BIN): ../benchmark_sig512_opt_steps.c $(OPT_SIG512_SRCS) | $(BUILD_DIR)
	$(CC) $(OPT_CFLAGS) -DSIG_PROFILE_STEPS -I.. -I. -I$(OPT_SIG512_DIR) $^ -o $@

kat_sig_opt: $(KAT_SIG_OPT_BIN)

$(KAT_SIG_OPT_BIN): $(OPT_SIG_DIR)/KAT_SIG.c $(OPT_SIG_SRCS) $(OPT_SIG_DIR)/SIG_AlgorithmInstance.h FORCE | $(BUILD_DIR)
	$(CC) $(OPT_CFLAGS) -I.. -I. -I$(OPT_SIG_DIR) $(filter %.c,$^) -o $@

benchmark_opt512: $(BENCHMARK_OPT512_BIN)

$(BENCHMARK_OPT512_BIN): ../benchmark_sig512_opt.c $(BENCHMARK_TIMING_HDR) $(OPT_SIG512_SRCS) | $(BUILD_DIR)
	$(CC) $(OPT_CFLAGS) -I.. -I. -I$(OPT_SIG512_DIR) $(filter %.c,$^) -o $@

kat_sig_opt512: $(KAT_SIG_OPT512_BIN)

$(KAT_SIG_OPT512_BIN): $(OPT_SIG512_DIR)/KAT_SIG.c $(OPT_SIG512_SRCS) $(OPT_SIG512_DIR)/SIG_AlgorithmInstance.h FORCE | $(BUILD_DIR)
	$(CC) $(OPT_CFLAGS) -I.. -I. -I$(OPT_SIG512_DIR) $(filter %.c,$^) -o $@

test_vectors: kat_sig
	mkdir -p $(VECTOR_DIR)
	rm -rf $(BUILD_DIR)/output
	cd $(BUILD_DIR) && ./$(notdir $(KAT_SIG_BIN))
	mv $(BUILD_DIR)/output/KAT_SIG_Sigurd128_REF.txt $(VECTOR_DIR)/
	rmdir $(BUILD_DIR)/output

test_vectors256: kat_sig256
	mkdir -p $(VECTOR_DIR)
	rm -rf $(BUILD_DIR)/output
	cd $(BUILD_DIR) && ./$(notdir $(KAT_SIG256_BIN))
	mv $(BUILD_DIR)/output/KAT_SIG_Sigurd256_REF.txt $(VECTOR_DIR)/
	rmdir $(BUILD_DIR)/output

test_vectors512: kat_sig512
	mkdir -p $(VECTOR_DIR)
	rm -rf $(BUILD_DIR)/output
	cd $(BUILD_DIR) && ./$(notdir $(KAT_SIG512_BIN))
	mv $(BUILD_DIR)/output/KAT_SIG_Sigurd512_REF.txt $(VECTOR_DIR)/
	rmdir $(BUILD_DIR)/output

test_vectors_opt: kat_sig_opt
	mkdir -p $(VECTOR_DIR)
	rm -rf $(BUILD_DIR)/output
	cd $(BUILD_DIR) && ./$(notdir $(KAT_SIG_OPT_BIN))
	mv $(BUILD_DIR)/output/KAT_SIG_Sigurd128_OPT.txt $(VECTOR_DIR)/
	rmdir $(BUILD_DIR)/output

test_vectors_opt256: kat_sig_opt256
	mkdir -p $(VECTOR_DIR)
	rm -rf $(BUILD_DIR)/output
	cd $(BUILD_DIR) && ./$(notdir $(KAT_SIG_OPT256_BIN))
	mv $(BUILD_DIR)/output/KAT_SIG_Sigurd256_OPT.txt $(VECTOR_DIR)/
	rmdir $(BUILD_DIR)/output

test_vectors_opt512: kat_sig_opt512
	mkdir -p $(VECTOR_DIR)
	rm -rf $(BUILD_DIR)/output
	cd $(BUILD_DIR) && ./$(notdir $(KAT_SIG_OPT512_BIN))
	mv $(BUILD_DIR)/output/KAT_SIG_Sigurd512_OPT.txt $(VECTOR_DIR)/
	rmdir $(BUILD_DIR)/output

clean:
	rm -rf $(BUILD_DIR)

FORCE: