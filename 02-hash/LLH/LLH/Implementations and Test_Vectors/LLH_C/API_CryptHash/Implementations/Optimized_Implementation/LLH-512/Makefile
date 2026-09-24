CC ?= gcc

CFLAGS_BASE = -O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra -DLLH_FORCE_AVX2=1
LDFLAGS ?= -flto

KAT_BIN = kat_llh_512
KAT_SRCS = CryptHash_AlgorithmInstance.c KAT_CryptHash.c drng.c
TEST_VECTOR_DIR = ../../../Test_Vectors

.PHONY: all kat vectors clean

all: kat

kat: $(KAT_BIN)

$(KAT_BIN): $(KAT_SRCS) CryptHash_AlgorithmInstance.h llh_core.c
	$(CC) $(CFLAGS_BASE) $(KAT_SRCS) -o $@ $(LDFLAGS)

vectors: $(KAT_BIN)
	rm -rf output
	./$(KAT_BIN)
	mkdir -p $(TEST_VECTOR_DIR)
	cp output/KAT_* $(TEST_VECTOR_DIR)/
	rm -rf output

clean:
	rm -rf $(KAT_BIN) output
