CC ?= gcc
CFLAGS ?= -std=c99 -O3 -Wall -Wextra -pedantic
LDFLAGS ?=
OPT_DEFINES := -DAFS_TREDM_OPT64_PORTABLE=1
DISPATCH_COMMON_DIR := ../common/dispatch
S6_SRCS := ../common/s6/afs_lmds1600_s6_opt64.c

# S6-02 canonical AVX2 uses the AVX2 AFS-64 nonlinear layer plus opt64 S6 linear.
AVX2_CFLAGS ?= -std=c99 -O3 -Wall -Wextra -pedantic \
	-DAFS_TREDM_BENCH_IMPL_AVX2=1 \
	-DAFS_TREDM_USE_AVX2=1 \
	-DAFS_TREDM_S6_CANONICAL_AVX2=1 \
	-mavx2

PERF_SPLIT_ROUNDS ?= 12
PERF_CFLAGS ?= $(CFLAGS) -DAFS_TREDM_PERFORMANCE_PROFILE=1 -DAFS_TREDM_TIERED_SPLIT_ROUNDS=$(PERF_SPLIT_ROUNDS)
AVX2_PERF_CFLAGS ?= $(AVX2_CFLAGS) -DAFS_TREDM_PERFORMANCE_PROFILE=1 -DAFS_TREDM_TIERED_SPLIT_ROUNDS=$(PERF_SPLIT_ROUNDS)
PERF_KAT_CFLAGS ?= $(PERF_CFLAGS)
AVX2_PERF_KAT_CFLAGS ?= $(AVX2_PERF_CFLAGS)

COMMON_SRCS = CryptHash_AlgorithmInstance.c afs_sbox64.c $(S6_SRCS) afs_p1600.c afs_tredm.c
KAT_SRCS = KAT_CryptHash.c drng.c $(COMMON_SRCS)
QUICK_SRCS = quick_test.c $(COMMON_SRCS)
HASHCLI_SRCS = hash_cli.c $(COMMON_SRCS)
BENCH_SRCS = benchmark.c $(COMMON_SRCS)
PROFILE_SRCS = profile_info.c
MICROBENCH_SRCS = microbench_rounds.c CryptHash_AlgorithmInstance.c afs_sbox64.c $(S6_SRCS) afs_tredm.c

AVX2_COMMON_SRCS = CryptHash_AlgorithmInstance.c afs_sbox64.c $(S6_SRCS) afs_p1600_avx2.c afs_tredm.c
AVX2_KAT_SRCS = KAT_CryptHash.c drng.c $(AVX2_COMMON_SRCS)
AVX2_QUICK_SRCS = quick_test.c $(AVX2_COMMON_SRCS)
AVX2_HASHCLI_SRCS = hash_cli.c $(AVX2_COMMON_SRCS)
AVX2_BENCH_SRCS = benchmark.c $(AVX2_COMMON_SRCS)

DISPATCH_PORTABLE_SRCS = CryptHash_AlgorithmInstance.c afs_sbox64.c afs_p1600.c afs_tredm.c
DISPATCH_AVX2_SRCS = CryptHash_AlgorithmInstance.c afs_sbox64.c afs_p1600_avx2.c afs_tredm.c
DISPATCH_AVX2_COMPILE ?= 1
DISPATCH_BUILD_MODE := $(if $(filter 1,$(DISPATCH_AVX2_COMPILE)),avx2,portable)
DISPATCH_BUILD_DIR := .dispatch_build_$(DISPATCH_BUILD_MODE)
DISPATCH_PERF_BUILD_DIR := .dispatch_perf_build_$(DISPATCH_BUILD_MODE)
DISPATCH_PORTABLE_OBJS = $(patsubst %.c,$(DISPATCH_BUILD_DIR)/portable/%.o,$(DISPATCH_PORTABLE_SRCS)) $(DISPATCH_BUILD_DIR)/portable/afs_lmds1600_s6_opt64.o
DISPATCH_PERF_PORTABLE_OBJS = $(patsubst %.c,$(DISPATCH_PERF_BUILD_DIR)/portable/%.o,$(DISPATCH_PORTABLE_SRCS)) $(DISPATCH_PERF_BUILD_DIR)/portable/afs_lmds1600_s6_opt64.o
ifeq ($(DISPATCH_AVX2_COMPILE),1)
DISPATCH_AVX2_OBJS = $(patsubst %.c,$(DISPATCH_BUILD_DIR)/avx2/%.o,$(DISPATCH_AVX2_SRCS)) $(DISPATCH_BUILD_DIR)/avx2/afs_lmds1600_s6_opt64.o
DISPATCH_PERF_AVX2_OBJS = $(patsubst %.c,$(DISPATCH_PERF_BUILD_DIR)/avx2/%.o,$(DISPATCH_AVX2_SRCS)) $(DISPATCH_PERF_BUILD_DIR)/avx2/afs_lmds1600_s6_opt64.o
DISPATCH_FEATURE_CFLAGS = -DAFS_TREDM_DISPATCH_HAS_AVX2=1
else
DISPATCH_AVX2_OBJS =
DISPATCH_PERF_AVX2_OBJS =
DISPATCH_FEATURE_CFLAGS =
endif
DISPATCH_COMMON_OBJS = $(DISPATCH_BUILD_DIR)/common/afs_dispatch.o
DISPATCH_PERF_COMMON_OBJS = $(DISPATCH_PERF_BUILD_DIR)/common/afs_dispatch.o
DISPATCH_OBJS = $(DISPATCH_PORTABLE_OBJS) $(DISPATCH_AVX2_OBJS) $(DISPATCH_COMMON_OBJS)
DISPATCH_PERF_OBJS = $(DISPATCH_PERF_PORTABLE_OBJS) $(DISPATCH_PERF_AVX2_OBJS) $(DISPATCH_PERF_COMMON_OBJS)

DISPATCH_RENAME_PORTABLE = \
	-DCryptHash=afs_dispatch_portable_CryptHash \
	-Dafs_tredm_hash=afs_dispatch_portable_afs_tredm_hash \
	-Dafs_p1600_permute=afs_dispatch_portable_afs_p1600_permute \
	-Dafs_p1600_g=afs_dispatch_portable_afs_p1600_g \
	-Dafs_p1600_h=afs_dispatch_portable_afs_p1600_h \
	-Dafs_lmds1600_s6_opt64=afs_dispatch_portable_afs_lmds1600_s6_opt64 \
	-Dafs64_t5_k2=afs_dispatch_portable_afs64_t5_k2

DISPATCH_RENAME_AVX2 = \
	-DCryptHash=afs_dispatch_avx2_CryptHash \
	-Dafs_tredm_hash=afs_dispatch_avx2_afs_tredm_hash \
	-Dafs_p1600_permute=afs_dispatch_avx2_afs_p1600_permute \
	-Dafs_p1600_g=afs_dispatch_avx2_afs_p1600_g \
	-Dafs_p1600_h=afs_dispatch_avx2_afs_p1600_h \
	-Dafs_lmds1600_s6_opt64=afs_dispatch_avx2_afs_lmds1600_s6_opt64 \
	-Dafs64_t5_k2=afs_dispatch_avx2_afs64_t5_k2

.PHONY: all clean kat quick_test hash_cli benchmark run-quick run-benchmark kat-2-12 \
    kat_avx2 quick_test_avx2 hash_cli_avx2 benchmark_avx2 run-quick-avx2 run-benchmark-avx2 kat-2-12-avx2 \
    kat_dispatch quick_test_dispatch hash_cli_dispatch benchmark_dispatch run-quick-dispatch run-benchmark-dispatch kat-2-12-dispatch dispatch-info \
    quick_test_perf hash_cli_perf benchmark_perf kat_perf run-quick-perf run-benchmark-perf kat-2-12-perf \
    quick_test_avx2_perf hash_cli_avx2_perf benchmark_avx2_perf kat_avx2_perf run-quick-avx2-perf run-benchmark-avx2-perf kat-2-12-avx2-perf \
    quick_test_dispatch_perf hash_cli_dispatch_perf benchmark_dispatch_perf kat_dispatch_perf run-quick-dispatch-perf run-benchmark-dispatch-perf kat-2-12-dispatch-perf \
    profile_info_avx2 profile-info profile-info-perf profile-info-avx2 \
    microbench_rounds microbench_rounds_opt64 run-microbench-rounds run-microbench-rounds-opt64

all: kat quick_test hash_cli benchmark

kat: $(KAT_SRCS)
	$(CC) $(CFLAGS) $(OPT_DEFINES) -o $@ $(KAT_SRCS) $(LDFLAGS)

quick_test: $(QUICK_SRCS)
	$(CC) $(CFLAGS) $(OPT_DEFINES) -o $@ $(QUICK_SRCS) $(LDFLAGS)

hash_cli: $(HASHCLI_SRCS)
	$(CC) $(CFLAGS) $(OPT_DEFINES) -o $@ $(HASHCLI_SRCS) $(LDFLAGS)

benchmark: $(BENCH_SRCS)
	$(CC) $(CFLAGS) $(OPT_DEFINES) -o $@ $(BENCH_SRCS) $(LDFLAGS)

profile_info: $(PROFILE_SRCS)
	$(CC) $(CFLAGS) $(OPT_DEFINES) -o $@ $(PROFILE_SRCS) $(LDFLAGS)

profile_info_perf: $(PROFILE_SRCS)
	$(CC) $(PERF_CFLAGS) $(OPT_DEFINES) -o $@ $(PROFILE_SRCS) $(LDFLAGS)

profile_info_avx2: $(PROFILE_SRCS)
	$(CC) $(AVX2_CFLAGS) $(OPT_DEFINES) -o $@ $(PROFILE_SRCS) $(LDFLAGS)

microbench_rounds: $(MICROBENCH_SRCS) afs_p1600.c
	$(CC) $(AVX2_PERF_CFLAGS) $(OPT_DEFINES) -I. -o $@ $(MICROBENCH_SRCS) $(LDFLAGS)

microbench_rounds_opt64: $(MICROBENCH_SRCS) afs_p1600.c
	$(CC) $(PERF_CFLAGS) $(OPT_DEFINES) -I. -o $@ $(MICROBENCH_SRCS) $(LDFLAGS)

kat_perf: $(KAT_SRCS)
	$(CC) $(PERF_KAT_CFLAGS) $(OPT_DEFINES) -o $@ $(KAT_SRCS) $(LDFLAGS)

quick_test_perf: $(QUICK_SRCS)
	$(CC) $(PERF_CFLAGS) $(OPT_DEFINES) -o $@ $(QUICK_SRCS) $(LDFLAGS)

hash_cli_perf: $(HASHCLI_SRCS)
	$(CC) $(PERF_CFLAGS) $(OPT_DEFINES) -o $@ $(HASHCLI_SRCS) $(LDFLAGS)

benchmark_perf: $(BENCH_SRCS)
	$(CC) $(PERF_CFLAGS) $(OPT_DEFINES) -o $@ $(BENCH_SRCS) $(LDFLAGS)

kat_avx2: $(AVX2_KAT_SRCS)
	$(CC) $(AVX2_CFLAGS) $(OPT_DEFINES) -o $@ $(AVX2_KAT_SRCS) $(LDFLAGS)

quick_test_avx2: $(AVX2_QUICK_SRCS)
	$(CC) $(AVX2_CFLAGS) $(OPT_DEFINES) -o $@ $(AVX2_QUICK_SRCS) $(LDFLAGS)

hash_cli_avx2: $(AVX2_HASHCLI_SRCS)
	$(CC) $(AVX2_CFLAGS) $(OPT_DEFINES) -o $@ $(AVX2_HASHCLI_SRCS) $(LDFLAGS)

benchmark_avx2: $(AVX2_BENCH_SRCS)
	$(CC) $(AVX2_CFLAGS) $(OPT_DEFINES) -o $@ $(AVX2_BENCH_SRCS) $(LDFLAGS)

kat_avx2_perf: $(AVX2_KAT_SRCS)
	$(CC) $(AVX2_PERF_KAT_CFLAGS) $(OPT_DEFINES) -o $@ $(AVX2_KAT_SRCS) $(LDFLAGS)

quick_test_avx2_perf: $(AVX2_QUICK_SRCS)
	$(CC) $(AVX2_PERF_CFLAGS) $(OPT_DEFINES) -o $@ $(AVX2_QUICK_SRCS) $(LDFLAGS)

hash_cli_avx2_perf: $(AVX2_HASHCLI_SRCS)
	$(CC) $(AVX2_PERF_CFLAGS) $(OPT_DEFINES) -o $@ $(AVX2_HASHCLI_SRCS) $(LDFLAGS)

benchmark_avx2_perf: $(AVX2_BENCH_SRCS) microbench_rounds
	$(CC) $(AVX2_PERF_CFLAGS) $(OPT_DEFINES) -o $@ $(AVX2_BENCH_SRCS) $(LDFLAGS)

$(DISPATCH_BUILD_DIR)/portable/%.o: %.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(OPT_DEFINES) $(DISPATCH_RENAME_PORTABLE) -c -o $@ $<

$(DISPATCH_BUILD_DIR)/portable/afs_lmds1600_s6_opt64.o: ../common/s6/afs_lmds1600_s6_opt64.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(OPT_DEFINES) $(DISPATCH_RENAME_PORTABLE) -c -o $@ $<

$(DISPATCH_BUILD_DIR)/avx2/%.o: %.c
	@mkdir -p $(@D)
	$(CC) $(AVX2_CFLAGS) $(OPT_DEFINES) $(DISPATCH_RENAME_AVX2) -c -o $@ $<

$(DISPATCH_BUILD_DIR)/avx2/afs_lmds1600_s6_opt64.o: ../common/s6/afs_lmds1600_s6_opt64.c
	@mkdir -p $(@D)
	$(CC) $(AVX2_CFLAGS) $(OPT_DEFINES) $(DISPATCH_RENAME_AVX2) -c -o $@ $<

$(DISPATCH_BUILD_DIR)/common/afs_dispatch.o: $(DISPATCH_COMMON_DIR)/afs_dispatch.c $(DISPATCH_COMMON_DIR)/afs_dispatch.h
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) $(OPT_DEFINES) $(DISPATCH_FEATURE_CFLAGS) -I. -I$(DISPATCH_COMMON_DIR) -c -o $@ $(DISPATCH_COMMON_DIR)/afs_dispatch.c

$(DISPATCH_PERF_BUILD_DIR)/portable/%.o: %.c
	@mkdir -p $(@D)
	$(CC) $(PERF_CFLAGS) $(OPT_DEFINES) $(DISPATCH_RENAME_PORTABLE) -c -o $@ $<

$(DISPATCH_PERF_BUILD_DIR)/portable/afs_lmds1600_s6_opt64.o: ../common/s6/afs_lmds1600_s6_opt64.c
	@mkdir -p $(@D)
	$(CC) $(PERF_CFLAGS) $(OPT_DEFINES) $(DISPATCH_RENAME_PORTABLE) -c -o $@ $<

$(DISPATCH_PERF_BUILD_DIR)/avx2/%.o: %.c
	@mkdir -p $(@D)
	$(CC) $(AVX2_PERF_CFLAGS) $(OPT_DEFINES) $(DISPATCH_RENAME_AVX2) -c -o $@ $<

$(DISPATCH_PERF_BUILD_DIR)/avx2/afs_lmds1600_s6_opt64.o: ../common/s6/afs_lmds1600_s6_opt64.c
	@mkdir -p $(@D)
	$(CC) $(AVX2_PERF_CFLAGS) $(OPT_DEFINES) $(DISPATCH_RENAME_AVX2) -c -o $@ $<

$(DISPATCH_PERF_BUILD_DIR)/common/afs_dispatch.o: $(DISPATCH_COMMON_DIR)/afs_dispatch.c $(DISPATCH_COMMON_DIR)/afs_dispatch.h
	@mkdir -p $(@D)
	$(CC) $(PERF_CFLAGS) $(OPT_DEFINES) $(DISPATCH_FEATURE_CFLAGS) -I. -I$(DISPATCH_COMMON_DIR) -c -o $@ $(DISPATCH_COMMON_DIR)/afs_dispatch.c

quick_test_dispatch: $(DISPATCH_COMMON_DIR)/dispatch_quick_test.c $(DISPATCH_COMMON_DIR)/afs_dispatch.h $(DISPATCH_OBJS)
	$(CC) $(CFLAGS) $(OPT_DEFINES) -I. -I$(DISPATCH_COMMON_DIR) -o $@ $(DISPATCH_COMMON_DIR)/dispatch_quick_test.c $(DISPATCH_OBJS) $(LDFLAGS)

hash_cli_dispatch: hash_cli.c $(DISPATCH_COMMON_DIR)/afs_dispatch.h $(DISPATCH_OBJS)
	$(CC) $(CFLAGS) $(OPT_DEFINES) -I$(DISPATCH_COMMON_DIR) -DCryptHash=CryptHash_dispatch -o $@ hash_cli.c $(DISPATCH_OBJS) $(LDFLAGS)

benchmark_dispatch: benchmark.c $(DISPATCH_COMMON_DIR)/afs_dispatch.h $(DISPATCH_OBJS)
	$(CC) $(CFLAGS) $(OPT_DEFINES) -I$(DISPATCH_COMMON_DIR) -DCryptHash=CryptHash_dispatch -DAFS_TREDM_BENCH_IMPL_DISPATCH=1 -o $@ benchmark.c $(DISPATCH_OBJS) $(LDFLAGS)

kat_dispatch: KAT_CryptHash.c drng.c $(DISPATCH_COMMON_DIR)/afs_dispatch.h $(DISPATCH_OBJS)
	$(CC) $(CFLAGS) $(OPT_DEFINES) -I$(DISPATCH_COMMON_DIR) -DCryptHash=CryptHash_dispatch -o $@ KAT_CryptHash.c drng.c $(DISPATCH_OBJS) $(LDFLAGS)

quick_test_dispatch_perf: $(DISPATCH_COMMON_DIR)/dispatch_quick_test.c $(DISPATCH_COMMON_DIR)/afs_dispatch.h $(DISPATCH_PERF_OBJS)
	$(CC) $(PERF_CFLAGS) $(OPT_DEFINES) -I. -I$(DISPATCH_COMMON_DIR) -o $@ $(DISPATCH_COMMON_DIR)/dispatch_quick_test.c $(DISPATCH_PERF_OBJS) $(LDFLAGS)

hash_cli_dispatch_perf: hash_cli.c $(DISPATCH_COMMON_DIR)/afs_dispatch.h $(DISPATCH_PERF_OBJS)
	$(CC) $(PERF_CFLAGS) $(OPT_DEFINES) -I$(DISPATCH_COMMON_DIR) -DCryptHash=CryptHash_dispatch -o $@ hash_cli.c $(DISPATCH_PERF_OBJS) $(LDFLAGS)

benchmark_dispatch_perf: benchmark.c $(DISPATCH_COMMON_DIR)/afs_dispatch.h $(DISPATCH_PERF_OBJS)
	$(CC) $(PERF_CFLAGS) $(OPT_DEFINES) -I$(DISPATCH_COMMON_DIR) -DCryptHash=CryptHash_dispatch -DAFS_TREDM_BENCH_IMPL_DISPATCH=1 -o $@ benchmark.c $(DISPATCH_PERF_OBJS) $(LDFLAGS)

kat_dispatch_perf: KAT_CryptHash.c drng.c $(DISPATCH_COMMON_DIR)/afs_dispatch.h $(DISPATCH_PERF_OBJS)
	$(CC) $(PERF_KAT_CFLAGS) $(OPT_DEFINES) -I$(DISPATCH_COMMON_DIR) -DCryptHash=CryptHash_dispatch -o $@ KAT_CryptHash.c drng.c $(DISPATCH_PERF_OBJS) $(LDFLAGS)

run-quick: quick_test
	./quick_test

run-benchmark: benchmark
	./benchmark

run-quick-perf: quick_test_perf
	./quick_test_perf

run-benchmark-perf: benchmark_perf
	./benchmark_perf

run-quick-avx2: quick_test_avx2
	./quick_test_avx2

run-benchmark-avx2: benchmark_avx2
	./benchmark_avx2

run-quick-avx2-perf: quick_test_avx2_perf
	./quick_test_avx2_perf

run-benchmark-avx2-perf: benchmark_avx2_perf
	./benchmark_avx2_perf

run-quick-dispatch: quick_test_dispatch
	./quick_test_dispatch

run-benchmark-dispatch: benchmark_dispatch
	./benchmark_dispatch

run-quick-dispatch-perf: quick_test_dispatch_perf
	./quick_test_dispatch_perf

run-benchmark-dispatch-perf: benchmark_dispatch_perf
	./benchmark_dispatch_perf

kat-2-12: kat
	./kat

kat-2-12-perf: kat_perf
	./kat_perf

kat-2-12-avx2: kat_avx2
	./kat_avx2

kat-2-12-avx2-perf: kat_avx2_perf
	./kat_avx2_perf

kat-2-12-dispatch: kat_dispatch
	AFS_TREDM_DISPATCH_FORCE=portable ./kat_dispatch 2_12
	@if [ "$(DISPATCH_AVX2_COMPILE)" = "1" ] && grep -m1 '^flags' /proc/cpuinfo 2>/dev/null | grep -qw avx2; then \
		AFS_TREDM_DISPATCH_FORCE=avx2 ./kat_dispatch 2_12; \
	else \
		echo "SKIPPED: forced AVX2 dispatch KAT (compiler or runtime unavailable)"; \
	fi

kat-2-12-dispatch-perf: kat_dispatch_perf
	AFS_TREDM_DISPATCH_FORCE=portable ./kat_dispatch_perf 2_12
	@if [ "$(DISPATCH_AVX2_COMPILE)" = "1" ] && grep -m1 '^flags' /proc/cpuinfo 2>/dev/null | grep -qw avx2; then \
		AFS_TREDM_DISPATCH_FORCE=avx2 ./kat_dispatch_perf 2_12; \
	else \
		echo "SKIPPED: forced AVX2 dispatch performance KAT (compiler or runtime unavailable)"; \
	fi

dispatch-info:
	@echo "DISPATCH_AVX2_COMPILE=$(DISPATCH_AVX2_COMPILE)"
	@echo "DISPATCH_BUILD_MODE=$(DISPATCH_BUILD_MODE)"
	@echo "DISPATCH_BUILD_DIR=$(DISPATCH_BUILD_DIR)"
	@echo "DISPATCH_PERF_BUILD_DIR=$(DISPATCH_PERF_BUILD_DIR)"

profile-info: profile_info
	./profile_info

profile-info-perf: profile_info_perf
	./profile_info_perf

profile-info-avx2: profile_info_avx2
	./profile_info_avx2

run-microbench-rounds: microbench_rounds
	./microbench_rounds

run-microbench-rounds-opt64: microbench_rounds_opt64
	./microbench_rounds_opt64

clean:
	rm -f kat kat_perf quick_test quick_test_perf hash_cli hash_cli_perf benchmark benchmark_perf \
		kat_avx2 kat_avx2_perf quick_test_avx2 quick_test_avx2_perf hash_cli_avx2 hash_cli_avx2_perf \
		benchmark_avx2 benchmark_avx2_perf kat_dispatch kat_dispatch_perf quick_test_dispatch quick_test_dispatch_perf \
		hash_cli_dispatch hash_cli_dispatch_perf benchmark_dispatch benchmark_dispatch_perf profile_info profile_info_perf profile_info_avx2 \
		microbench_rounds microbench_rounds_opt64 \
		kat_avx2_r2 quick_test_avx2_r2 hash_cli_avx2_r2 benchmark_avx2_r2 \
		kat_avx2_r3 quick_test_avx2_r3 hash_cli_avx2_r3 benchmark_avx2_r3 \
		kat_avx2_r4 quick_test_avx2_r4 hash_cli_avx2_r4 benchmark_avx2_r4 \
		kat_avx2_r6 quick_test_avx2_r6 hash_cli_avx2_r6 benchmark_avx2_r6 \
		kat_avx2_r7 quick_test_avx2_r7 hash_cli_avx2_r7 benchmark_avx2_r7 \
		kat_avx2_r9 quick_test_avx2_r9 hash_cli_avx2_r9 benchmark_avx2_r9 \
		kat_avx2_r11 quick_test_avx2_r11 hash_cli_avx2_r11 benchmark_avx2_r11 \
		kat_avx512_r8 quick_test_avx512_r8 hash_cli_avx512_r8 benchmark_avx512_r8 \
		kat_avx512_r10 quick_test_avx512_r10 hash_cli_avx512_r10 benchmark_avx512_r10 \
		benchmark_native benchmark_avx2_native *.o *.su
	rm -rf .dispatch_build .dispatch_build_avx2 .dispatch_build_portable .dispatch_perf_build .dispatch_perf_build_avx2 .dispatch_perf_build_portable
	rm -rf output output_performance output_*
