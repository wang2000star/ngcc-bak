# ATLAS — MLWR-Based Digital Signature Scheme

This repository contains the reference and AVX2-optimized implementations of **ATLAS**, a lattice-based digital signature scheme built on the Module Learning With Rounding (MLWR) problem, across four Security levels (128, 192, 256, and 512 bits).

## Repository Structure

```
.
└── Implementation/
    ├── Reference_Implementation/
    │   ├── lwrdsa128/
    │   ├── lwrdsa192/
    │   ├── lwrdsa256/
    │   └── lwrdsa512/
    └── Optimized_Implementation/
        ├── lwrdsa128/
        ├── lwrdsa192/
        ├── lwrdsa256/
        └── lwrdsa512/
```

Each `lwrdsaXXX` folder is a self-contained build of the signature scheme for that specific security level, containing the following types of files:

| File | Description |
|---|---|
| `SIG_lwrdsaXXX.c` | Core signature scheme implementation (key generation, signing, verification) |
| `polyvec.c` / `polyvec.h` | Polynomial vector operations |
| `poly.c` / `poly.h` | Polynomial arithmetic |
| `packing.c` / `packing.h` | Serialization/deserialization of keys and signatures |
| `rounding.c` / `rounding.h` | Rounding operations for the MLWR problem |
| `auxfunc.c` / `auxfunc.h` | Auxiliary helper functions |
| `drng.c` / `drng.h` | Deterministic random number generation |
| `api.h` | Public API definitions |
| `params.h` | Security-level-specific parameters |
| `SIG_AlgorithmInstance.h` | Algorithm instance metadata |
| `KAT_SIG.c` | Known Answer Test (KAT) generator |
| `test/` | Benchmarking utilities (`cpucycles`, `speed_print`, `test_speed`) |

## Build Requirements

- **Compiler:** GCC (tested with `gcc 11.4.0`)
- **Platform:** x86-64 with AVX2 support (required for the optimized implementation)
- **OS:** Linux (tested on Ubuntu 22.04.5 LTS)

The Makefile assumes GCC is located at `/usr/bin/gcc`. If your compiler is installed elsewhere, update the `CC` variable in the Makefile or override it on the command line (see below).

## Building

Navigate to the desired implementation and security level directory, for example:

```bash
cd Implementation/Optimized_Implementation/lwrdsa256
```

### Generate Known Answer Tests (KAT)

```bash
make genKAT
./genKAT
```

This compiles and runs the KAT generator, producing reference test vectors for the signature scheme.

### Run Speed Benchmarks

```bash
make bench_speed
./bench_speed
```

This builds and runs the benchmark suite, which measures CPU cycle counts (via hardware performance counters) for key generation, signing, and verification operations.

### Clean Build Artifacts

```bash
make clean
```

This removes the `genKAT` and `bench_speed` binaries, the `output/` directory, and `result_bench_speed.txt`.

### Overriding the Compiler Path

If `/usr/bin/gcc` is not the correct path on your system, override it directly:

```bash
make CC=$(which gcc) genKAT
```

## Compiler Flags

The implementations are compiled with the following flags:

```
-O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra
```

- `-mavx2`: enables AVX2 SIMD instructions, required by the optimized implementation's vectorized polynomial multiplication routines.
- `-flto`: enables link-time optimization.
- `-std=c99`: enforces C99 standard compliance.

> **Note:** The reference implementation directories use `-O2` rather than `-O3` to align with the unoptimized baseline used for performance comparisons. Confirm the optimization level in each directory's Makefile if you intend to reproduce published benchmark figures.

## Security Levels

| Directory | Security Level |
|---|---|
| `lwrdsa128` | 128-bit |
| `lwrdsa192` | 192-bit |
| `lwrdsa256` | 256-bit |
| `lwrdsa512` | 512-bit |

Build and benchmark each level independently by repeating the build steps above within the corresponding directory.

# Reference Implementation of ATLAS-128
./Reference_Implementation/lwrdsa128/api.h
./Reference_Implementation/lwrdsa128/auxfunc.c
./Reference_Implementation/lwrdsa128/auxfunc.h
./Reference_Implementation/lwrdsa128/drng.c
./Reference_Implementation/lwrdsa128/drng.h
./Reference_Implementation/lwrdsa128/KAT_SIG.c
./Reference_Implementation/lwrdsa128/Makefile
./Reference_Implementation/lwrdsa128/packing.c
./Reference_Implementation/lwrdsa128/packing.h
./Reference_Implementation/lwrdsa128/params.h
./Reference_Implementation/lwrdsa128/poly.c
./Reference_Implementation/lwrdsa128/poly.h
./Reference_Implementation/lwrdsa128/polyvec.c
./Reference_Implementation/lwrdsa128/polyvec.h
./Reference_Implementation/lwrdsa128/rounding.c
./Reference_Implementation/lwrdsa128/rounding.h
./Reference_Implementation/lwrdsa128/SIG_AlgorithmInstance.h
./Reference_Implementation/lwrdsa128/SIG_lwrdsa128.c
./Reference_Implementation/lwrdsa128/test/cpucycles.c
./Reference_Implementation/lwrdsa128/test/cpucycles.h
./Reference_Implementation/lwrdsa128/test/speed_print.c
./Reference_Implementation/lwrdsa128/test/speed_print.h
./Reference_Implementation/lwrdsa128/test/test_speed.c

# Reference Implementation of ATLAS-192
./Reference_Implementation/lwrdsa192/api.h
./Reference_Implementation/lwrdsa192/auxfunc.c
./Reference_Implementation/lwrdsa192/auxfunc.h
./Reference_Implementation/lwrdsa192/drng.c
./Reference_Implementation/lwrdsa192/drng.h
./Reference_Implementation/lwrdsa192/KAT_SIG.c
./Reference_Implementation/lwrdsa192/Makefile
./Reference_Implementation/lwrdsa192/packing.c
./Reference_Implementation/lwrdsa192/packing.h
./Reference_Implementation/lwrdsa192/params.h
./Reference_Implementation/lwrdsa192/poly.c
./Reference_Implementation/lwrdsa192/poly.h
./Reference_Implementation/lwrdsa192/polyvec.c
./Reference_Implementation/lwrdsa192/polyvec.h
./Reference_Implementation/lwrdsa192/rounding.c
./Reference_Implementation/lwrdsa192/rounding.h
./Reference_Implementation/lwrdsa192/SIG_AlgorithmInstance.h
./Reference_Implementation/lwrdsa192/SIG_lwrdsa192.c
./Reference_Implementation/lwrdsa192/test/cpucycles.c
./Reference_Implementation/lwrdsa192/test/cpucycles.h
./Reference_Implementation/lwrdsa192/test/speed_print.c
./Reference_Implementation/lwrdsa192/test/speed_print.h
./Reference_Implementation/lwrdsa192/test/test_speed.c

# Reference Implementation of ATLAS-256
./Reference_Implementation/lwrdsa256/api.h
./Reference_Implementation/lwrdsa256/auxfunc.c
./Reference_Implementation/lwrdsa256/auxfunc.h
./Reference_Implementation/lwrdsa256/drng.c
./Reference_Implementation/lwrdsa256/drng.h
./Reference_Implementation/lwrdsa256/KAT_SIG.c
./Reference_Implementation/lwrdsa256/Makefile
./Reference_Implementation/lwrdsa256/packing.c
./Reference_Implementation/lwrdsa256/packing.h
./Reference_Implementation/lwrdsa256/params.h
./Reference_Implementation/lwrdsa256/poly.c
./Reference_Implementation/lwrdsa256/poly.h
./Reference_Implementation/lwrdsa256/polyvec.c
./Reference_Implementation/lwrdsa256/polyvec.h
./Reference_Implementation/lwrdsa256/rounding.c
./Reference_Implementation/lwrdsa256/rounding.h
./Reference_Implementation/lwrdsa256/SIG_AlgorithmInstance.h
./Reference_Implementation/lwrdsa256/SIG_lwrdsa256.c
./Reference_Implementation/lwrdsa256/test/cpucycles.c
./Reference_Implementation/lwrdsa256/test/cpucycles.h
./Reference_Implementation/lwrdsa256/test/speed_print.c
./Reference_Implementation/lwrdsa256/test/speed_print.h
./Reference_Implementation/lwrdsa256/test/test_speed.c

# Reference Implementation of ATLAS-512
./Reference_Implementation/lwrdsa512/api.h
./Reference_Implementation/lwrdsa512/auxfunc.c
./Reference_Implementation/lwrdsa512/auxfunc.h
./Reference_Implementation/lwrdsa512/drng.c
./Reference_Implementation/lwrdsa512/drng.h
./Reference_Implementation/lwrdsa512/KAT_SIG.c
./Reference_Implementation/lwrdsa512/Makefile
./Reference_Implementation/lwrdsa512/packing.c
./Reference_Implementation/lwrdsa512/packing.h
./Reference_Implementation/lwrdsa512/params.h
./Reference_Implementation/lwrdsa512/poly.c
./Reference_Implementation/lwrdsa512/poly.h
./Reference_Implementation/lwrdsa512/polyvec.c
./Reference_Implementation/lwrdsa512/polyvec.h
./Reference_Implementation/lwrdsa512/rounding.c
./Reference_Implementation/lwrdsa512/rounding.h
./Reference_Implementation/lwrdsa512/SIG_AlgorithmInstance.h
./Reference_Implementation/lwrdsa512/SIG_lwrdsa512.c
./Reference_Implementation/lwrdsa512/test/cpucycles.c
./Reference_Implementation/lwrdsa512/test/cpucycles.h
./Reference_Implementation/lwrdsa512/test/speed.c
./Reference_Implementation/lwrdsa512/test/speed.h
./Reference_Implementation/lwrdsa512/test/speed_print.c
./Reference_Implementation/lwrdsa512/test/speed_print.h
./Reference_Implementation/lwrdsa512/test/test_speed.c

# Optimized Implementation of ATLAS-128
./Optimized Implementation/lwrdsa128/api.h
./Optimized Implementation/lwrdsa128/auxfunc.c
./Optimized Implementation/lwrdsa128/auxfunc.h
./Optimized Implementation/lwrdsa128/drng.c
./Optimized Implementation/lwrdsa128/drng.h
./Optimized Implementation/lwrdsa128/KAT_SIG.c
./Optimized Implementation/lwrdsa128/Makefile
./Optimized Implementation/lwrdsa128/packing.c
./Optimized Implementation/lwrdsa128/packing.h
./Optimized Implementation/lwrdsa128/params.h
./Optimized Implementation/lwrdsa128/poly.c
./Optimized Implementation/lwrdsa128/poly.h
./Optimized Implementation/lwrdsa128/polyvec.c
./Optimized Implementation/lwrdsa128/polyvec.h
./Optimized Implementation/lwrdsa128/rounding.c
./Optimized Implementation/lwrdsa128/rounding.h
./Optimized Implementation/lwrdsa128/SIG_AlgorithmInstance.h
./Optimized Implementation/lwrdsa128/SIG_lwrdsa128.c
./Optimized Implementation/lwrdsa128/test/cpucycles.c
./Optimized Implementation/lwrdsa128/test/cpucycles.h
./Optimized Implementation/lwrdsa128/test/speed_print.c
./Optimized Implementation/lwrdsa128/test/speed_print.h
./Optimized Implementation/lwrdsa128/test/test_speed.c

# Optimized Implementation of ATLAS-192
./Optimized Implementation/lwrdsa192/api.h
./Optimized Implementation/lwrdsa192/auxfunc.c
./Optimized Implementation/lwrdsa192/auxfunc.h
./Optimized Implementation/lwrdsa192/drng.c
./Optimized Implementation/lwrdsa192/drng.h
./Optimized Implementation/lwrdsa192/KAT_SIG.c
./Optimized Implementation/lwrdsa192/Makefile
./Optimized Implementation/lwrdsa192/packing.c
./Optimized Implementation/lwrdsa192/packing.h
./Optimized Implementation/lwrdsa192/params.h
./Optimized Implementation/lwrdsa192/poly.c
./Optimized Implementation/lwrdsa192/poly.h
./Optimized Implementation/lwrdsa192/polyvec.c
./Optimized Implementation/lwrdsa192/polyvec.h
./Optimized Implementation/lwrdsa192/rounding.c
./Optimized Implementation/lwrdsa192/rounding.h
./Optimized Implementation/lwrdsa192/SIG_AlgorithmInstance.h
./Optimized Implementation/lwrdsa192/SIG_lwrdsa192.c
./Optimized Implementation/lwrdsa192/test/cpucycles.c
./Optimized Implementation/lwrdsa192/test/cpucycles.h
./Optimized Implementation/lwrdsa192/test/speed_print.c
./Optimized Implementation/lwrdsa192/test/speed_print.h
./Optimized Implementation/lwrdsa192/test/test_speed.c

# Optimized Implementation of ATLAS-256
./Optimized Implementation/lwrdsa256/api.h
./Optimized Implementation/lwrdsa256/auxfunc.c
./Optimized Implementation/lwrdsa256/auxfunc.h
./Optimized Implementation/lwrdsa256/drng.c
./Optimized Implementation/lwrdsa256/drng.h
./Optimized Implementation/lwrdsa256/KAT_SIG.c
./Optimized Implementation/lwrdsa256/Makefile
./Optimized Implementation/lwrdsa256/packing.c
./Optimized Implementation/lwrdsa256/packing.h
./Optimized Implementation/lwrdsa256/params.h
./Optimized Implementation/lwrdsa256/poly.c
./Optimized Implementation/lwrdsa256/poly.h
./Optimized Implementation/lwrdsa256/polyvec.c
./Optimized Implementation/lwrdsa256/polyvec.h
./Optimized Implementation/lwrdsa256/rounding.c
./Optimized Implementation/lwrdsa256/rounding.h
./Optimized Implementation/lwrdsa256/SIG_AlgorithmInstance.h
./Optimized Implementation/lwrdsa256/SIG_lwrdsa256.c
./Optimized Implementation/lwrdsa256/test/cpucycles.c
./Optimized Implementation/lwrdsa256/test/cpucycles.h
./Optimized Implementation/lwrdsa256/test/speed_print.c
./Optimized Implementation/lwrdsa256/test/speed_print.h
./Optimized Implementation/lwrdsa256/test/test_speed.c

# Optimized Implementation of ATLAS-512
./Optimized Implementation/lwrdsa512/api.h
./Optimized Implementation/lwrdsa512/auxfunc.c
./Optimized Implementation/lwrdsa512/auxfunc.h
./Optimized Implementation/lwrdsa512/drng.c
./Optimized Implementation/lwrdsa512/drng.h
./Optimized Implementation/lwrdsa512/KAT_SIG.c
./Optimized Implementation/lwrdsa512/Makefile
./Optimized Implementation/lwrdsa512/packing.c
./Optimized Implementation/lwrdsa512/packing.h
./Optimized Implementation/lwrdsa512/params.h
./Optimized Implementation/lwrdsa512/poly.c
./Optimized Implementation/lwrdsa512/poly.h
./Optimized Implementation/lwrdsa512/polyvec.c
./Optimized Implementation/lwrdsa512/polyvec.h
./Optimized Implementation/lwrdsa512/rounding.c
./Optimized Implementation/lwrdsa512/rounding.h
./Optimized Implementation/lwrdsa512/SIG_AlgorithmInstance.h
./Optimized Implementation/lwrdsa512/SIG_lwrdsa512.c
./Optimized Implementation/lwrdsa512/test/cpucycles.c
./Optimized Implementation/lwrdsa512/test/cpucycles.h
./Optimized Implementation/lwrdsa512/test/speed.c
./Optimized Implementation/lwrdsa512/test/speed.h
./Optimized Implementation/lwrdsa512/test/speed_print.c
./Optimized Implementation/lwrdsa512/test/speed_print.h
./Optimized Implementation/lwrdsa512/test/test_speed.c
