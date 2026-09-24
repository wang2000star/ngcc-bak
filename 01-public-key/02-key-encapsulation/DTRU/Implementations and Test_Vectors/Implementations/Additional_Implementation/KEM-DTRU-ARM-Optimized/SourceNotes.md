# Source Code Overview

This directory contains the source code delivery for `KEM-DTRU-ARM-Optimized`. The implementation maps to the `m4fspeed` variant, covering all seven DTRU parameter sets.

| Parameter Set | Algorithm Source Directory |
| --- | --- |
| DTRU-Light | `crypto_kem/dtru-light/m4fspeed` |
| DTRU-648 | `crypto_kem/dtru-648/m4fspeed` |
| DTRU-768 | `crypto_kem/dtru-768/m4fspeed` |
| DTRU-1024 | `crypto_kem/dtru-1024/m4fspeed` |
| DTRU-1536 | `crypto_kem/dtru-1536/m4fspeed` |
| DTRU-2048 | `crypto_kem/dtru-2048/m4fspeed` |
| DTRU-Prime | `crypto_kem/dtru-prime/m4fspeed` |

| Directory/File | Description |
| --- | --- |
| `common/` | STM32F4 HAL, random number generation, and serial output helper code |
| `mupq/` | Test framework for test, speed, stack, profiling, and testvectors |
| `mk/`, `ldscripts/`, `Makefile` | Cortex-M4 build system and linker scripts |
| `Test_Vectors/` | Fixed test vectors for standard KAT and `PK_PACK_OPT` KAT |
| `kat.py` | Bundled KAT verification script; defaults to standard KAT verification, use `--pk-pack-opt` for public key compression optimized KAT |
| `benchmarks.py` | Entry point for speed, stack, profiling, and size benchmarks |
