CC      = gcc
CFLAGS  = -DUSE_API_PKC -O3 -march=native -mtune=native

INSTANCES = UVW-128 UVW-256 UVW-512

SRCS_COMMON = KAT_SIG.c \
              SIG_AlgorithmInstance.c \
              uvw.c \
              gauss.c \
              auxfunc.c \
              drng.c \
              fq_arithmetic/vf3.c \
              fq_arithmetic/mf3.c \
              fq_arithmetic/dp.c

TEST_VECTORS_DIR = ../Test_Vectors

.PHONY: all clean kat $(INSTANCES)

all: kat

kat: $(addprefix $(TEST_VECTORS_DIR)/KAT_SIG_,$(addsuffix .txt,$(INSTANCES)))

$(TEST_VECTORS_DIR)/KAT_SIG_%.txt: %
	@echo "=== Generating test vectors for $* ==="
	cd $< && ./KAT_SIG

define BUILD_RULE
$(1)/KAT_SIG:
	@echo "=== Building $(1) ==="
	$$(CC) $$(CFLAGS) -I$(1) -o $$@ $$(addprefix $(1)/,$$(SRCS_COMMON))
endef

$(foreach inst,$(INSTANCES),$(eval $(call BUILD_RULE,$(inst))))

$(TEST_VECTORS_DIR):
	mkdir -p $(TEST_VECTORS_DIR)

$(addprefix $(TEST_VECTORS_DIR)/KAT_SIG_,$(addsuffix .txt,$(INSTANCES))): | $(TEST_VECTORS_DIR)

clean:
	rm -f $(addsuffix /KAT_SIG,$(INSTANCES))
	rm -rf output
