CC = gcc
CFLAGS = -O3 -march=x86-64 -maes -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra

KAT      = KAT_CryptHash
CORE     = drng.c CryptHash_AlgorithmInstance.c wish.c
INSTANCE = Wish512

.PHONY: kat bench run-kat clean

kat: $(KAT)

$(KAT): KAT_CryptHash.c $(CORE)
	$(CC) $(CFLAGS) -o $@ $^

# Build shared libraries (.so) for benchmarking.
bench: $(CORE)
	$(CC) -shared -fPIC $(CFLAGS) $(CORE) -o $(INSTANCE)_x86_aes.so
	$(CC) -shared -fPIC $(CFLAGS) -mavx2 $(CORE) -o $(INSTANCE)_x86_aes_avx2.so

run-kat: $(KAT)
	./$(KAT)

clean:
	rm -f $(KAT) $(INSTANCE)_x86_aes.so $(INSTANCE)_x86_aes_avx2.so
