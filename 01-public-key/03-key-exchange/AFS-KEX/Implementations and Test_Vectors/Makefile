# Root Makefile: run the AFS-KEX performance tests for all three instances.
#
#   make            # build & run speed test for C128, C256, C512 (CSV to stdout)
#   make speed      # same as above
#   make NTESTS=10000   # change the number of measurements (default 1000)
#   make clean      # remove all build/ artifacts

REF_DIR := Implementations/Reference_Implementation
INSTANCES := AFS_KEX_C128 AFS_KEX_C256 AFS_KEX_C512

NTESTS ?= 1000

.PHONY: all speed clean $(INSTANCES)

all: speed

# Run each instance's speed test. The header line is printed once; the per-row
# lines from every instance carry the instance name, so the combined output is a
# single CSV ready to paste into a spreadsheet.
speed:
	@first=1; \
	for inst in $(INSTANCES); do \
		if [ $$first -eq 1 ]; then \
			$(MAKE) -s -C $(REF_DIR)/$$inst speed NTESTS=$(NTESTS); \
			first=0; \
		else \
			$(MAKE) -s -C $(REF_DIR)/$$inst speed NTESTS=$(NTESTS) | tail -n +2; \
		fi; \
		$(MAKE) -s -C $(REF_DIR)/$$inst clean; \
	done

clean:
	@for inst in $(INSTANCES); do \
		$(MAKE) -s -C $(REF_DIR)/$$inst clean; \
	done
