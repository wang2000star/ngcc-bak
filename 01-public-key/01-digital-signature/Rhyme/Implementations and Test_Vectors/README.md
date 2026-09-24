# Rhyme Signature Implementations

This repository contains implementations of Rhyme, a Fiat-Shamir lattice-based
digital signature algorithm with a compressed unimodular ("cut-F") construction.

This release contains two hash backends:

* `Rhyme-SHAKE`: SHAKE-128 / SHAKE-256 (FIPS 202) based implementation.
* `Rhyme-SM3`: SM3 / SM3-KDF (pseudoXOF) based implementation.

It also contains two implementation families:

* Reference portable C implementation.
* x86-64 optimized implementation.

The supported security levels are:

| Level | Classical Security | N    | Q     | K | L |
| ----- | -----------------: | ---: | ----: | -:| -:|
| 128   |            128-bit |  256 |  3329 | 2 | 3 |
| 256   |            256-bit |  512 |  9473 | 2 | 3 |
| 384   |            384-bit |  512 | 11777 | 3 | 4 |
| 512   |            512-bit | 1024 | 18433 | 2 | 3 |

## Directory Structure

```text
.
├── Implementations/
│   ├── Reference_Implementation/
│   │   ├── Rhyme-SHAKE/
│   │   │   ├── Rhyme-SHAKE-128/
│   │   │   ├── Rhyme-SHAKE-256/
│   │   │   ├── Rhyme-SHAKE-384/
│   │   │   └── Rhyme-SHAKE-512/
│   │   └── Rhyme-SM3/
│   │       ├── Rhyme-SM3-128/
│   │       ├── Rhyme-SM3-256/
│   │       ├── Rhyme-SM3-384/
│   │       └── Rhyme-SM3-512/
│   ├── Optimized_Implementation/
│   │   ├── Rhyme-SHAKE/
│   │   │   ├── Rhyme-SHAKE-128/
│   │   │   ├── Rhyme-SHAKE-256/
│   │   │   ├── Rhyme-SHAKE-384/
│   │   │   └── Rhyme-SHAKE-512/
│   │   └── Rhyme-SM3/
│   │       ├── Rhyme-SM3-128/
│   │       ├── Rhyme-SM3-256/
│   │       ├── Rhyme-SM3-384/
│   │       └── Rhyme-SM3-512/
│   └── Additional_Implementation/
├── Test_Vectors/
│   ├── Rhyme-SHAKE/
│   │   ├── KAT_SIG_Rhyme-SHAKE-128.txt
│   │   ├── KAT_SIG_Rhyme-SHAKE-256.txt
│   │   ├── KAT_SIG_Rhyme-SHAKE-384.txt
│   │   └── KAT_SIG_Rhyme-SHAKE-512.txt
│   └── Rhyme-SM3/
│       ├── KAT_SIG_Rhyme-SM3-128.txt
│       ├── KAT_SIG_Rhyme-SM3-256.txt
│       ├── KAT_SIG_Rhyme-SM3-384.txt
│       └── KAT_SIG_Rhyme-SM3-512.txt
└── README.md
```

## File Overview

Each `Rhyme-*-*` instance directory contains the source files for one algorithm instance.

| File                                                 | Description                                          |
| ---------------------------------------------------- | ---------------------------------------------------- |
| `api.h`                                              | Public API constants and byte lengths.               |
| `SIG_AlgorithmInstance.c`, `SIG_AlgorithmInstance.h` | API_PKC-compatible SIG wrapper.                      |
| `KAT_SIG.c`                                          | Known-answer test driver.                            |
| `drng.c`, `drng.h`                                   | Deterministic random generator for KAT generation.   |
| `auxfunc.c`, `auxfunc.h`                             | API_PKC auxiliary functions (byte-identical to template no-modify). |
| `rhyme_xof.c`, `rhyme_xof.h`                         | Rhyme-specific Hash/XOF wrapper layer.               |
| `sign.c`, `sign.h`                                   | Key generation, signing, and verification.           |
| `poly.c`, `poly.h`                                   | Polynomial arithmetic over R_q.                      |
| `ntt.c`, `ntt_tables.c`, `ntt.h`                     | NTT and precomputed twiddle-factor tables.           |
| `zpntt.c`, `zpntt.h`                                 | Auxiliary-prime NTT for exact integer products.      |
| `sampler.c`, `sampler.h`                             | CBD, discrete Gaussian (CDT), challenge, and rejection samplers. |
| `encoding.c`, `encoding.h`                           | rANS entropy coding for signature compression.       |
| `packing.c`, `packing.h`                             | Key and signature serialization.                     |
| `randombytes.c`, `randombytes.h`                     | Random byte generation interface.                    |
| `Makefile`                                           | Build script for the instance.                       |
| `src/keygen/`                                        | Key-generation driver and unimodular-basis solver.   |

SHAKE-specific directories additionally contain:

| File                               | Description            |
| ---------------------------------- | ---------------------- |
| `fips202.c`, `fips202.h`           | SHAKE-128/256 and SHA3 primitives. |
| `symmetric-shake.c`, `symmetric.h` | SHAKE backend adapter. |

SM3-specific directories additionally contain:

| File                             | Description                        |
| -------------------------------- | ---------------------------------- |
| `sm3.c`, `sm3.h`                 | SM3 hash wrappers over API_PKC auxfunc. |
| `sm3_xof.c`, `sm3_xof.h`         | SM3-based XOF state machine (incremental KDF-SM3). |
| `symmetric-shake.c`, `symmetric.h` | SM3 backend adapter.             |

SM3 AVX2 Optimized additionally contains:

| File                               | Description                        |
| ---------------------------------- | ---------------------------------- |
| `simd/sm3_avx2.c`, `simd/sm3_avx2.h` | AVX2-optimized SM3 compression (batch-8 + single-hash). |

Optimized implementations:

* **Rhyme-SHAKE Optimized:** DP1 fast keygen (`-DUSE_DP1_CHECK`) — truncated-minor
  coprimality check for ~2–16x keygen speedup. KAT output differs from Reference
  (different valid secret basis); all signatures self-verify correctly.
* **Rhyme-SM3 Optimized:** AVX2 SM3 compression (`simd/sm3_avx2.c`) adapted from
  Lore-SM3-AVX. KAT byte-identical to Reference.

## Build and Run

Each instance directory can be built independently.

The default build target is `KAT_SIG`.

### Reference SHAKE

```bash
for L in 128 256 384 512; do
  pushd Implementations/Reference_Implementation/Rhyme-SHAKE/Rhyme-SHAKE-${L}
  make clean && make && ./KAT_SIG
  popd
done
```

### Reference SM3

```bash
for L in 128 256 384 512; do
  pushd Implementations/Reference_Implementation/Rhyme-SM3/Rhyme-SM3-${L}
  make clean && make && ./KAT_SIG
  popd
done
```

### Optimized SHAKE (DP1)

```bash
for L in 128 256 384 512; do
  pushd Implementations/Optimized_Implementation/Rhyme-SHAKE/Rhyme-SHAKE-${L}
  make clean && make && ./KAT_SIG
  popd
done
```

### Optimized SM3 (AVX2)

```bash
for L in 128 256 384 512; do
  pushd Implementations/Optimized_Implementation/Rhyme-SM3/Rhyme-SM3-${L}
  make clean && make && ./KAT_SIG
  popd
done
```

## Test Vectors

Known-answer test files are stored under:

```text
Test_Vectors/Rhyme-SHAKE/
Test_Vectors/Rhyme-SM3/
```

Each backend contains one KAT file per level. The generated output of each
`KAT_SIG` executable should match the corresponding test vector file:

- Reference SHAKE: byte-identical
- Reference SM3: byte-identical
- Optimized SHAKE (DP1): KAT differs (different valid secret basis); validated by self-verification
- Optimized SM3 (AVX2): byte-identical

## Notes

* Generated binaries, object files, and temporary output files should not be committed.
* The SHAKE and SM3 backends share the same high-level SIG API and core algorithm
  logic, differing only in the hash/XOF backend.
* API_PKC `no modify/` files (`auxfunc.c/h`, `drng.c/h`, `KAT_SIG.c`) are
  byte-identical to the template originals in all instances.
* This package contains signature functionality only. No KEM or KEX implementation
  is included.
