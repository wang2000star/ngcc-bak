# ═══════════════════════════════════════════════════════════════════════
#  Makefile for ZEN_SWIFT_256 (ARM Cortex-A / MinGW)
# ═══════════════════════════════════════════════════════════════════════
#
#  Build on ARM target board (default):
#    make
#
#  Build with NEON SIMD acceleration (ARM only):
#    make NEON=1
#
#  Syntax-check on local Windows/MinGW (no NEON, x86 scalar only):
#    make native
#
# ═══════════════════════════════════════════════════════════════════════

HEADERS = auxfunc.h drng.h sample.h ntt.h poly.h symmetric.h pke.h KEM_AlgorithmInstance.h
SOURCES = auxfunc.c drng.c sample.c ntt.c poly.c symmetric.c pke.c KEM_AlgorithmInstance.c
KAT_KEM_SOURCES  = $(SOURCES) KAT_KEM.c
SPEED_KEM_SOURCES = $(SOURCES) cpucycles.c SPEED_KEM.c
TEST_SPEED_SOURCES = $(SOURCES) test_speed.c
TEST_SPEED_SOURCES_KeyGen = $(SOURCES) test_speed_KeyGen.c
TEST_SPEED_SOURCES_Encrypt = $(SOURCES) test_speed_Encrypt.c
TEST_SPEED_SOURCES_Decrypt = $(SOURCES) test_speed_Decrypt.c

# ── ARM cross-compiler (default target) ──────────────────────────────
CC_ARM   = /home/zxtest/toolchain/gcc-linaro-4.9-2016.02-x86_64_arm-linux-gnueabihf/bin/arm-linux-gnueabihf-gcc-4.9.4
CFLAGS_ARM = -O3 -march=armv7-a -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra -mtune=cortex-a9 -funroll-loops

# ── 仅 SPEED_KEM 使用的额外编译选项 ──────────────────────────────────
# SPEED_KEM 需要 GNU 扩展和性能计数器支持
CFLAGS_ARM_SPEED = $(CFLAGS_ARM)  -mfloat-abi=hard -D_GNU_SOURCE

# SPEED_KEM 链接选项（需要 -lrt 支持 clock_gettime）
LDFLAGS_ARM_SPEED = -lrt

# ── Local MinGW (syntax check on Windows, no NEON) ──────────────────
CC_NATIVE  = gcc
CFLAGS_NATIVE = -O2 -std=c99 -Wall -Wextra -Wno-unused-parameter

# Optional NEON (ARM only): make NEON=1
#ifeq ($(NEON),1)
CFLAGS_ARM += -mfpu=neon -DARM_NEON_ENABLED
CFLAGS_ARM_SPEED += -mfpu=neon -DARM_NEON_ENABLED
#endif

# ── Targets ──────────────────────────────────────────────────────────
# Default: build ARM binaries (run on the target board)
all: KAT_KEM TEST_SPEED SPEED_KEM TEST_SPEED_KeyGen TEST_SPEED_Encrypt TEST_SPEED_Decrypt

# Local syntax-check (run on Windows/MinGW dev machine)
native: KAT_KEM_native TEST_SPEED_native

KAT_KEM: $(HEADERS) $(KAT_KEM_SOURCES)
	$(CC_ARM) $(CFLAGS_ARM) -o $@_256 $(KAT_KEM_SOURCES)

# SPEED_KEM 使用独立的编译和链接选项
SPEED_KEM: $(HEADERS) $(SPEED_KEM_SOURCES) cpucycles.h
	$(CC_ARM) $(CFLAGS_ARM_SPEED) $(LDFLAGS_ARM_SPEED) -o $@_256 $(SPEED_KEM_SOURCES)

TEST_SPEED: $(HEADERS) $(TEST_SPEED_SOURCES)
	$(CC_ARM) $(CFLAGS_ARM) -o $@_256 $(TEST_SPEED_SOURCES)
TEST_SPEED_KeyGen: $(HEADERS) $(TEST_SPEED_SOURCES_KeyGen)
	$(CC_ARM) $(CFLAGS_ARM) -o $@_256 $(TEST_SPEED_SOURCES_KeyGen)
TEST_SPEED_Encrypt: $(HEADERS) $(TEST_SPEED_SOURCES_Encrypt)
	$(CC_ARM) $(CFLAGS_ARM) -o $@_256 $(TEST_SPEED_SOURCES_Encrypt)
TEST_SPEED_Decrypt: $(HEADERS) $(TEST_SPEED_SOURCES_Decrypt)
	$(CC_ARM) $(CFLAGS_ARM) -o $@_256 $(TEST_SPEED_SOURCES_Decrypt)

KAT_KEM_native: $(HEADERS) $(KAT_KEM_SOURCES)
	$(CC_NATIVE) $(CFLAGS_NATIVE) -o $@ $(KAT_KEM_SOURCES)

SPEED_KEM_native: $(HEADERS) $(SPEED_KEM_SOURCES)
	$(CC_NATIVE) $(CFLAGS_NATIVE) -o $@ $(SPEED_KEM_SOURCES)

TEST_SPEED_native: $(HEADERS) $(TEST_SPEED_SOURCES)
	$(CC_NATIVE) $(CFLAGS_NATIVE) -o $@ $(TEST_SPEED_SOURCES)

.PHONY: clean native
clean:
	-rm -f KAT_KEM SPEED_KEM TEST_SPEED KAT_KEM_* SPEED_KEM_* TEST_SPEED_* 
