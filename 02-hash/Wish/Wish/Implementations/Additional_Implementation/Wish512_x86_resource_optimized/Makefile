CC = gcc
CFLAGS = -Os -march=x86-64 -maes  -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra

KAT      = KAT_CryptHash
INSTANCE = Wish512
CORE     = drng.c CryptHash_AlgorithmInstance.c wish.c

.PHONY: kat run-kat bench clean

kat: $(KAT)

$(KAT): KAT_CryptHash.c $(CORE)
	$(CC) $(CFLAGS) -o $@ $^

run-kat: $(KAT)
	./$(KAT)

# Build shared libraries (.so) for benchmarking.
bench: $(CORE)
	$(CC) -shared -fPIC $(CFLAGS) $(CORE) -o $(INSTANCE)_x86_aes_mem.so

clean:
	rm -f $(KAT) *.so *.txt
