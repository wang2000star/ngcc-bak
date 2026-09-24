CC=/usr/bin/gcc
CFLAGS += -O3 -march=native -fomit-frame-pointer -I. -I../../common

SOURCES= auxfunc.c cbd.c crypto_kem.c drng.c indcpa.c KEM_scabbard256.c packing.c poly.c minal.c poly_mul.c polyvec.c ../../common/randombytes.c verify.c
HEADERS= api.h auxfunc.h cbd.h drng.h indcpa.h KEM_scabbard256.h packing.h params.h poly.h minal.h poly_mul.h polyvec.h ../../common/randombytes.h verify.h

genKAT: $(HEADERS) $(SOURCES) KAT_KEM.c
	$(CC) $(CFLAGS) -o $@ $(SOURCES) KAT_KEM.c

.PHONY: clean

clean:
	-rm genKAT -rf output
