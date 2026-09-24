CC = gcc
CFLAGS ?= -Wall -Wextra -Wpedantic -Wmissing-prototypes -Wredundant-decls \
  -Wshadow -Wvla -Wpointer-arith -O3 -march=native -mtune=native -mavx2 -mfma
CPPFLAGS ?= -I.
TARGET = KAT_SIG

SRCS = $(filter-out KAT_SIG.c, $(wildcard *.c))
SRCS := $(filter-out packing.c, $(SRCS)) packing.c
# NTT in hand-written AVX2 assembly (forward / inverse / pointwise) + Keccak
ASM_OBJS = ntt.o intt.o pointwise.o f1600x4.o
OBJS = $(SRCS:.c=.o) $(ASM_OBJS)

all: $(TARGET)

$(TARGET): KAT_SIG.c $(OBJS)
	$(CC) $(CFLAGS) $(CPPFLAGS) $^ -o $@

%.o: %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

%.o: %.S
	$(CC) -x assembler-with-cpp $(CFLAGS) -c $< -o $@

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(TARGET) $(OBJS)

.PHONY: all run clean

# ----------------------------------------------------------------------
# Static library for use by upper-layer AKE protocols
# ----------------------------------------------------------------------

AR ?= ar
LIBRARY ?= libbit512.a

$(LIBRARY): $(OBJS)
	$(AR) rcs $@ $^

lib: $(LIBRARY)

clean-lib:
	rm -f $(LIBRARY)

distclean: clean clean-lib

.PHONY: all run clean lib clean-lib distclean

