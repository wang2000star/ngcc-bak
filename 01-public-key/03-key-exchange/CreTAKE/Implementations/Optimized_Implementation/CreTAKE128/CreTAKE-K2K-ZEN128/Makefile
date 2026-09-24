CC = gcc
CFLAGS += -O3 -march=x86-64 -mavx2 -mtune=native -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra

ifeq ($(USE_LTO),1)
CFLAGS += -flto
AR := gcc-ar
endif


# ----------------------------------------------------------------------
# Underlying primitive directories and libraries
# ----------------------------------------------------------------------

KEM_DIR := ../../Common/primitives/kem/ZEN_128
KEM_LIB := $(KEM_DIR)/libzen128.a

INCLUDES := \
	-I. \
	-I$(KEM_DIR)

# ----------------------------------------------------------------------
# Protocol sources
# ----------------------------------------------------------------------

CORE_OBJS := KEX_AlgorithmInstance.o twokem.o auxfunc.o drng.o secure_bzero.o
KAT_KEX_OBJS := KEX_AlgorithmInstance.o twokem.o auxfunc.o drng.o secure_bzero.o

# ----------------------------------------------------------------------
# Primitive source dependencies
# ----------------------------------------------------------------------

KEM_INPUTS := \
	$(wildcard $(KEM_DIR)/*.c) \
	$(wildcard $(KEM_DIR)/*.h) \
	$(KEM_DIR)/Makefile

# ----------------------------------------------------------------------
# Main targets
# ----------------------------------------------------------------------

#all: test_correctness test_efficiency run_kat_kex
all: test_correctness test_efficiency KAT_KEX

# ----------------------------------------------------------------------
# Build underlying primitive libraries
# ----------------------------------------------------------------------

$(KEM_LIB): $(KEM_INPUTS)
	$(MAKE) -C $(KEM_DIR) \
		CC="$(CC)" \
		AR="$(AR)" \
		libzen128.a

# ----------------------------------------------------------------------
# Compile protocol source files
# ----------------------------------------------------------------------

%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# ----------------------------------------------------------------------
# Link protocol test executables
# ----------------------------------------------------------------------

test_correctness: $(CORE_OBJS) test_correctness.c $(KEM_LIB)
	$(CC) $(CFLAGS) $(INCLUDES) \
		test_correctness.c \
		$(CORE_OBJS) \
		$(KEM_LIB) \
		-o $@

test_efficiency: $(CORE_OBJS) test_efficiency.c $(KEM_LIB)
	$(CC) $(CFLAGS) $(INCLUDES) \
		test_efficiency.c \
		$(CORE_OBJS) \
		$(KEM_LIB) \
		-o $@

KAT_KEX: $(KAT_KEX_OBJS) KAT_KEX.c $(KEM_LIB)
	$(CC) $(CFLAGS) $(INCLUDES) \
		KAT_KEX.c \
		$(KAT_KEX_OBJS) \
		$(KEM_LIB) \
		-o $@

#run_kat_kex: KAT_KEX
#	mkdir -p output
#	./KAT_KEX

# ----------------------------------------------------------------------
# Cleaning
# ----------------------------------------------------------------------

clean:
	rm -f *.o test_correctness test_efficiency KAT_KEX

clean-all: clean
	$(MAKE) -C $(KEM_DIR) clean-kem-lib

.PHONY: all clean clean-all KAT_KEX rebuild
