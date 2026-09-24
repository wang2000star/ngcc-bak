CC ?= gcc
IS_X86 := $(filter x86_64 i386 i686,$(shell uname -m))
.DEFAULT_GOAL := vistrutith_d3_512s_bench

# Optimized vistrutith-d3-512s:
# - Single-core build (no OpenMP)
# - x86 defaults to AES-NI accelerated vistrutah PRG path
CFLAGS = -O3 -std=c11 -pedantic -Wall -Wextra \
         -I. -I./utils_vistrutah \
         -include fallbacks.h
LDFLAGS = -lm
TIMING ?= 0
ifeq ($(TIMING),1)
CFLAGS += -DSIG_TIMING -D_POSIX_C_SOURCE=200809L
endif

NDEBUG ?= 1
LTO_FLAG := -flto
ifeq (,$(findstring clang,$(shell $(CC) --version 2>/dev/null)))
LTO_FLAG := -flto=auto
endif
ifeq ($(NDEBUG),1)
ifeq ($(IS_X86),)
CFLAGS += -DNDEBUG -O3 $(LTO_FLAG)
else
CFLAGS += -DNDEBUG -march=native $(LTO_FLAG)
endif
endif

ifneq ($(IS_X86),)
PRG_ACCE ?= 1
FIELD_PCLMUL ?= 1
else
# Keep non-x86 Optimized builds on the same portable path as Reference.
override PRG_ACCE := 0
override FIELD_PCLMUL := 0
override USE_SBOX_TABLE := 1
endif
ifeq ($(FIELD_PCLMUL),1)
CFLAGS += -mpclmul -DVISTRUTITH_FIELD_PCLMUL
endif

ifeq ($(PRG_ACCE),1)
USE_SBOX_TABLE ?= 0
else
USE_SBOX_TABLE ?= 1
endif
ifeq ($(USE_SBOX_TABLE),1)
CFLAGS += -DSBOX=1 -DSBOX_TABLE
endif

CFLAGS += -DPRG_ACCE=$(PRG_ACCE) -DVISTRUTITH_ENABLE_AESNI=$(PRG_ACCE)
ifneq ($(IS_X86),)
ifeq ($(PRG_ACCE),1)
CFLAGS += -maes -DVISTRUTITH_FAEST_AVX_SBOX=1 -DVISTRUTITH_ASSUME_AESNI=1
endif
endif

COMMON_SRCS = \
  auxfunc.c bavc.c compat.c drng.c fields.c params.c prg.c random_oracle.c sig_impl.c universal_hashing.c utils.c vole.c

VISTRUTITH_SRCS = \
  utils_vistrutah/sig_impl_vistrutith.c \
  utils_vistrutah/vistrutah.c \
  utils_vistrutah/vistrutith_witness.c \
  utils_vistrutah/vistrutith_constraints.c \
  utils_vistrutah/vistrutith_vistrutah_512.c

CORE_SRCS = $(COMMON_SRCS) $(VISTRUTITH_SRCS) vistrutith_d3_512s.c
INSTANCE_SRC = vistrutith_d3_512s_AlgorithmInstance.c
SOURCES = $(CORE_SRCS) $(INSTANCE_SRC)
OBJECTS = $(SOURCES:.c=.o)

all: vistrutith_d3_512s_bench

KAT_SIG: KAT_SIG.c $(INSTANCE_SRC) $(CORE_SRCS)
	$(CC) $(CFLAGS) -o $@ KAT_SIG.c $(INSTANCE_SRC) $(CORE_SRCS) $(LDFLAGS)

vistrutith_d3_512s_bench: vistrutith_d3_512s_bench.c $(INSTANCE_SRC) $(CORE_SRCS)
	$(CC) $(CFLAGS) -o $@ vistrutith_d3_512s_bench.c $(INSTANCE_SRC) $(CORE_SRCS) $(LDFLAGS)

vistrutith_d3_512s_test: vistrutith_d3_512s_test.c $(INSTANCE_SRC) $(CORE_SRCS)
	$(CC) $(CFLAGS) -o $@ vistrutith_d3_512s_test.c $(INSTANCE_SRC) $(CORE_SRCS) $(LDFLAGS)

clean:
	rm -f vistrutith_d3_512s_test vistrutith_d3_512_test vistrutith_d3_512s_bench KAT_SIG \
	      $(OBJECTS)
	rm -f *.o utils_sm4/*.o utils_ballet/*.o utils_ublock/*.o utils_vistrutah/*.o
	rm -rf output

.PHONY: all clean KAT_SIG vistrutith_d3_512s_bench vistrutith_d3_512s_test
