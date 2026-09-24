CC = gcc
CFLAGS = -std=c99 -Wpedantic -Wall -Wextra -O2

SRCROOT = ../Algorithm_Source_Code
INSTANCES = Neulaser-512 Neulaser-768 Neulaser-1024
BENCH_TARGETS = $(addprefix build/,$(addsuffix /bench_hash.exe,$(INSTANCES)))

.PHONY: all bench clean

all: $(BENCH_TARGETS)

build/%/bench_hash.exe: benchmark_hash.c $(SRCROOT)/%/CryptHash_AlgorithmInstance.c $(SRCROOT)/%/CryptHash_AlgorithmInstance.h
	mkdir -p build/$*
	$(CC) $(CFLAGS) -I$(SRCROOT)/$* -o $@ benchmark_hash.c $(SRCROOT)/$*/CryptHash_AlgorithmInstance.c

bench: $(BENCH_TARGETS)
	for d in $(INSTANCES); do ./build/$$d/bench_hash.exe; done

clean:
	rm -rf build
