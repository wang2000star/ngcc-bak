CC := gcc
CFLAGS_BASE := -std=c99 -O3 -flto -fomit-frame-pointer -frename-registers -Wall -Wextra -pedantic
CFLAGS_PORTABLE := $(CFLAGS_BASE) -mno-avx -mno-avx2 -mno-bmi -mno-bmi2 -DAXIS_OPT_LEVEL=1
CFLAGS_AVX2 := $(CFLAGS_BASE) -mavx2 -mno-bmi -mno-bmi2 -mno-avx512f -DAXIS_OPT_LEVEL=2
CFLAGS_BEST := $(CFLAGS_BASE) -funroll-loops -march=native -mtune=native -DAXIS_OPT_LEVEL=3
CFLAGS := $(CFLAGS_BEST)
CPPFLAGS :=
TARGET := kat_axis_ref
OBJS := CryptHash_AlgorithmInstance.o axis_core.o drng.o KAT_CryptHash.o

ifeq ($(OS),Windows_NT)
EXEEXT := .exe
CPPFLAGS += -D__USE_MINGW_ANSI_STDIO=1
RUN_TARGET := ./$(TARGET)$(EXEEXT)
CLEAN_CMD = powershell -NoProfile -Command "Remove-Item -LiteralPath @('CryptHash_AlgorithmInstance.o','axis_core.o','drng.o','KAT_CryptHash.o','$(TARGET)$(EXEEXT)') -Force -ErrorAction SilentlyContinue; if (Test-Path output) { Remove-Item -Recurse -Force output }"
else
EXEEXT :=
RUN_TARGET := ./$(TARGET)$(EXEEXT)
CLEAN_CMD = rm -f $(OBJS) $(TARGET)$(EXEEXT) && rm -rf output
endif

all: $(TARGET)$(EXEEXT)

portable:
	$(MAKE) clean
	$(MAKE) CFLAGS="$(CFLAGS_PORTABLE)" all

avx2:
	$(MAKE) clean
	$(MAKE) CFLAGS="$(CFLAGS_AVX2)" all

best:
	$(MAKE) clean
	$(MAKE) CFLAGS="$(CFLAGS_BEST)" all

$(TARGET)$(EXEEXT): $(OBJS)
	$(CC) $(CPPFLAGS) $(CFLAGS) -o $@ $(OBJS)

CryptHash_AlgorithmInstance.o: CryptHash_AlgorithmInstance.c CryptHash_AlgorithmInstance.h axis_core.h def.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

axis_core.o: axis_core.c axis_core.h def.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

drng.o: drng.c drng.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

KAT_CryptHash.o: KAT_CryptHash.c drng.h CryptHash_AlgorithmInstance.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

kat: $(TARGET)$(EXEEXT)
	$(RUN_TARGET)

clean:
	$(CLEAN_CMD)
