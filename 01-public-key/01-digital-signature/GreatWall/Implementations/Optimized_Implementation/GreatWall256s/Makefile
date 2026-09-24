CC ?= gcc

CFLAGS ?= -O3 -march=x86-64 -mavx2 -maes -mpclmul -mtune=native -flto -fomit-frame-pointer -std=c11 -Wpedantic -Wall -Wextra -I.
LDFLAGS ?= -O3 -march=x86-64 -mavx2 -maes -mpclmul -mtune=native -flto -fomit-frame-pointer -lcrypto

TARGET := KAT_SIG

SRCS := \
	KAT_SIG.c \
	SIG_AlgorithmInstance.c \
	drng.c \
	api.c \
	aes.c \
	aes_impl.c \
	block.c \
	block_impl.c \
	faest.c \
	greatwall.c \
	greatwall-256-matrix.c \
	greatwall_impl.c \
	hash.c \
	KeccakHash.c \
	KeccakHashtimes4.c \
	KeccakP-1600-times2-SIMD128.c \
	KeccakP-1600-times4-SIMD256.c \
	KeccakP-1600-times8-on4.c \
	KeccakSponge.c \
	KeccakSpongetimes4.c \
	owf_proof.c \
	polynomials.c \
	polynomials_impl.c \
	prgs.c \
	quicksilver.c \
	randomness_randombytes.c \
	small_vole.c \
	transpose.c \
	universal_hash.c \
	util.c \
	vector_com.c \
	vole_check.c \
	vole_commit.c

ASM_SRCS := \
	KeccakP-1600-AVX2.s

OBJS := $(SRCS:.c=.o) $(ASM_SRCS:.s=.o)

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) -o $@ $^ $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: %.s
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJS) $(TARGET)
	rm -rf output

.PHONY: all clean
