CC = gcc
CFLAGS ?= -std=c99 -Wpedantic -Wall -Wextra -O2
CPPFLAGS ?= -I.
TARGET = KAT_SIG

SRCS = $(filter-out KAT_SIG.c, $(wildcard *.c))
SRCS := $(filter-out packing.c, $(SRCS)) packing.c
OBJS = $(SRCS:.c=.o)

all: $(TARGET)

$(TARGET): KAT_SIG.c $(OBJS)
	$(CC) $(CFLAGS) $(CPPFLAGS) $^ -o $@

%.o: %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

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