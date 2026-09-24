# BiT optimized implementation (AVX2) — x86 evaluation guide §3.2 (Table 1)
CC       = gcc
CFLAGS  ?= -O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer \
           -std=c99 -Wpedantic -Wall -Wextra -DASM_ALIASES
CPPFLAGS ?= -I.

TARGET   = KAT_SIG

# All .c files except KAT_SIG.c (which owns main()); packing.c ordered last.
SRCS = $(filter-out KAT_SIG.c, $(wildcard *.c))
SRCS := $(filter-out packing.c, $(SRCS)) packing.c
ASRC = f1600x4.S ntt.S intt.S pointwise.S
OBJS = $(SRCS:.c=.o) $(ASRC:.S=.o)

.PHONY: all correctness speed clean

all: $(TARGET)

$(TARGET): KAT_SIG.c $(OBJS)
	$(CC) $(CFLAGS) $(CPPFLAGS) $^ -o $@

correctness: $(OBJS) test/test_correctness.c test/test_common.h
	$(CC) $(CFLAGS) $(CPPFLAGS) test/test_correctness.c $(OBJS) -o $@
	./$@

# Unity build: all sources in one gcc invocation → aggressive cross-file inlining
# for the tiny helpers (NTT butterflies, Barrett reductions) that dominate cycles.
speed: test/test_speed.c test/cpucycles.c test/speed_print.c test/test_common.h
	$(CC) $(CFLAGS) $(CPPFLAGS) -DNTESTS=10000 \
	  test/test_speed.c test/cpucycles.c test/speed_print.c \
	  $(SRCS) $(ASRC) -o $@ -lm
	./$@

%.o: %.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

%.o: %.S
	$(CC) $(filter-out -flto,$(CFLAGS)) $(CPPFLAGS) -x assembler-with-cpp -c $< -o $@

clean:
	rm -f $(TARGET) $(OBJS) correctness speed
