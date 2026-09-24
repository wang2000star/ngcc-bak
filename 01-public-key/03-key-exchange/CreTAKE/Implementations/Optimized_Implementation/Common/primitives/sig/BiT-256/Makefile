CC = gcc
CFLAGS ?= -Wall -Wextra -Wpedantic -Wmissing-prototypes -Wredundant-decls \
  -Wshadow -Wvla -Wpointer-arith -O3 -march=native -mtune=native
CPPFLAGS ?= -I.
TARGET = KAT_SIG

SRCS = $(filter-out KAT_SIG.c, $(wildcard *.c))
SRCS := $(filter-out packing.c, $(SRCS)) packing.c
OBJS = $(SRCS:.c=.o)

# Assembly files (NTT + Keccak)
ASM_OBJS = ntt.o intt.o pointwise.o f1600x4.o
OBJS += $(ASM_OBJS)

all: $(TARGET)

$(TARGET): KAT_SIG.c $(OBJS)
	$(CC) $(CFLAGS) $(CPPFLAGS) $^ -o $@

%.o: %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

%.o: %.S
	$(CC) $(CFLAGS) $(CPPFLAGS) -x assembler-with-cpp -c $< -o $@

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(TARGET) $(OBJS)

.PHONY: all run clean

# ----------------------------------------------------------------------
# Static library for use by upper-layer AKE protocols
# ----------------------------------------------------------------------

AR ?= ar
LIBRARY ?= libbit256.a

$(LIBRARY): $(OBJS)
	$(AR) rcs $@ $^

lib: $(LIBRARY)

clean-lib:
	rm -f $(LIBRARY)

distclean: clean clean-lib

.PHONY: all run clean lib clean-lib distclean

