CC ?= gcc
OPT_DIR := ../../../Optimized_Implementation/AFS-TrEDM-768
COMMON_DIR := ../../../Optimized_Implementation/common/low/batch_multibuffer_common
S6_DIR := ../../../Optimized_Implementation/common/s6

CFLAGS ?= -std=c99 -O3 -Wall -Wextra -pedantic -I$(OPT_DIR) -I$(COMMON_DIR) -DAFS_TREDM_OPT64_PORTABLE=1 -DAFS_TREDM_S6_BATCH_SCALAR_FALLBACK=1
PERF_SPLIT_ROUNDS ?= 10
PERF_CFLAGS ?= $(CFLAGS) -DAFS_TREDM_PERFORMANCE_PROFILE=1 -DAFS_TREDM_TIERED_SPLIT_ROUNDS=$(PERF_SPLIT_ROUNDS)
HARDENING_CFLAGS ?= $(CFLAGS) -O1 -g -Werror -Wno-error=unused-function -Wno-error=unused-const-variable -fsanitize=address,undefined -fno-omit-frame-pointer
HARDENING_PERF_CFLAGS ?= $(PERF_CFLAGS) -O1 -g -Werror -Wno-error=unused-function -Wno-error=unused-const-variable -fsanitize=address,undefined -fno-omit-frame-pointer
ASAN_RUN_ENV ?= env -u LD_PRELOAD ASAN_OPTIONS=detect_leaks=0
AVX2_CFLAGS ?= $(CFLAGS) -DAFS_TREDM_USE_AVX2=1 -DAFS_TREDM_BENCH_IMPL_AVX2=1 -mavx2
AVX2_PERF_CFLAGS ?= $(AVX2_CFLAGS) -DAFS_TREDM_PERFORMANCE_PROFILE=1 -DAFS_TREDM_TIERED_SPLIT_ROUNDS=$(PERF_SPLIT_ROUNDS)
AVX512_BASE_CFLAGS ?= $(AVX2_CFLAGS) -DAFS_TREDM_USE_AVX512_BATCH=1 -mavx512f
AVX512_BATCH16_CFLAGS ?= $(AVX512_BASE_CFLAGS) -DAFS_TREDM_BENCH_BATCH16_AVX512_ONLY=1
AVX512_BATCH16_FALLBACK_CFLAGS ?= $(AVX512_BATCH16_CFLAGS)
AVX512_BATCH16_PERF_CFLAGS ?= $(AVX512_BATCH16_DEFAULT_CFLAGS) -DAFS_TREDM_PERFORMANCE_PROFILE=1 -DAFS_TREDM_TIERED_SPLIT_ROUNDS=$(PERF_SPLIT_ROUNDS)
LDFLAGS ?=

CORE_SRCS = \
	$(OPT_DIR)/CryptHash_AlgorithmInstance.c \
	$(OPT_DIR)/afs_sbox64.c \
	$(S6_DIR)/afs_lmds1600_s6_opt64.c \
	$(OPT_DIR)/afs_p1600.c \
	$(OPT_DIR)/afs_tredm.c

BATCH_SRCS = $(COMMON_DIR)/CryptHash_Batch.c $(CORE_SRCS)
QUICK_SRCS = $(COMMON_DIR)/batch_quick_test.c $(BATCH_SRCS)
BENCH_SRCS = $(COMMON_DIR)/batch_benchmark.c $(BATCH_SRCS)
HARDENING_SRCS = $(COMMON_DIR)/batch_hardening_test.c $(BATCH_SRCS)
PROFILE_SRCS = $(OPT_DIR)/profile_info.c
AVX512_BATCH16_TRUE_SRCS = $(COMMON_DIR)/afs_batch16_s6_avx512.c
BATCH16_AVX512_SELFTEST_SRCS = $(COMMON_DIR)/batch16_avx512_selftest.c $(BATCH_SRCS)
STAGE41_ASM_SRCS =

HOST_ARCH ?= $(shell uname -m 2>/dev/null || echo unknown)
GENERATED_ASM ?= auto
ASM_PROBE := $(shell tmp=$${TMPDIR:-/tmp}/afs_tredm_asm_probe_$$$$.o; printf '.intel_syntax noprefix\n.text\n.globl afs_tredm_asm_probe\nafs_tredm_asm_probe:\n ret\n' | $(CC) -x assembler -c -o $$tmp - >/dev/null 2>&1 && { rm -f $$tmp; echo 1; } || { rm -f $$tmp; echo 0; })
ifneq (,$(filter x86_64 amd64,$(HOST_ARCH)))
GENERATED_ASM_AUTO := $(ASM_PROBE)
else
GENERATED_ASM_AUTO := 0
endif
ifeq ($(GENERATED_ASM),auto)
GENERATED_ASM_ENABLED := $(GENERATED_ASM_AUTO)
else ifeq ($(GENERATED_ASM),1)
GENERATED_ASM_ENABLED := 1
else
GENERATED_ASM_ENABLED := 0
endif
ifeq ($(GENERATED_ASM_ENABLED),1)
AVX512_BATCH16_DEFAULT_CFLAGS ?= $(AVX512_BATCH16_CFLAGS)
AVX512_BATCH16_DEFAULT_SRCS ?= $(AVX512_BATCH16_TRUE_SRCS) $(STAGE41_ASM_SRCS)
else
AVX512_BATCH16_DEFAULT_CFLAGS ?= $(AVX512_BATCH16_FALLBACK_CFLAGS)
AVX512_BATCH16_DEFAULT_SRCS ?= $(AVX512_BATCH16_TRUE_SRCS)
endif
AVX2_RUNTIME_OK := $(shell grep -m1 '^flags' /proc/cpuinfo 2>/dev/null | grep -qw avx2 && echo 1 || echo 0)
AVX512F_RUNTIME_OK := $(shell grep -m1 '^flags' /proc/cpuinfo 2>/dev/null | grep -qw avx512f && echo 1 || echo 0)

.PHONY: all all-avx2 all-portable clean run-quick run-benchmark run-quick-perf run-benchmark-perf \
    run-quick-batch16-avx512 run-benchmark-batch16-avx512 run-quick-batch16-avx512-perf run-benchmark-batch16-avx512-perf \
    run-hardening run-hardening-perf run-hardening-sanitize run-hardening-sanitize-perf run-batchmany-benchmark run-batchmany-benchmark-perf \
    profile-info profile-info-perf batch16-avx512-selftest experiments-help

all: all-portable

all-portable: batch_quick_test_fallback batch_benchmark_fallback batch_hardening_test_fallback

all-avx2: batch_quick_test batch_benchmark

profile_info: $(PROFILE_SRCS)
	$(CC) $(CFLAGS) -I$(OPT_DIR) -o $@ $(PROFILE_SRCS) $(LDFLAGS)

profile_info_perf: $(PROFILE_SRCS)
	$(CC) $(PERF_CFLAGS) -I$(OPT_DIR) -o $@ $(PROFILE_SRCS) $(LDFLAGS)

batch_quick_test: $(QUICK_SRCS)
	$(CC) $(AVX2_CFLAGS) -o $@ $(QUICK_SRCS) $(LDFLAGS)

batch_benchmark: $(BENCH_SRCS)
	$(CC) $(AVX2_CFLAGS) -o $@ $(BENCH_SRCS) $(LDFLAGS)

batch_quick_test_perf: $(QUICK_SRCS)
	$(CC) $(AVX2_PERF_CFLAGS) -o $@ $(QUICK_SRCS) $(LDFLAGS)

batch_benchmark_perf: $(BENCH_SRCS)
	$(CC) $(AVX2_PERF_CFLAGS) -o $@ $(BENCH_SRCS) $(LDFLAGS)

batch_quick_test_fallback: $(QUICK_SRCS)
	$(CC) $(CFLAGS) -o $@ $(QUICK_SRCS) $(LDFLAGS)

batch_benchmark_fallback: $(BENCH_SRCS)
	$(CC) $(CFLAGS) -o $@ $(BENCH_SRCS) $(LDFLAGS)

batch_quick_test_fallback_perf: $(QUICK_SRCS)
	$(CC) $(PERF_CFLAGS) -o $@ $(QUICK_SRCS) $(LDFLAGS)

batch_benchmark_fallback_perf: $(BENCH_SRCS)
	$(CC) $(PERF_CFLAGS) -o $@ $(BENCH_SRCS) $(LDFLAGS)

batch_hardening_test_fallback: $(HARDENING_SRCS)
	$(CC) $(CFLAGS) -o $@ $(HARDENING_SRCS) $(LDFLAGS)

batch_hardening_test_fallback_perf: $(HARDENING_SRCS)
	$(CC) $(PERF_CFLAGS) -o $@ $(HARDENING_SRCS) $(LDFLAGS)

batch_hardening_test_sanitize: $(HARDENING_SRCS)
	$(CC) $(HARDENING_CFLAGS) -o $@ $(HARDENING_SRCS) $(LDFLAGS) -fsanitize=address,undefined

batch_hardening_test_sanitize_perf: $(HARDENING_SRCS)
	$(CC) $(HARDENING_PERF_CFLAGS) -o $@ $(HARDENING_SRCS) $(LDFLAGS) -fsanitize=address,undefined

batchmany_benchmark: $(BENCH_SRCS)
	$(CC) $(AVX2_CFLAGS) -DAFS_TREDM_BENCH_BATCHMANY_ONLY=1 -o $@ $(BENCH_SRCS) $(LDFLAGS)

batchmany_benchmark_perf: $(BENCH_SRCS)
	$(CC) $(AVX2_PERF_CFLAGS) -DAFS_TREDM_BENCH_BATCHMANY_ONLY=1 -o $@ $(BENCH_SRCS) $(LDFLAGS)

quick_test_batch16_avx512: $(QUICK_SRCS) $(AVX512_BATCH16_DEFAULT_SRCS)
	$(CC) $(AVX512_BATCH16_DEFAULT_CFLAGS) -o $@ $(QUICK_SRCS) $(AVX512_BATCH16_DEFAULT_SRCS) $(LDFLAGS)

benchmark_batch16_avx512: $(BENCH_SRCS) $(AVX512_BATCH16_DEFAULT_SRCS)
	$(CC) $(AVX512_BATCH16_DEFAULT_CFLAGS) -o $@ $(BENCH_SRCS) $(AVX512_BATCH16_DEFAULT_SRCS) $(LDFLAGS)

quick_test_batch16_avx512_perf: $(QUICK_SRCS) $(AVX512_BATCH16_DEFAULT_SRCS)
	$(CC) $(AVX512_BATCH16_PERF_CFLAGS) -o $@ $(QUICK_SRCS) $(AVX512_BATCH16_DEFAULT_SRCS) $(LDFLAGS)

benchmark_batch16_avx512_perf: $(BENCH_SRCS) $(AVX512_BATCH16_DEFAULT_SRCS)
	$(CC) $(AVX512_BATCH16_PERF_CFLAGS) -o $@ $(BENCH_SRCS) $(AVX512_BATCH16_DEFAULT_SRCS) $(LDFLAGS)

batch16_avx512_selftest: $(BATCH16_AVX512_SELFTEST_SRCS) $(AVX512_BATCH16_DEFAULT_SRCS)
	$(CC) $(AVX512_BATCH16_PERF_CFLAGS) -o $@ $(BATCH16_AVX512_SELFTEST_SRCS) $(AVX512_BATCH16_DEFAULT_SRCS) $(LDFLAGS)

batch16-avx512-selftest: batch16_avx512_selftest
	./batch16_avx512_selftest

run-quick:
	@if [ "$(AVX2_RUNTIME_OK)" != "1" ]; then echo "SKIPPED: no AVX2 runtime support"; exit 0; fi; \
	$(MAKE) batch_quick_test; ./batch_quick_test

run-benchmark:
	@if [ "$(AVX2_RUNTIME_OK)" != "1" ]; then echo "SKIPPED: no AVX2 runtime support"; exit 0; fi; \
	$(MAKE) batch_benchmark; ./batch_benchmark

run-quick-perf:
	@if [ "$(AVX2_RUNTIME_OK)" != "1" ]; then echo "SKIPPED: no AVX2 runtime support"; exit 0; fi; \
	$(MAKE) batch_quick_test_perf; ./batch_quick_test_perf

run-benchmark-perf:
	@if [ "$(AVX2_RUNTIME_OK)" != "1" ]; then echo "SKIPPED: no AVX2 runtime support"; exit 0; fi; \
	$(MAKE) batch_benchmark_perf; ./batch_benchmark_perf

run-quick-batch16-avx512:
	@if [ "$(AVX2_RUNTIME_OK)" != "1" ] || [ "$(AVX512F_RUNTIME_OK)" != "1" ]; then echo "SKIPPED: no AVX512F runtime support"; exit 0; fi; \
	$(MAKE) quick_test_batch16_avx512; ./quick_test_batch16_avx512

run-benchmark-batch16-avx512:
	@if [ "$(AVX2_RUNTIME_OK)" != "1" ] || [ "$(AVX512F_RUNTIME_OK)" != "1" ]; then echo "SKIPPED: no AVX512F runtime support"; exit 0; fi; \
	$(MAKE) benchmark_batch16_avx512; ./benchmark_batch16_avx512

run-quick-batch16-avx512-perf:
	@if [ "$(AVX2_RUNTIME_OK)" != "1" ] || [ "$(AVX512F_RUNTIME_OK)" != "1" ]; then echo "SKIPPED: no AVX512F runtime support"; exit 0; fi; \
	$(MAKE) quick_test_batch16_avx512_perf; ./quick_test_batch16_avx512_perf

run-benchmark-batch16-avx512-perf:
	@if [ "$(AVX2_RUNTIME_OK)" != "1" ] || [ "$(AVX512F_RUNTIME_OK)" != "1" ]; then echo "SKIPPED: no AVX512F runtime support"; exit 0; fi; \
	$(MAKE) benchmark_batch16_avx512_perf; ./benchmark_batch16_avx512_perf

run-hardening:
	$(MAKE) batch_hardening_test_fallback
	./batch_hardening_test_fallback

run-hardening-perf:
	$(MAKE) batch_hardening_test_fallback_perf
	./batch_hardening_test_fallback_perf

run-hardening-sanitize:
	$(MAKE) batch_hardening_test_sanitize
	$(ASAN_RUN_ENV) ./batch_hardening_test_sanitize

run-hardening-sanitize-perf:
	$(MAKE) batch_hardening_test_sanitize_perf
	$(ASAN_RUN_ENV) ./batch_hardening_test_sanitize_perf

run-batchmany-benchmark:
	@if [ "$(AVX2_RUNTIME_OK)" != "1" ]; then echo "SKIPPED: no AVX2 runtime support"; exit 0; fi; \
	$(MAKE) batchmany_benchmark; ./batchmany_benchmark --quick

run-batchmany-benchmark-perf:
	@if [ "$(AVX2_RUNTIME_OK)" != "1" ]; then echo "SKIPPED: no AVX2 runtime support"; exit 0; fi; \
	$(MAKE) batchmany_benchmark_perf; ./batchmany_benchmark_perf --quick

profile-info: profile_info
	./profile_info

profile-info-perf: profile_info_perf
	./profile_info_perf

experiments-help:
	@echo "Historical batch measurement targets are outside the active submission package."
	@echo "Batch4/8/Many use scalar fallback; Batch16 AVX512 same-length byte-aligned targets use the true hot path."

clean:
	rm -f batch_quick_test batch_benchmark batch_quick_test_perf batch_benchmark_perf \
		batch_quick_test_fallback batch_benchmark_fallback batch_quick_test_fallback_perf batch_benchmark_fallback_perf \
		quick_test_batch16_avx512 benchmark_batch16_avx512 quick_test_batch16_avx512_perf benchmark_batch16_avx512_perf \
		batch16_avx512_selftest \
		\
		batch_hardening_test_* batchmany_benchmark batchmany_benchmark_perf profile_info profile_info_perf \
		batch_quick_test_* batch_benchmark_* quick_test_* benchmark_* batch_microbench* *.o *.su
