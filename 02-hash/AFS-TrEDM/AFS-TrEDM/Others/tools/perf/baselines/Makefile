CC ?= cc
CFLAGS ?= -O3 -Wall -Wextra -pedantic -std=c99 -march=native
OPENSSL_LIBS ?= -lcrypto

.PHONY: all clean kat

SHA3_REF = sha3_512_reference_c
SHA3_COMPACT = xkcp_compactfips202_sha3_512
SHA3_OPENSSL = openssl_evp_sha3_512

all: $(SHA3_REF) $(SHA3_COMPACT) $(SHA3_OPENSSL)

$(SHA3_REF): xkcp_readable/benchmark_sha3_512_reference_c.c sha3_512_xkcp_bench_driver.h xkcp_readable/Keccak-readable-and-compact.c
	$(CC) $(CFLAGS) -o $@ xkcp_readable/benchmark_sha3_512_reference_c.c

$(SHA3_COMPACT): xkcp_more_compact/benchmark_xkcp_compactfips202_sha3_512.c sha3_512_xkcp_bench_driver.h xkcp_more_compact/Keccak-more-compact.c
	$(CC) $(CFLAGS) -o $@ xkcp_more_compact/benchmark_xkcp_compactfips202_sha3_512.c

$(SHA3_OPENSSL): benchmark_openssl_evp_sha3_512.c ../../baselines/bench_openssl_sha3_512.c
	$(CC) $(CFLAGS) -o $@ benchmark_openssl_evp_sha3_512.c $(OPENSSL_LIBS)

benchmark_sha3_512_ref_c: $(SHA3_REF)
	cp $(SHA3_REF) $@

benchmark_xkcp_compact_sha3_512: $(SHA3_COMPACT)
	cp $(SHA3_COMPACT) $@

benchmark_openssl_evp_sha3_512: $(SHA3_OPENSSL)
	cp $(SHA3_OPENSSL) $@

kat: all
	bash run_sha3_kat.sh

clean:
	rm -f $(SHA3_REF) $(SHA3_COMPACT) $(SHA3_OPENSSL) \
		benchmark_sha3_512_ref_c benchmark_openssl_evp_sha3_512 benchmark_xkcp_compact_sha3_512 *.o *.su
