# SPDX-License-Identifier: Apache-2.0 or CC0-1.0
#
# Convenience wrapper: build + run the ICCS KAT verifier for THIS
# implementation against the project-level Test_Vectors/ directory
#
# Examples:
#   make                                  # build & run under QEMU (mps2-an386)
#   make PLATFORM=stm32f4discovery UART=/dev/ttyUSB0   # on a physical board
#
# Everything is driven through the top-level pqm4/mupq build via ../../../kat.py.

TOP      := ../../..
SCHEME   := crypto_kem/bw-kem-128/m4fspeed
PLATFORM ?= mps2-an386
UART     ?=

.PHONY: kat clean
kat:
	cd $(TOP) && ./kat.py -p $(PLATFORM) $(if $(UART),-u $(UART)) $(SCHEME)

clean:
	$(MAKE) -C $(TOP) clean
