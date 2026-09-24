CC      ?= gcc
CFLAGS  ?= -mavx2 -mbmi2 -mpopcnt -mpclmul -march=native -mtune=native \
           -O2 -fomit-frame-pointer -std=c11 -Wall -Wextra
DEPFLAGS = -MMD -MP

# ── Source files ──────────────────────────────────────────────
CORE      = ntt.c ntt_avx.c basemul_avx.c poly.c decode.c packing.c \
            reduce.c verify.c auxfunc.c drng.c consts.c
INDCPA    = indcpa.c
KAT_SRCS  = KAT_KEM.c KEM_AlgorithmInstance.c
ALL_SRCS  = kem.c $(CORE) $(INDCPA) $(KAT_SRCS)
HEADERS   = config.h params.h kem.h indcpa.h poly.h ntt.h ntt_avx.h \
            packing.h decode.h reduce.h verify.h auxfunc.h drng.h \
            symmetric.h consts.h KEM_AlgorithmInstance.h

# ── Test targets ──────────────────────────────────────────────
TESTDIR   = test
TEST_MUL  = $(TESTDIR)/test_mul
TEST_CPAP = $(TESTDIR)/test_cpapke
TEST_KEM  = $(TESTDIR)/test_kem
TEST_SPD  = $(TESTDIR)/test_speed
TEST_NTT  = $(TESTDIR)/test_ntt_avx

# ── Build rules ───────────────────────────────────────────────
.PHONY: all test speed clean help

all: KAT_KEM

KAT_KEM: $(HEADERS) $(ALL_SRCS)
	$(CC) $(CFLAGS) $(DEPFLAGS) -o $@ $(ALL_SRCS)

# Tests that don't need INDCPA (no drng_algorithm dependency)
$(TEST_MUL): $(TESTDIR)/test_mul.c $(CORE)
	$(CC) $(CFLAGS) $(DEPFLAGS) -o $@ $^

$(TEST_NTT): $(TESTDIR)/test_ntt_avx.c $(CORE)
	$(CC) $(CFLAGS) $(DEPFLAGS) -o $@ $^

# Tests that need INDCPA (define drng_algorithm in test file)
$(TEST_CPAP): $(TESTDIR)/test_cpapke.c $(CORE) $(INDCPA)
	$(CC) $(CFLAGS) $(DEPFLAGS) -o $@ $^

$(TEST_KEM): $(TESTDIR)/test_kem.c kem.c $(CORE) $(INDCPA)
	$(CC) $(CFLAGS) $(DEPFLAGS) -o $@ $^

$(TEST_SPD): $(TESTDIR)/test_speed.c $(TESTDIR)/cpucycles.c $(TESTDIR)/speed_print.c \
             kem.c $(CORE) $(INDCPA)
	$(CC) $(CFLAGS) $(DEPFLAGS) -o $@ $^

# test_basemul_avx: excluded — k4_baseinv_avx_8x() not implemented
test: $(TEST_NTT) $(TEST_MUL) $(TEST_CPAP) $(TEST_KEM) $(TEST_SPD)

speed: $(TEST_SPD)
	@echo "=== FLIT AVX2 speed benchmark ==="
	./$(TEST_SPD)

clean:
	-rm -f KAT_KEM $(TEST_MUL) $(TEST_CPAP) $(TEST_KEM) $(TEST_SPD) \
	        $(TEST_NTT)
	-rm -f *.o *.d $(TESTDIR)/*.d
	-rm -f PQCkemKAT_*.req PQCkemKAT_*.rsp
	-rm -rf output

help:
	@echo "FLIT AVX2 Implementation"
	@echo ""
	@echo "Targets:"
	@echo "  all      Build KAT_KEM binary (default)"
	@echo "  test     Build all test binaries"
	@echo "  speed    Build and run speed benchmark"
	@echo "  clean    Remove all build artifacts"
	@echo "  help     Show this help"
	@echo ""
	@echo "Variables:"
	@echo "  CC       C compiler (default: gcc)"
	@echo "  CFLAGS   Compiler flags"

# ── Auto dependency tracking ──────────────────────────────────
DEPFILES = $(ALL_SRCS:.c=.d) \
           $(TESTDIR)/test_mul.d \
           $(TESTDIR)/test_cpapke.d \
           $(TESTDIR)/test_kem.d \
           $(TESTDIR)/test_speed.d \
           $(TESTDIR)/test_ntt_avx.d
-include $(DEPFILES)
