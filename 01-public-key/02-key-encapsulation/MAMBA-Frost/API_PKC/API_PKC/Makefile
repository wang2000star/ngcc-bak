# One-command build, test and KAT orchestration for all submitted KEM instances.
FROST_INSTANCES := MAMBA-Frost-128 MAMBA-Frost-192 MAMBA-Frost-256 MAMBA-Frost-384 MAMBA-Frost-512
FROST_CC_INSTANCES := MAMBA-Frost-CC-128 MAMBA-Frost-CC-192 MAMBA-Frost-CC-256 MAMBA-Frost-CC-384 MAMBA-Frost-CC-512
INSTANCES := $(FROST_INSTANCES) $(FROST_CC_INSTANCES)
REFERENCE := Implementations/Reference_Implementation
OPTIMIZED := Implementations/Optimized_Implementation
TEST_VECTOR_DIR := Test_Vectors

.PHONY: all smoke check kats kat-repro clean \
	optimized-all optimized-smoke optimized-check optimized-kats optimized-kat-repro optimized-perf optimized-clean \
	cc-all cc-smoke cc-check cc-kats cc-kat-repro cc-optimized-all cc-optimized-smoke cc-optimized-check cc-optimized-kats cc-optimized-kat-repro cc-optimized-perf cc-clean \
	$(INSTANCES)
all: $(INSTANCES)

$(INSTANCES):
	$(MAKE) -C $(REFERENCE)/$@ all

smoke: all
	@set -e; for instance in $(INSTANCES); do \
		$(MAKE) -C $(REFERENCE)/$$instance smoke; \
	done

check: all
	@set -e; for instance in $(INSTANCES); do \
		$(MAKE) -C $(REFERENCE)/$$instance check; \
	done

kats: all
	@mkdir -p $(TEST_VECTOR_DIR)
	@set -e; for instance in $(INSTANCES); do \
		$(MAKE) -C $(REFERENCE)/$$instance kat-generate; \
		cp $(REFERENCE)/$$instance/output/KAT_KEM_$$instance.txt $(TEST_VECTOR_DIR)/; \
	done

kat-repro: all
	@set -e; for instance in $(INSTANCES); do \
		$(MAKE) -C $(REFERENCE)/$$instance kat-repro; \
	done

clean:
	@for instance in $(INSTANCES); do \
		$(MAKE) -C $(REFERENCE)/$$instance clean; \
	done
	rm -f $(TEST_VECTOR_DIR)/KAT_KEM_MAMBA-Frost-*.txt

optimized-all:
	@set -e; for instance in $(INSTANCES); do \
		$(MAKE) -C $(OPTIMIZED)/$$instance all; \
	done

optimized-smoke: optimized-all
	@set -e; for instance in $(INSTANCES); do \
		$(MAKE) -C $(OPTIMIZED)/$$instance smoke; \
	done

optimized-check: optimized-all
	@set -e; for instance in $(INSTANCES); do \
		$(MAKE) -C $(OPTIMIZED)/$$instance check; \
	done

optimized-kats: optimized-all
	@mkdir -p $(TEST_VECTOR_DIR)
	@set -e; for instance in $(INSTANCES); do \
		$(MAKE) -C $(OPTIMIZED)/$$instance kat-install; \
	done

optimized-kat-repro: optimized-all
	@set -e; for instance in $(INSTANCES); do \
		$(MAKE) -C $(OPTIMIZED)/$$instance kat-repro; \
	done

optimized-perf: optimized-all
	@set -e; for instance in $(INSTANCES); do \
		$(MAKE) -C $(OPTIMIZED)/$$instance perf-run; \
	done

optimized-clean:
	@for instance in $(INSTANCES); do \
		$(MAKE) -C $(OPTIMIZED)/$$instance clean; \
	done

cc-all:
	@set -e; for instance in $(FROST_CC_INSTANCES); do \
		$(MAKE) -C $(REFERENCE)/$$instance all; \
	done

cc-smoke: cc-all
	@set -e; for instance in $(FROST_CC_INSTANCES); do \
		$(MAKE) -C $(REFERENCE)/$$instance smoke; \
	done

cc-check: cc-all
	@set -e; for instance in $(FROST_CC_INSTANCES); do \
		$(MAKE) -C $(REFERENCE)/$$instance check; \
	done

cc-kats: cc-all
	@mkdir -p $(TEST_VECTOR_DIR)
	@set -e; for instance in $(FROST_CC_INSTANCES); do \
		$(MAKE) -C $(REFERENCE)/$$instance kat-install; \
	done

cc-kat-repro: cc-all
	@set -e; for instance in $(FROST_CC_INSTANCES); do \
		$(MAKE) -C $(REFERENCE)/$$instance kat-repro; \
	done

cc-optimized-all:
	@set -e; for instance in $(FROST_CC_INSTANCES); do \
		$(MAKE) -C $(OPTIMIZED)/$$instance all; \
	done

cc-optimized-smoke: cc-optimized-all
	@set -e; for instance in $(FROST_CC_INSTANCES); do \
		$(MAKE) -C $(OPTIMIZED)/$$instance smoke; \
	done

cc-optimized-check: cc-optimized-all
	@set -e; for instance in $(FROST_CC_INSTANCES); do \
		$(MAKE) -C $(OPTIMIZED)/$$instance check; \
	done

cc-optimized-kats: cc-optimized-all
	@mkdir -p $(TEST_VECTOR_DIR)
	@set -e; for instance in $(FROST_CC_INSTANCES); do \
		$(MAKE) -C $(OPTIMIZED)/$$instance kat-install; \
	done

cc-optimized-kat-repro: cc-optimized-all
	@set -e; for instance in $(FROST_CC_INSTANCES); do \
		$(MAKE) -C $(OPTIMIZED)/$$instance kat-repro; \
	done

cc-optimized-perf: cc-optimized-all
	@set -e; for instance in $(FROST_CC_INSTANCES); do \
		$(MAKE) -C $(OPTIMIZED)/$$instance perf-run; \
	done

cc-clean:
	@for instance in $(FROST_CC_INSTANCES); do \
		$(MAKE) -C $(REFERENCE)/$$instance clean; \
		$(MAKE) -C $(OPTIMIZED)/$$instance clean; \
	done
	rm -f $(TEST_VECTOR_DIR)/KAT_KEM_MAMBA-Frost-CC-*.txt
