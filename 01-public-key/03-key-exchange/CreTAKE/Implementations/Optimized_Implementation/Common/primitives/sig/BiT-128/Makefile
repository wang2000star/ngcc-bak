CC = cc
AS = cc
CFLAGS ?= -Wall -Wextra -Wpedantic -Wmissing-prototypes -Wredundant-decls \
  -Wshadow -Wpointer-arith -O3 -mavx2 -mfma -march=native -mtune=native -DASM_ALIASES
CPPFLAGS ?= -I.
TARGET = KAT_SIG

SRCS = $(filter-out KAT_SIG.c, $(wildcard *.c))
SRCS := $(filter-out packing.c, $(SRCS)) packing.c
ASRC = f1600x4.S ntt.S intt.S pointwise.S
OBJS = $(SRCS:.c=.o) $(ASRC:.S=.o)

all: $(TARGET)

$(TARGET): KAT_SIG.c $(OBJS)
	$(CC) $(CFLAGS) $(CPPFLAGS) $^ -o $@

%.o: %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

%.o: %.S
	$(AS) $(CFLAGS) $(CPPFLAGS) -x assembler-with-cpp -c $< -o $@

run: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(TARGET) $(OBJS)

.PHONY: all run clean

# ----------------------------------------------------------------------
# Static library for use by upper-layer AKE protocols
# ----------------------------------------------------------------------

AR ?= ar
LIBRARY ?= libbit128.a

$(LIBRARY): $(OBJS)
	$(AR) rcs $@ $^

lib: $(LIBRARY)

clean-lib:
	rm -f $(LIBRARY)

distclean: clean clean-lib

.PHONY: all run clean lib clean-lib distclean

