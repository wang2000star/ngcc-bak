# Viper KEM AVX2 Implementation

This directory contains the AVX2 implementation of Viper KEM.

- `make` builds the implementation.
- `make test` runs correctness tests.
- `make kat` generates deterministic KEM KAT files.

The `tches2021_ntt/` directory is an intentionally retained third-party optimized backend used by this AVX2 implementation, with its own license and attribution.
