CC ?= gcc
CFLAGS ?= -Wall -Wextra -Wmissing-prototypes -Wredundant-decls -O2 -fomit-frame-pointer -std=gnu99
NISTFLAGS ?= -Wno-unused-result -O2 -fomit-frame-pointer -std=gnu99
LDFLAGS ?= -lcrypto
LEVEL ?= 128
VIPER_USE_E8_CODEC ?= 0
VIPERFLAGS = -DVIPER_LEVEL=$(LEVEL) -DVIPER_USE_E8_CODEC=$(VIPER_USE_E8_CODEC)

SOURCES = viper.c viper_arith.c viper_message_codec.c viper_e8.c fips202.c verify.c rng.c kem.c
HEADERS = viper_params.h api.h viper.h viper_arith.h viper_message_codec.h viper_e8.h fips202.h verify.h rng.h

all: test/viper_validation test/viper_bench test/viper_codec_validation test/viper_size_test

test/viper_validation: FORCE $(SOURCES) $(HEADERS) test/viper_validation.c
	$(CC) $(CFLAGS) $(VIPERFLAGS) -o $@ $(SOURCES) test/viper_validation.c $(LDFLAGS)

test/viper_bench: FORCE $(SOURCES) $(HEADERS) test/viper_bench.c test/cpucycles.c test/cpucycles.h
	$(CC) $(CFLAGS) $(VIPERFLAGS) -o $@ $(SOURCES) test/viper_bench.c test/cpucycles.c $(LDFLAGS)

test/viper_codec_validation: FORCE $(SOURCES) $(HEADERS) test/viper_codec_validation.c
	$(CC) $(CFLAGS) $(VIPERFLAGS) -o $@ $(SOURCES) test/viper_codec_validation.c $(LDFLAGS)

test/viper_size_test: FORCE $(HEADERS) test/viper_size_test.c
	$(CC) $(CFLAGS) $(VIPERFLAGS) -o $@ test/viper_size_test.c

.PHONY: clean test kat FORCE
FORCE:

test: test/viper_validation
	./test/viper_validation 1000

KAT_KEM: FORCE $(SOURCES) $(HEADERS) test/viper_kat_kem.c
	$(CC) $(CFLAGS) $(VIPERFLAGS) -o $@ $(SOURCES) test/viper_kat_kem.c $(LDFLAGS)

kat: KAT_KEM
	./KAT_KEM

clean:
	rm -f *.o test/viper_validation test/viper_bench test/viper_codec_validation test/viper_size_test test/test_kex test/kem test/PQCgenKAT_kem KAT_KEM PQCkemKAT_*.req PQCkemKAT_*.rsp *.req *.rsp
