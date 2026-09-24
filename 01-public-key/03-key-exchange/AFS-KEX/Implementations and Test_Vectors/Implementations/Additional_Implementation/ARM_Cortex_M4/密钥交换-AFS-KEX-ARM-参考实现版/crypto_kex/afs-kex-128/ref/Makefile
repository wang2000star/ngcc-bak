# SPDX-License-Identifier: Apache-2.0 or CC0-1.0
#
# Convenience wrapper: build + run the ICCS KAT verifier for THIS
# implementation against the project-level Test_Vectors/ directory.
#
# Examples:
#   make PLATFORM=stm32f4discovery UART=/dev/ttyUSB0   # verify on a physical board
#
# Everything is driven through the top-level pqm4/mupq build via ../../../kat.py.

TOP      := ../../..
SCHEME   := crypto_kex/afs-kex-128/ref
PLATFORM ?= mps2-an386
UART     ?=

.PHONY: kat clean
kat:
	cd $(TOP) && ./kat.py -p $(PLATFORM) $(if $(UART),-u $(UART)) $(SCHEME)

clean:
	$(MAKE) -C $(TOP) clean
