CC ?= /usr/bin/cc
CFLAGS += -Wall -Wextra -Wpedantic -Wmissing-prototypes -Wredundant-decls \
          -Wshadow -Wpointer-arith -mavx2 -mpopcnt \
          -march=native -mtune=native -O3

SOURCES = sign.c packing.c polyvec.c poly.c ntt.c reduce.c rounding.c auxfunc.c drng.c consts.c \
          shuffle.S ntt.S invntt.S pointwise.S
HEADERS = config.h params.h api.h sign.h packing.h polyvec.h poly.h ntt.h \
          reduce.h rounding.h auxfunc.h drng.h symmetric.h randombytes.h align.h ntt_avx.h

KECCAK_SOURCES = $(SOURCES) fips202.c symmetric-shake.c f1600x4.S fips202x4.c
KECCAK_HEADERS = $(HEADERS) fips202.h fips202x4.h

.PHONY: all speed shared clean

all: \
  test/test_COMPASS_SIG128 \
  test/test_COMPASS_SIG256 \
  test/test_COMPASS_SIG384 \
  test/test_COMPASS_SIG512

speed: \
  test/test_speed128 \
  test/test_speed256 \
  test/test_speed384 \
  test/test_speed512

shared: \
  lib/libpqcrystals_COMPASS_SIG128_avx2.so \
  lib/libpqcrystals_COMPASS_SIG256_avx2.so \
  lib/libpqcrystals_COMPASS_SIG384_avx2.so \
  lib/libpqcrystals_COMPASS_SIG512_avx2.so \

lib/libpqcrystals_COMPASS_SIG128_avx2.so: $(SOURCES) $(HEADERS) symmetric-shake.c
	mkdir -p lib
	$(CC) -shared -fPIC $(CFLAGS) -DCOMPASS_SIG_MODE=128 -o $@ $(SOURCES) symmetric-shake.c

lib/libpqcrystals_COMPASS_SIG256_avx2.so: $(SOURCES) $(HEADERS) symmetric-shake.c
	mkdir -p lib
	$(CC) -shared -fPIC $(CFLAGS) -DCOMPASS_SIG_MODE=256 -o $@ $(SOURCES) symmetric-shake.c

lib/libpqcrystals_COMPASS_SIG384_avx2.so: $(SOURCES) $(HEADERS) symmetric-shake.c
	mkdir -p lib
	$(CC) -shared -fPIC $(CFLAGS) -DCOMPASS_SIG_MODE=384 -o $@ $(SOURCES) symmetric-shake.c

lib/libpqcrystals_COMPASS_SIG512_avx2.so: $(SOURCES) $(HEADERS) symmetric-shake.c
	mkdir -p lib
	$(CC) -shared -fPIC $(CFLAGS) -DCOMPASS_SIG_MODE=512 -o $@ $(SOURCES) symmetric-shake.c

test/test_COMPASS_SIG128: test/test_COMPASS_SIG.c randombytes.c $(KECCAK_SOURCES) $(KECCAK_HEADERS)
	$(CC) $(CFLAGS) -DCOMPASS_SIG_MODE=128 -o $@ $< randombytes.c $(KECCAK_SOURCES)

test/test_COMPASS_SIG256: test/test_COMPASS_SIG.c randombytes.c $(KECCAK_SOURCES) $(KECCAK_HEADERS)
	$(CC) $(CFLAGS) -DCOMPASS_SIG_MODE=256 -o $@ $< randombytes.c $(KECCAK_SOURCES)

test/test_COMPASS_SIG384: test/test_COMPASS_SIG.c randombytes.c $(KECCAK_SOURCES) $(KECCAK_HEADERS)
	$(CC) $(CFLAGS) -DCOMPASS_SIG_MODE=384 -o $@ $< randombytes.c $(KECCAK_SOURCES)

test/test_COMPASS_SIG512: test/test_COMPASS_SIG.c randombytes.c $(KECCAK_SOURCES) $(KECCAK_HEADERS)
	$(CC) $(CFLAGS) -DCOMPASS_SIG_MODE=512 -o $@ $< randombytes.c $(KECCAK_SOURCES)

test/test_speed128: test/test_speed.c test/speed_print.c test/speed_print.h test/cpucycles.c test/cpucycles.h randombytes.c $(KECCAK_SOURCES) $(KECCAK_HEADERS)
	$(CC) $(CFLAGS) -DCOMPASS_SIG_MODE=128 -o $@ $< test/speed_print.c test/cpucycles.c randombytes.c $(KECCAK_SOURCES)

test/test_speed256: test/test_speed.c test/speed_print.c test/speed_print.h test/cpucycles.c test/cpucycles.h randombytes.c $(KECCAK_SOURCES) $(KECCAK_HEADERS)
	$(CC) $(CFLAGS) -DCOMPASS_SIG_MODE=256 -o $@ $< test/speed_print.c test/cpucycles.c randombytes.c $(KECCAK_SOURCES)

test/test_speed384: test/test_speed.c test/speed_print.c test/speed_print.h test/cpucycles.c test/cpucycles.h randombytes.c $(KECCAK_SOURCES) $(KECCAK_HEADERS)
	$(CC) $(CFLAGS) -DCOMPASS_SIG_MODE=384 -o $@ $< test/speed_print.c test/cpucycles.c randombytes.c $(KECCAK_SOURCES)

test/test_speed512: test/test_speed.c test/speed_print.c test/speed_print.h test/cpucycles.c test/cpucycles.h randombytes.c $(KECCAK_SOURCES) $(KECCAK_HEADERS)
	$(CC) $(CFLAGS) -DCOMPASS_SIG_MODE=512 -o $@ $< test/speed_print.c test/cpucycles.c randombytes.c $(KECCAK_SOURCES)

clean:
	rm -f *~ test/*~ *.gcno *.gcda *.lcov *.o
	rm -rf lib/
	rm -f test/test_COMPASS_SIG128
	rm -f test/test_COMPASS_SIG256
	rm -f test/test_COMPASS_SIG384
	rm -f test/test_COMPASS_SIG512
	rm -f test/test_speed128
	rm -f test/test_speed256
	rm -f test/test_speed384
	rm -f test/test_speed512
