CC ?= gcc
CFLAGS ?= -Wall -Wextra -Wmissing-prototypes -Wredundant-decls -O3 -fomit-frame-pointer -msse2avx -mavx2 -march=native -fno-common -std=gnu99
NISTFLAGS ?= -Wno-unused-result -O3 -fomit-frame-pointer -msse2avx -mavx2 -march=native -std=gnu99
LDFLAGS ?= -lcrypto
LEVEL ?= 128
VIPER_USE_E8_CODEC ?= 0
VIPERFLAGS = -DVIPER_LEVEL=$(LEVEL) -DVIPER_USE_E8_CODEC=$(VIPER_USE_E8_CODEC) -DVIPER_ARITH_AVX
TCHES_EXPERIMENT_COUNT := $(words $(filter 1,$(VIPER_EXPERIMENTAL_TCHES2021_NTT) $(VIPER_EXPERIMENTAL_TCHES2021_HYBRID) $(VIPER_EXPERIMENTAL_TCHES2021_HYBRID_L3L5)))
ifneq ($(TCHES_EXPERIMENT_COUNT),0)
ifneq ($(TCHES_EXPERIMENT_COUNT),1)
$(error Select at most one TCHES2021 experimental backend: VIPER_EXPERIMENTAL_TCHES2021_NTT, VIPER_EXPERIMENTAL_TCHES2021_HYBRID, or VIPER_EXPERIMENTAL_TCHES2021_HYBRID_L3L5)
endif
VIPERFLAGS += -Itches2021_ntt
endif
ifeq ($(VIPER_EXPERIMENTAL_TCHES2021_NTT),1)
VIPERFLAGS += -DVIPER_EXPERIMENTAL_TCHES2021_NTT=1
endif
ifeq ($(VIPER_TCHES_NTT_STAGE_PROFILE),1)
VIPERFLAGS += -DVIPER_TCHES_NTT_STAGE_PROFILE=1
endif
ifeq ($(VIPER_EXPERIMENTAL_TCHES2021_HYBRID),1)
VIPERFLAGS += -DVIPER_EXPERIMENTAL_TCHES2021_HYBRID=1
endif
ifeq ($(VIPER_EXPERIMENTAL_TCHES2021_HYBRID_L3L5),1)
VIPERFLAGS += -DVIPER_EXPERIMENTAL_TCHES2021_HYBRID_L3L5=1
endif

AVX_POLYMUL_SOURCES = polymul/toom-cook_4way.c
KECCAK4X_SOURCES = fips202x4.c keccak4x/KeccakP-1600-times4-SIMD256.c
TCHES_NTT_SOURCES = tches2021_ntt/viper_tches2021_ntt.c tches2021_ntt/poly.c tches2021_ntt/polyvec.c tches2021_ntt/aes256ctr.c tches2021_ntt/cbd.c tches2021_ntt/ntt256n.S tches2021_ntt/invntt256n.S tches2021_ntt/basemul256x1.S tches2021_ntt/consts256n7681.c tches2021_ntt/consts256n10753.c
ifneq ($(TCHES_EXPERIMENT_COUNT),0)
EXPERIMENTAL_SOURCES = $(TCHES_NTT_SOURCES)
endif
SOURCES = viper.c viper_arith.c viper_message_codec.c viper_e8.c $(AVX_POLYMUL_SOURCES) $(EXPERIMENTAL_SOURCES) $(KECCAK4X_SOURCES) fips202.c verify.c rng.c kem.c
HEADERS = viper_params.h api.h viper.h viper_arith.h viper_message_codec.h viper_e8.h fips202.h fips202x4.h verify.h rng.h

all: test/viper_validation test/viper_bench test/viper_arith_compare test/viper_codec_validation test/viper_size_test

test/viper_validation: FORCE $(SOURCES) $(HEADERS) test/viper_validation.c
	$(CC) $(CFLAGS) $(VIPERFLAGS) -o $@ $(SOURCES) test/viper_validation.c $(LDFLAGS)

test/viper_bench: FORCE $(SOURCES) $(HEADERS) test/viper_bench.c test/cpucycles.c test/cpucycles.h
	$(CC) $(CFLAGS) $(VIPERFLAGS) -o $@ $(SOURCES) test/viper_bench.c test/cpucycles.c $(LDFLAGS)

test/viper_codec_validation: FORCE $(SOURCES) $(HEADERS) test/viper_codec_validation.c
	$(CC) $(CFLAGS) $(VIPERFLAGS) -o $@ $(SOURCES) test/viper_codec_validation.c $(LDFLAGS)

test/viper_size_test: FORCE $(HEADERS) test/viper_size_test.c
	$(CC) $(CFLAGS) $(VIPERFLAGS) -o $@ test/viper_size_test.c

test/viper_ntt_validation: FORCE $(SOURCES) $(HEADERS) test/viper_ntt_validation.c
	$(CC) $(CFLAGS) $(VIPERFLAGS) -o $@ $(SOURCES) test/viper_ntt_validation.c test/cpucycles.c $(LDFLAGS)

test/viper_arith_compare: FORCE viper_arith.c $(AVX_POLYMUL_SOURCES) ../Reference_Implementation_KEM/viper_arith.c viper_arith.h viper.h viper_params.h ../Reference_Implementation_KEM/viper_arith.h ../Reference_Implementation_KEM/viper.h test/viper_arith_compare.c
	$(CC) $(CFLAGS) $(VIPERFLAGS) -I. -I../Reference_Implementation_KEM -o $@ viper_arith.c $(AVX_POLYMUL_SOURCES) $(EXPERIMENTAL_SOURCES) ../Reference_Implementation_KEM/viper_arith.c test/viper_arith_compare.c $(LDFLAGS)

.PHONY: clean test kat FORCE
FORCE:

test: test/viper_validation
	./test/viper_validation 1000

KAT_KEM: FORCE $(SOURCES) $(HEADERS) test/viper_kat_kem.c
	$(CC) $(CFLAGS) $(VIPERFLAGS) -o $@ $(SOURCES) test/viper_kat_kem.c $(LDFLAGS)

kat: KAT_KEM
	./KAT_KEM

clean:
	rm -f *.o test/viper_validation test/viper_bench test/viper_codec_validation test/viper_size_test test/viper_arith_compare test/viper_ntt_validation test/test_kex test/kem test/PQCgenKAT_kem KAT_KEM PQCkemKAT_*.req PQCkemKAT_*.rsp *.req *.rsp
