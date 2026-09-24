CC = gcc
CFLAGS = -O3 -march=armv8.2-a+aes -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra

KAT      = KAT_CryptHash
CORE     = drng.c CryptHash_AlgorithmInstance.c wish.c
INSTANCE = Wish1024

.PHONY: kat bench run-kat clean

kat: $(KAT)

$(KAT): KAT_CryptHash.c $(CORE)
	$(CC) $(CFLAGS) -o $@ $^

# Build shared libraries (.so) for benchmarking.
bench: $(CORE)
	$(CC) -shared -fPIC $(CFLAGS) $(CORE) -o $(INSTANCE)_arm_aes.so
	$(CC) -shared -fPIC $(CFLAGS) -march=armv8.2-a+aes+sve $(CORE) -o $(INSTANCE)_arm_aes_sve.so

run-kat: $(KAT)
	./$(KAT)

clean:
	rm -f $(KAT) $(INSTANCE)_arm_aes.so $(INSTANCE)_arm_aes_sve.so
