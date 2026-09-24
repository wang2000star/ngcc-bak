CC = gcc
CFLAGS += -std=c99 -Wpedantic -Wall -Wextra -O2

HEADERS = auxfunc.h drng.h sample.h ntt.h poly.h symmetric.h pke.h KEM_AlgorithmInstance.h
SOURCES = auxfunc.c drng.c sample.c ntt.c poly.c symmetric.c pke.c KEM_AlgorithmInstance.c
KAT_KEM_SOURCES = $(SOURCES) KAT_KEM.c
SPEED_KEM_SOURCES = $(SOURCES) cpucycles.c SPEED_KEM.c 

KAT_KEM: $(HEADERS) $(KAT_KEM_SOURCES)
	$(CC) $(CFLAGS) -o $@ $(KAT_KEM_SOURCES)

SPEED_KEM: $(HEADERS) $(SPEED_KEM_SOURCES)
	$(CC) $(CFLAGS) -o $@ $(SPEED_KEM_SOURCES)

.PHONY: clean
clean:
	-rm KAT_KEM SPEED_KEM

# ----------------------------------------------------------------------
# Static library for use by upper-layer AKE protocols
# ----------------------------------------------------------------------

AR ?= ar
CPPFLAGS ?= -I.

KEM_LIBRARY ?= libzen128.a

KEM_LIB_SOURCES := \
	auxfunc.c \
	drng.c \
	sample.c \
	ntt.c \
	poly.c \
	symmetric.c \
	pke.c \
	KEM_AlgorithmInstance.c

KEM_LIB_OBJS := $(KEM_LIB_SOURCES:.c=.o)

$(KEM_LIBRARY): $(KEM_LIB_OBJS)
	$(AR) rcs $@ $^

%.o: %.c $(HEADERS)
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

kem-lib: $(KEM_LIBRARY)

clean-kem-lib:
	rm -f $(KEM_LIBRARY) $(KEM_LIB_OBJS)

distclean: clean clean-kem-lib

.PHONY: kem-lib clean-kem-lib distclean



