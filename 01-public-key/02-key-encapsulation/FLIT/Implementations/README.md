# FLIT — NGCC630

This directory summarizes multiple implementation versions of FLIT (Reference Implementation, Optimized Implementation, Additional Implementation) and KAT test vectors.

## 1. Directory Structure

```text
Implementation/
├── README.md
├── Additional_Implementation/
│   ├── FLIT_FIPS202_REF128/
│   ├── FLIT_FIPS202_REF256/
│   ├── FLIT_FIPS202_OPT128/
│   └── FLIT_FIPS202_OPT256/
├── Optimized_Implementation/
│   ├── FLIT128/
│   ├── FLIT256/
│   └── FLIT512/
└── Reference_Implementation/
    ├── FLIT128/
    ├── FLIT256/
    └── FLIT512/
```

## 2. File Descriptions for Each Implementation Directory

- **Reference_Implementation** (`REF`) — reference implementation, available for FLIT128, FLIT256, and FLIT512.
- **Optimized_Implementation** (`OPT`) — AVX2-optimized implementation, available for FLIT128, FLIT256, and FLIT512.
- **Additional_Implementation** (`FIPS202`) — FIPS202 (SHAKE)-based implementation, available at 128-bit and 256-bit security strength: `FLIT_FIPS202_REF128`, `FLIT_FIPS202_REF256`, `FLIT_FIPS202_OPT128`, `FLIT_FIPS202_OPT256`.

The file descriptions in sections 2.1–2.3 and 2.6–2.7 apply to all parameter sets (FLIT128, FLIT256, FLIT512) under both Reference_Implementation and Optimized_Implementation, unless otherwise noted.

### 2.1 Build and Entry Files

| File | Description |
|------|-------------|
| `Makefile` | Build script providing `all`, `test`, `speed`, and `clean` targets |
| `KAT_KEM.c` | KAT vector generation/verification program entry point |
| `KEM_AlgorithmInstance.c` | Algorithm instance interface implementation (KEM interface layer) |
| `KEM_AlgorithmInstance.h` | Algorithm instance interface and macro configuration |
| `config.h` | Compilation configuration macros; selects parameter set via `KEM_MODE` (128/256/512) |
| `params.h` | Parameter set configuration (modulus Q, dimension N, byte lengths, etc.) |

### 2.2 KEM Core Modules

| File | Description |
|------|-------------|
| `kem.c` / `kem.h` | KEM upper-level interface (KeyGen / Encaps / Decaps) |
| `indcpa.c` / `indcpa.h` | IND-CPA basic public-key encryption core process |
| `poly.c` / `poly.h` | Polynomial objects and operations (addition, subtraction, sampling, transformation helpers) |
| `ntt.c` / `ntt.h` | NTT / inverse NTT transformation logic |
| `reduce.c` / `reduce.h` | Modular reduction operations |
| `decode.c` / `decode.h` | Encoding/decoding and bit-level conversions |
| `packing.c` / `packing.h` | Packing/unpacking of public keys, ciphertexts, and polynomials to/from byte streams |
| `verify.c` / `verify.h` | Constant-time comparison, conditional copy, and other verification helpers |

### 2.3 Symmetric Primitives and Random Number Generation

| File | Description |
|------|-------------|
| `symmetric.h` | Hash/XOF symmetric interface declarations |
| `drng.c` / `drng.h` | Deterministic random number generator (for KAT test vector scenarios) |
| `auxfunc.c` / `auxfunc.h` | Auxiliary function collection (utility/compatibility functions) |

### 2.4 Optimized Implementation Files (Optimized_Implementation only)

| File | Description |
|------|-------------|
| `ntt_avx.c` / `ntt_avx.h` | AVX2-accelerated NTT / inverse NTT implementation |
| `basemul_avx.c` / `basemul_avx.h` | AVX2-accelerated base multiplication implementation |
| `consts.c` / `consts.h` | Pre-computed constant tables |
| `keccak4x/` | Keccak 4-way parallel implementation (SIMD256) |

### 2.5 Additional Implementation Files (Additional_Implementation only)

The Additional Implementation uses FIPS202 (SHAKE) as the symmetric primitive, as opposed to the internal hash used by the main implementations.

| File | Description |
|------|-------------|
| `fips202.c` / `fips202.h` | FIPS202 (SHA3/SHAKE) single-lane implementation |
| `fips202x4.c` / `fips202x4.h` | FIPS202 4-way parallel implementation (OPT128/OPT256 only) |
| `symmetric-shake.c` | SHAKE-based symmetric primitive wrapper |
| `rng.c` / `rng.h` | SHAKE-based random number generator |

### 2.6 Test Directory (test/)

| File | Description |
|------|-------------|
| `test_mul.c` | Polynomial / multiplication tests |
| `test_cpapke.c` | IND-CPA PKE functionality tests |
| `test_kem.c` | KEM functional correctness tests |
| `test_speed.c` | Speed benchmark entry point |
| `cpucycles.c` / `cpucycles.h` | Cycle counting utilities |
| `speed_print.c` / `speed_print.h` | Speed statistics output formatting |

### 2.7 Parameter Set Reference

| Parameter Set | N | Q | Q_BITS | D | PF | PG | PR | PE | SEEDBYTES |
|---------------|---|---|--------|---|-----|-----|-----|-----|-----------|
| 128 | 512 | 769 | 10 | 8 | 125 | 3125 | 125 | 3125 | 32 |
| 256 | 1024 | 769 | 10 | 8 | 15625 | 25 | 15625 | 25 | 32 |
| 512 | 2048 | 3329 | 12 | 9 | 4375 | 4375 | 4375 | 4375 | 64 |

## 3. Compilation and Execution

The following commands are tested in a Linux environment with gcc as the default compiler.

### 3.1 Enter Target Directory

Example: enter the optimized implementation of FLIT256.

```bash
cd Optimized_Implementation/FLIT256
```

For reference implementation:

```bash
cd Reference_Implementation/FLIT256
```

For additional (FIPS202) implementation:

```bash
cd Additional_Implementation/FLIT_FIPS202_REF128
```

### 3.2 Compile Main Program (KAT_KEM)

```bash
make
# or
make all
```

Execute:

```bash
./KAT_KEM
```

Output files will be saved in the `output/` directory.

### 3.3 Run Speed Benchmarks

```bash
make speed
# or
./test/test_speed
```

### 3.4 Clean Build Artifacts

```bash
make clean
```

## 4. KAT Test Vectors

The `Test_Vectors/` directory (located alongside `Implementation/`, not inside it) contains Known Answer Test vectors for each parameter set and implementation. Each file contains 10 groups (Count 0–9), each with:

- `Seed` — deterministic random seed
- `PK` / `SK` — public key / secret key
- `CT` — ciphertext
- `SS` — shared secret

Reference and optimized implementations should produce identical output given the same seed.

## 5. Usage Recommendations

- If your machine does not support AVX2 instructions, use `Reference_Implementation` for compilation and execution.
- When performing cross-parameter-set comparisons, run `make clean && make test` independently in each directory.
- For batch speed benchmarking, invoke `make speed` and `test/test_speed` sequentially from scripts in the repository root.
- The Additional Implementation (FIPS202) uses standard FIPS202 interfaces and is suitable for scenarios requiring standard SHAKE.
- The FLIT512 parameter set (N=2048, Q=3329) takes significantly longer to compile and run; please be patient.