# Common build rules for API_PKC AVX2 optimized Frost-CC KEM instances.

CC ?= cc
ROOT := .
LEVEL ?= 128
INSTANCE ?= MAMBA-Frost-CC-$(LEVEL)
CORE_API := $(ROOT)/Frost-CC/src/api_frostcc$(LEVEL).h
ARCH_DEFINE ?= _AMD64_
MATRIX_A_BACKEND ?= AES128

ifeq ($(MATRIX_A_BACKEND),SHAKE128)
MATRIX_DEFINE := _SHAKE128_FOR_A_
else
MATRIX_DEFINE := _AES128_FOR_A_
endif

CPPFLAGS := -I. -DNIX -D$(ARCH_DEFINE) -D_FAST_ -D$(MATRIX_DEFINE) -DFROST_USE_E8_CODE
CFLAGS ?= -std=c99 -Wpedantic -Wall -Wextra -O3 -march=x86-64 -mavx2 -maes -mtune=native -flto -fomit-frame-pointer
CHECK_CFLAGS ?= -std=c99 -Wpedantic -Wall -Wextra -O2 -march=x86-64
LDLIBS := -lm

ifeq ($(OS),Windows_NT)
EXEEXT := .exe
STACK_LDFLAGS := -Wl,--stack,67108864
else
EXEEXT :=
STACK_LDFLAGS :=
endif

CORE_SOURCES := \
	$(ROOT)/Frost-CC/src/frostcc$(LEVEL).c \
	$(ROOT)/Frost-CC/src/util.c \
	$(ROOT)/common/sha3/fips202.c \
	$(ROOT)/common/aes/aes_ni.c

API_SOURCES := KEM_AlgorithmInstance.c randombytes_adapter.c drng.c auxfunc.c
COMMON_TEST_SOURCES := ../test_perf.c
COMMON_AVX2_CHECK := ../check_avx2.c

.PHONY: all kat test smoke check perf perf-run kat-generate kat-install kat-repro check-avx2 clean

all: check-avx2 kat test perf

kat: KAT_KEM$(EXEEXT)
test: test_kem_api$(EXEEXT)
perf: perf_kem_api$(EXEEXT)

check-avx2: check_avx2$(EXEEXT)
	./check_avx2$(EXEEXT)

check_avx2$(EXEEXT): $(COMMON_AVX2_CHECK)
	$(CC) $(CHECK_CFLAGS) $(COMMON_AVX2_CHECK) $(STACK_LDFLAGS) $(LDLIBS) -o $@

KAT_KEM$(EXEEXT): KAT_KEM.c $(API_SOURCES) $(CORE_SOURCES) $(CORE_API)
	$(CC) $(CPPFLAGS) $(CFLAGS) KAT_KEM.c $(API_SOURCES) $(CORE_SOURCES) $(STACK_LDFLAGS) $(LDLIBS) -o $@

test_kem_api$(EXEEXT): test_kem_api.c $(API_SOURCES) $(CORE_SOURCES) $(CORE_API)
	$(CC) $(CPPFLAGS) $(CFLAGS) test_kem_api.c $(API_SOURCES) $(CORE_SOURCES) $(STACK_LDFLAGS) $(LDLIBS) -o $@

perf_kem_api$(EXEEXT): $(COMMON_TEST_SOURCES) $(API_SOURCES) $(CORE_SOURCES) $(CORE_API)
	$(CC) $(CPPFLAGS) $(CFLAGS) $(COMMON_TEST_SOURCES) $(API_SOURCES) $(CORE_SOURCES) $(STACK_LDFLAGS) $(LDLIBS) -o $@

smoke: check-avx2 test_kem_api$(EXEEXT)
	ulimit -s unlimited; ./test_kem_api$(EXEEXT) 5

check: check-avx2 test_kem_api$(EXEEXT)
	ulimit -s unlimited; ./test_kem_api$(EXEEXT) 1000

kat-generate: check-avx2 KAT_KEM$(EXEEXT)
	ulimit -s unlimited; ./KAT_KEM$(EXEEXT)

kat-install: kat-generate
	mkdir -p ../../../Test_Vectors
	cp output/KAT_KEM_$(INSTANCE).txt ../../../Test_Vectors/

kat-repro: kat-generate
	cmp output/KAT_KEM_$(INSTANCE).txt ../../../Test_Vectors/KAT_KEM_$(INSTANCE).txt

perf-run: check-avx2 perf_kem_api$(EXEEXT)
	ulimit -s unlimited; ./perf_kem_api$(EXEEXT) 100

clean:
	rm -rf KAT_KEM KAT_KEM.exe test_kem_api test_kem_api.exe \
		perf_kem_api perf_kem_api.exe check_avx2 check_avx2.exe \
		output output.first perf_$(INSTANCE).csv
