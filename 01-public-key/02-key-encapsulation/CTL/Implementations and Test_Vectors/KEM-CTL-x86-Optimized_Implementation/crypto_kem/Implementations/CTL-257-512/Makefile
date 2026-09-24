.POSIX:

CC = gcc
CFLAGS = -D_GNU_SOURCE -O3 -march=x86-64 -mavx2 -mtune=native -flto=auto -fomit-frame-pointer -std=c99 -w -DCTL_AVX2=1 -DCTL_X86_ASM=1
ASFLAGS = -Wa,-O3
LD = $(CC)
LDFLAGS = -flto=auto -w
LIBS = -lquadmath -lgmp -lm
UNAME_S = $(shell uname -s 2>/dev/null)
ifneq (,$(filter MINGW% MSYS% CYGWIN%,$(UNAME_S)))
PSAPI_LIBS = -lpsapi
else ifeq ($(OS),Windows_NT)
PSAPI_LIBS = -lpsapi
else
PSAPI_LIBS =
endif

CORE_OBJ = api_257_512.o \
	codec.o fft.o fnr.o kem257.o kem769.o kem3329.o \
	ntru_utils.o ng_fxp.o ng_mp31.o ng_ntru.o ng_poly.o ng_zint31.o \
	sha3.o modqp.o prng.o auxfunc.o drng.o ntru_solver.o keygen.o modq_asm.o

all: test_kem KAT_KEM benchmark test_kem_correctness_ctl benchmark_selfeval_ctl

test_kem: test_kem.o KEM_AlgorithmInstance.o $(CORE_OBJ)
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

KAT_KEM: KAT_KEM.o KEM_AlgorithmInstance.o $(CORE_OBJ)
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

benchmark: benchmark.o KEM_AlgorithmInstance.o $(CORE_OBJ)
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

test_kem_correctness_ctl: test_kem_correctness_ctl.o KEM_AlgorithmInstance.o $(CORE_OBJ)
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS)

benchmark_selfeval_ctl: benchmark_selfeval_ctl.o KEM_AlgorithmInstance.o $(CORE_OBJ)
	$(LD) $(LDFLAGS) -o $@ $^ $(LIBS) $(PSAPI_LIBS)

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

modq_asm.o: modq_asm.S
	$(CC) $(ASFLAGS) -c -o $@ $<

ng_fxp.o: ng_fxp.c
	$(CC) $(CFLAGS) -DNTRUGEN_PREFIX=ctlng -c -o $@ $<

ng_mp31.o: ng_mp31.c
	$(CC) $(CFLAGS) -DNTRUGEN_PREFIX=ctlng -c -o $@ $<

ng_ntru.o: ng_ntru.c
	$(CC) $(CFLAGS) -DNTRUGEN_PREFIX=ctlng -c -o $@ $<

ng_poly.o: ng_poly.c
	$(CC) $(CFLAGS) -DNTRUGEN_PREFIX=ctlng -c -o $@ $<

ng_zint31.o: ng_zint31.c
	$(CC) $(CFLAGS) -DNTRUGEN_PREFIX=ctlng -c -o $@ $<

sha3.o: sha3.c
	$(CC) $(CFLAGS) -DNTRUGEN_PREFIX=ctlng -c -o $@ $<

clean:
	rm -f *.o *.exe test_kem KAT_KEM benchmark test_kem_correctness_ctl benchmark_selfeval_ctl

.PHONY: all clean
