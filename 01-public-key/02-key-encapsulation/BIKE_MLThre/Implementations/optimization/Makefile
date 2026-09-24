CC := gcc
AR := ar

SECURITY ?= 128
BUILD_DIR := build_kat_$(SECURITY)
SRC_ROOT := bike_kem_ml

CFLAGS := -O3 -ggdb -fPIC -std=c99 -Wall -Wextra -Wno-unused-parameter
CPPFLAGS := -I$(SRC_ROOT)/include \
            -I$(SRC_ROOT)/include/internal \
            -I$(SRC_ROOT)/src/third_party_src \
            -I$(SRC_ROOT)/tests/FromNIST \
            -I$(SRC_ROOT)/kat \
            -DX86_64 \
            -DSECURITY_BITS=$(SECURITY) \
            -DUSE_NIST_RAND \
            -DBIKE_MLTHRE_ENABLED=1 \
            -DBIKE_MLTHRE_DELTA_ENABLED=1 \
            -DBIKE_MLTHRE_SAMPLING=0 \
	            -DBIKE_L7_REFERENCE_DECODER=1 \
	            -DBIKE_L7_DYNAMIC_THRESHOLD=1 \
	            -DBIKE_L7_EMPIRICAL_THRESHOLD=0 \
	            -DUSE_API_PKC_AUX=1 \
	            -DSTANDALONE_IMPL=1
LDLIBS := -lcrypto -lm

LIB_TARGET := $(BUILD_DIR)/libbike_kem_ml.a
KAT_TARGET := $(BUILD_DIR)/api-pkc-kat

CORE_SRC := \
  $(SRC_ROOT)/src/kem.c \
  $(SRC_ROOT)/src/common/cpu_features.c \
  $(SRC_ROOT)/src/common/error.c \
  $(SRC_ROOT)/src/common/utilities.c \
  $(SRC_ROOT)/src/decode/decode.c \
  $(SRC_ROOT)/src/decode/mlthre_model.c \
  $(SRC_ROOT)/src/decode/mlthre_sampling.c \
  $(SRC_ROOT)/src/decode/decode_portable.c \
  $(SRC_ROOT)/src/decode/decode_avx2.c \
  $(SRC_ROOT)/src/decode/decode_avx512.c \
  $(SRC_ROOT)/src/gf2x/gf2x_mul.c \
  $(SRC_ROOT)/src/gf2x/gf2x_mul_portable.c \
  $(SRC_ROOT)/src/gf2x/gf2x_mul_base_portable.c \
  $(SRC_ROOT)/src/gf2x/gf2x_inv.c \
  $(SRC_ROOT)/src/gf2x/gf2x_ksqr_portable.c \
  $(SRC_ROOT)/src/gf2x/gf2x_mul_avx2.c \
  $(SRC_ROOT)/src/gf2x/gf2x_mul_avx512.c \
  $(SRC_ROOT)/src/gf2x/gf2x_mul_base_pclmul.c \
  $(SRC_ROOT)/src/gf2x/gf2x_mul_base_vpclmul.c \
  $(SRC_ROOT)/src/gf2x/gf2x_ksqr_avx2.c \
  $(SRC_ROOT)/src/gf2x/gf2x_ksqr_avx512.c \
  $(SRC_ROOT)/src/random/sampling.c \
	  $(SRC_ROOT)/src/random/sampling_portable.c \
	  $(SRC_ROOT)/src/random/sampling_avx2.c \
	  $(SRC_ROOT)/src/random/sampling_avx512.c \
	  $(SRC_ROOT)/src/random/aux_prf.c \
	  $(SRC_ROOT)/src/third_party_src/auxfunc.c

KAT_SRC := \
  $(SRC_ROOT)/kat/KAT_KEM.c \
  $(SRC_ROOT)/kat/KEM_AlgorithmInstance.c \
  $(SRC_ROOT)/kat/drng.c \
  $(SRC_ROOT)/tests/FromNIST/rng.c

CORE_OBJ := $(patsubst $(SRC_ROOT)/%.c,$(BUILD_DIR)/%.o,$(CORE_SRC))
KAT_OBJ := $(patsubst $(SRC_ROOT)/%.c,$(BUILD_DIR)/%.o,$(KAT_SRC))

AVX2_FILES := \
  $(SRC_ROOT)/src/decode/decode_avx2.c \
  $(SRC_ROOT)/src/gf2x/gf2x_mul_avx2.c \
  $(SRC_ROOT)/src/gf2x/gf2x_ksqr_avx2.c \
  $(SRC_ROOT)/src/random/sampling_avx2.c

AVX512_FILES := \
  $(SRC_ROOT)/src/decode/decode_avx512.c \
  $(SRC_ROOT)/src/gf2x/gf2x_mul_avx512.c \
  $(SRC_ROOT)/src/gf2x/gf2x_ksqr_avx512.c \
  $(SRC_ROOT)/src/random/sampling_avx512.c

PCLMUL_FILE := $(SRC_ROOT)/src/gf2x/gf2x_mul_base_pclmul.c
VPCLMUL_FILE := $(SRC_ROOT)/src/gf2x/gf2x_mul_base_vpclmul.c

.PHONY: all kat kat128 kat192 kat256 kat512 clean distclean

all: $(LIB_TARGET)

kat: $(KAT_TARGET)
	cd $(BUILD_DIR) && ./api-pkc-kat

kat128:
	$(MAKE) clean SECURITY=128
	$(MAKE) kat SECURITY=128

kat192:
	$(MAKE) clean SECURITY=192
	$(MAKE) kat SECURITY=192

kat256:
	$(MAKE) clean SECURITY=256
	$(MAKE) kat SECURITY=256

kat512:
	$(MAKE) clean SECURITY=512
	$(MAKE) kat SECURITY=512

$(LIB_TARGET): $(CORE_OBJ)
	$(AR) rcs $@ $^

$(KAT_TARGET): $(KAT_OBJ) $(LIB_TARGET)
	$(CC) $(CFLAGS) $^ $(LDLIBS) -o $@

$(BUILD_DIR)/%.o: $(SRC_ROOT)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(CPPFLAGS) -c $< -o $@

$(patsubst $(SRC_ROOT)/%.c,$(BUILD_DIR)/%.o,$(AVX2_FILES)): CFLAGS += -mavx2
$(patsubst $(SRC_ROOT)/%.c,$(BUILD_DIR)/%.o,$(AVX512_FILES)): CFLAGS += -mavx512f -mavx512bw -mavx512dq
$(patsubst $(SRC_ROOT)/%.c,$(BUILD_DIR)/%.o,$(PCLMUL_FILE)): CFLAGS += -mpclmul
$(patsubst $(SRC_ROOT)/%.c,$(BUILD_DIR)/%.o,$(VPCLMUL_FILE)): CFLAGS += -mvpclmulqdq -mavx512f -mavx512bw -mavx512dq

clean:
	rm -rf $(BUILD_DIR)

distclean:
	rm -rf build_kat_128 build_kat_192 build_kat_256 build_kat_512
