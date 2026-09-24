CC ?= cc
CFLAGS ?= -std=c99 -O3 -Wall -Wextra -mavx -mavx2 -mbmi -mpclmul
INCLUDES = -I. -Isrc/opt/triq-512 -Isrc/opt -Isrc/common -Isrc/common/triq-512
SOURCES = KAT_KEM.c KEM_AlgorithmInstance.c drng.c auxfunc.c \
          src/common/code.c src/common/crypto_memset.c src/common/fft.c src/common/kem.c src/common/symmetric.c \
          src/opt/gf.c src/opt/triq-512/gf2x.c src/opt/triq_pke.c src/opt/parsing.c src/opt/reed_muller.c src/opt/triq-512/reed_solomon.c src/opt/vector.c
TARGET = kat_kem_512_avx2

all: $(TARGET)

$(TARGET): $(SOURCES)
	$(CC) $(CFLAGS) $(INCLUDES) -o $@ $(SOURCES)

kat: $(TARGET)
	./$(TARGET)

clean:
	rm -f $(TARGET) $(TARGET).exe
	rm -rf output
