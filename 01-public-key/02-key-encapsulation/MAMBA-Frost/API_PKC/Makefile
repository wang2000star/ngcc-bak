# Root build entry point for MAMBA-Frost.
.PHONY: all clean check size_test api api-check api-kats api-kat-repro api-clean \
	api-opt api-opt-check api-opt-kats api-opt-kat-repro api-opt-perf api-opt-clean \
	api-cc api-cc-check api-cc-kats api-cc-kat-repro api-cc-opt api-cc-opt-check api-cc-opt-kats api-cc-opt-kat-repro api-cc-opt-perf api-cc-clean

all:
	$(MAKE) -C Frost all

clean:
	$(MAKE) -C Frost clean

check:
	$(MAKE) -C Frost check

size_test:
	$(MAKE) -C Frost size_test

api:
	$(MAKE) -C API_PKC all

api-check:
	$(MAKE) -C API_PKC check

api-kats:
	$(MAKE) -C API_PKC kats

api-kat-repro:
	$(MAKE) -C API_PKC kat-repro

api-clean:
	$(MAKE) -C API_PKC clean

api-opt:
	$(MAKE) -C API_PKC optimized-all

api-opt-check:
	$(MAKE) -C API_PKC optimized-check

api-opt-kats:
	$(MAKE) -C API_PKC optimized-kats

api-opt-kat-repro:
	$(MAKE) -C API_PKC optimized-kat-repro

api-opt-perf:
	$(MAKE) -C API_PKC optimized-perf

api-opt-clean:
	$(MAKE) -C API_PKC optimized-clean

api-cc:
	$(MAKE) -C API_PKC cc-all

api-cc-check:
	$(MAKE) -C API_PKC cc-check

api-cc-kats:
	$(MAKE) -C API_PKC cc-kats

api-cc-kat-repro:
	$(MAKE) -C API_PKC cc-kat-repro

api-cc-opt:
	$(MAKE) -C API_PKC cc-optimized-all

api-cc-opt-check:
	$(MAKE) -C API_PKC cc-optimized-check

api-cc-opt-kats:
	$(MAKE) -C API_PKC cc-optimized-kats

api-cc-opt-kat-repro:
	$(MAKE) -C API_PKC cc-optimized-kat-repro

api-cc-opt-perf:
	$(MAKE) -C API_PKC cc-optimized-perf

api-cc-clean:
	$(MAKE) -C API_PKC cc-clean
