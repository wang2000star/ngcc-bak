CC ?= gcc
CFLAGS ?= -std=c99 -O3 -Wall -Wextra
INCLUDES = -I. -Isrc/common -Isrc/common/triq-384 -Isrc/ref -Isrc/ref/triq-384
SOURCES = KAT_KEM.c KEM_AlgorithmInstance.c drng.c auxfunc.c \
          src/common/code.c src/common/crypto_memset.c src/common/fft.c src/common/kem.c src/common/symmetric.c \
          src/ref/gf.c src/ref/gf2x.c src/ref/triq_pke.c src/ref/parsing.c src/ref/reed_muller.c src/ref/reed_solomon.c src/ref/vector.c
TARGET = kat_kem_384

all: $(TARGET)

$(TARGET): $(SOURCES)
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ $(SOURCES)

kat: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(TARGET) $(TARGET).exe
	rm -rf output
