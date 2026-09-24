# Lore KEM Implementations

This repository contains implementations of Lore KEM, a lattice-based post-quantum Key Encapsulation Mechanism over ( \mathbb{Z}_{257} ) with sparse fixed-weight secret keys.

This release contains two hash backends:

* `Lore-SHAKE`: SHA3/SHAKE-based implementation.
* `Lore-SM3`: SM3-based implementation.

It also contains three implementation families:

* Reference portable C implementation.
* AVX2 optimized implementation for x86-64.
* NEON optimized implementation for ARM64.

The supported security levels are:

| Level | Classical Security | KAPPA |
| ----- | -----------------: | ----: |
| L1    |            128-bit |   128 |
| L2    |            256-bit |   256 |
| L3    |            384-bit |   384 |
| L4    |            512-bit |   512 |

## Directory Structure

```text
.
├── bench/
│   ├── run_lore_measurements.sh
│   ├── run_lore_shake_measurements.sh
│   └── run_lore_sm3_measurements.sh
├── Implementations/
│   ├── Reference_Implementation/
│   │   ├── Lore-SHAKE/
│   │   │   ├── Lore-L1/
│   │   │   ├── Lore-L2/
│   │   │   ├── Lore-L3/
│   │   │   └── Lore-L4/
│   │   └── Lore-SM3/
│   │       ├── Lore-L1/
│   │       ├── Lore-L2/
│   │       ├── Lore-L3/
│   │       └── Lore-L4/
│   └── Optimized_Implementation/
│       ├── AVX/
│       │   ├── Lore-SHAKE-AVX/
│       │   │   ├── Lore-L1/
│       │   │   ├── Lore-L2/
│       │   │   ├── Lore-L3/
│       │   │   └── Lore-L4/
│       │   └── Lore-SM3-AVX/
│       │       ├── Lore-L1/
│       │       ├── Lore-L2/
│       │       ├── Lore-L3/
│       │       └── Lore-L4/
│       └── NEON/
│           ├── Lore-SHAKE-NEON/
│           │   ├── Lore-L1/
│           │   ├── Lore-L2/
│           │   ├── Lore-L3/
│           │   └── Lore-L4/
│           └── Lore-SM3-NEON/
│               ├── Lore-L1/
│               ├── Lore-L2/
│               ├── Lore-L3/
│               └── Lore-L4/
├── Test_Vectors/
│   ├── Lore-SHAKE/
│   │   ├── KAT_KEM_Lore-L1.txt
│   │   ├── KAT_KEM_Lore-L2.txt
│   │   ├── KAT_KEM_Lore-L3.txt
│   │   └── KAT_KEM_Lore-L4.txt
│   └── Lore-SM3/
│       ├── KAT_KEM_Lore-L1.txt
│       ├── KAT_KEM_Lore-L2.txt
│       ├── KAT_KEM_Lore-L3.txt
│       └── KAT_KEM_Lore-L4.txt
└── README.md
```

## File Overview

Each `Lore-L*` instance directory contains the source files for one algorithm instance.

| File                                                 | Description                                          |
| ---------------------------------------------------- | ---------------------------------------------------- |
| `api.h`                                              | Public API constants and byte lengths.               |
| `params.h`                                           | Compile-time algorithm parameters.                   |
| `kem.c`, `kem.h`                                     | Top-level KEM implementation.                        |
| `pke.c`, `pke.h`                                     | Public-key encryption layer.                         |
| `indcpa.c`, `indcpa.h`                               | IND-CPA encryption core.                             |
| `poly.c`, `poly.h`                                   | Polynomial arithmetic.                               |
| `polyvec.c`, `polyvec.h`                             | Polynomial-vector arithmetic.                        |
| `ntt.c`, `ntt.h`                                     | NTT-related arithmetic over ( \mathbb{Z}_{257} ).    |
| `toomcook.c`, `toomcook.h`                           | Toom-Cook / Karatsuba polynomial multiplication.     |
| `reduce.c`, `reduce.h`                               | Modular reduction routines.                          |
| `sampler.c`, `sampler.h`                             | Fixed-weight sampling routines.                      |
| `bch_codec.c`, `bch_codec.h`                         | BCH encoding/decoding support.                       |
| `verify.c`, `verify.h`                               | Constant-time verify and conditional move utilities. |
| `randombytes.c`, `randombytes.h`                     | Random byte generation interface.                    |
| `drng.c`, `drng.h`                                   | Deterministic random generator for KAT generation.   |
| `KAT_KEM.c`                                          | Known-answer test driver.                            |
| `KEM_AlgorithmInstance.c`, `KEM_AlgorithmInstance.h` | API_PKC-compatible KEM wrapper.                      |
| `Makefile`                                           | Build script for the instance.                       |

SHAKE-specific directories additionally contain:

| File                               | Description            |
| ---------------------------------- | ---------------------- |
| `fips202.c`, `fips202.h`           | SHA3/SHAKE primitives. |
| `symmetric-shake.c`, `symmetric.h` | SHAKE backend adapter. |

SM3-specific directories additionally contain:

| File                             | Description                        |
| -------------------------------- | ---------------------------------- |
| `sm3.c`, `sm3.h`                 | SM3 hash implementation.           |
| `sm3_xof.c`, `sm3_xof.h`         | SM3-based XOF construction.        |
| `symmetric-sm3.c`, `symmetric.h` | SM3 backend adapter.               |
| `auxfunc.c`, `auxfunc.h`         | API_PKC auxiliary hash/XOF bridge. |

Optimized implementations may also include a `simd/` directory containing AVX2 or NEON acceleration code.

## Build and Run

Each instance directory can be built independently.

The default build target is `kat_api`.

### Reference SHAKE

```bash
for L in 1 2 3 4; do
  pushd Implementations/Reference_Implementation/Lore-SHAKE/Lore-L${L}
  make clean
  make
  ./KAT_KEM_${L}
  popd
done
```

### Reference SM3

```bash
for L in 1 2 3 4; do
  pushd Implementations/Reference_Implementation/Lore-SM3/Lore-L${L}
  make clean
  make
  ./KAT_KEM_${L}
  popd
done
```

### AVX2 SHAKE

```bash
for L in 1 2 3 4; do
  pushd Implementations/Optimized_Implementation/AVX/Lore-SHAKE-AVX/Lore-L${L}
  make clean
  make
  ./KAT_KEM_${L}
  popd
done
```

### AVX2 SM3

```bash
for L in 1 2 3 4; do
  pushd Implementations/Optimized_Implementation/AVX/Lore-SM3-AVX/Lore-L${L}
  make clean
  make
  ./KAT_KEM_${L}
  popd
done
```

### NEON SHAKE

Run on an ARM64 platform:

```bash
for L in 1 2 3 4; do
  pushd Implementations/Optimized_Implementation/NEON/Lore-SHAKE-NEON/Lore-L${L}
  make clean
  make
  ./KAT_KEM_${L}
  popd
done
```

### NEON SM3

Run on an ARM64 platform:

```bash
for L in 1 2 3 4; do
  pushd Implementations/Optimized_Implementation/NEON/Lore-SM3-NEON/Lore-L${L}
  make clean
  make
  ./KAT_KEM_${L}
  popd
done
```

## Test Vectors

Known-answer test files are stored under:

```text
Test_Vectors/Lore-SHAKE/
Test_Vectors/Lore-SM3/
```

Each backend contains one KAT file per level:

```text
KAT_KEM_Lore-L1.txt
KAT_KEM_Lore-L2.txt
KAT_KEM_Lore-L3.txt
KAT_KEM_Lore-L4.txt
```

The generated output of each `KAT_KEM_N` executable should match the corresponding test vector file.

## Benchmark Scripts

Benchmark scripts are provided under `bench/`.

Example usage:

```bash
./bench/run_lore_measurements.sh shake cycles
./bench/run_lore_measurements.sh sm3 cycles
```

For a full 10000-trial benchmark:

```bash
LEVELS="L1 L2 L3 L4" TRIALS=10000 ITERS=10000 WARMUP=1000 CORE=0 \
  ./bench/run_lore_measurements.sh shake all

LEVELS="L1 L2 L3 L4" TRIALS=10000 ITERS=10000 WARMUP=1000 CORE=0 \
  ./bench/run_lore_measurements.sh sm3 all
```

## Code Review Fixes in This Release

This release includes the following high-priority fixes:

* `CRYPTO_ENCCOINBYTES` now uses `LORE_MSG_BYTES`.
* `LORE_NAMESPACE` prefixes are separated across reference, AVX, and NEON implementations.
* `L_SHIFT` is protected against the `n == 0` undefined-behavior case.
* Signed left shifts in `toomcook.c` have been removed and replaced with signed multiplication.
* SHAKE L1/L2 parameter headers have been synchronized with the complete L1–L4 parameter structure.

Validation status:

```text
x86_64 Reference SHAKE: L1-L4 passed
x86_64 Reference SM3:   L1-L4 passed
x86_64 AVX2 SHAKE:      L1-L4 passed
x86_64 AVX2 SM3:        L1-L4 passed
```

NEON source code is included and patched consistently, but runtime validation should be performed on an ARM64 platform.

## Notes

* Generated binaries, object files, temporary output files, and benchmark result files should not be committed.
* The SHAKE and SM3 backends are stored separately because they share the same high-level KEM API but use different hash/XOF backends.
* The `test` and `speed` Makefile targets may exist in instance directories, but the default `all` target builds the KAT driver to keep default builds minimal and reproducible.
