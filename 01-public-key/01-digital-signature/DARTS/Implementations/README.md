# DARTS Implementation

This project contains three different versions of the DARTS (lattice-based digital signature scheme) implementation: Reference Implementation, Optimized Implementation, and Additional Implementation. This project includes code derived from the HAETAE project, which is licensed under the MIT License. See Third Party License for details.

## Project Structure

```
Implementations/
├── Reference_Implementation/         # Reference implementation
│   ├── DARTS128/
│   ├── DARTS256/
│   └── DARTS512/
├── Optimized_Implementation/         # Optimized implementation
│   ├── DARTS_AVX2/                   # AVX2 optimized
│   │   ├── DARTS128/
│   │   ├── DARTS256/
│   │   └── DARTS512/
│   └── DARTS_neon/                   # NEON optimized
│       ├── DARTS128/
│       ├── DARTS256/
│       └── DARTS512/
├── Additional_Implementation/        # Additional implementation (FIPS 202 standard)
│    └── DARTS_FIPS202/
│       ├── Implementations/
│       │   ├── Optimized_Implementation/
│       │   │   ├── DARTS128/
│       │   │   ├── DARTS256/
│       │   │   └── DARTS512/
│       │   └── Reference_Implementation/
│       │       ├── DARTS128/
│       │       ├── DARTS256/
│       │       └── DARTS512/
│       ├── KAT/                      # Known Answer Tests
│       └── helper_scripts/           # Helper scripts and tools
│
└── Third Party License/
     └── license.txt
```
## File Description

### Core Source Files

| File | Description |
|------|-------------|
| `sign.c/h` | Main logic for signature generation and verification |
| `poly.c/h` | Polynomial operations (addition, subtraction, multiplication, etc.) |
| `polyvec.c/h` | Polynomial vector operations |
| `polymat.c/h` | Polynomial matrix operations |
| `ntt.c/h` | Number Theoretic Transform (NTT) implementation |
| `fft.c/h` | Fast Fourier Transform (FFT) implementation |
| `sampler.c/h` | Sampler - sampling from discrete Gaussian distribution |
| `encoding.c/h` | rANS encoding/decoding |
| `packing.c/h` | Data packing and unpacking |
| `symmetric.c/h` / `symmetric-shake.c` | Symmetric cryptographic primitives (SHA3/SHAKE) |
| `fixpoint.c/h` | Fixed-point arithmetic |
| `polyfix.c/h` | Fixed-point polynomial operations |
| `fips202.c/h` | FIPS 202 standard implementation (Additional Implementation only) |
| `fips202x4.c/h` | FIPS 202 AVX2 optimized version (Additional Implementation only) |
| `consts.c/h` | Constant definitions and precomputed values (Optimized and Additional Implementation only) |
| `randombytes.c/h` | Random number generation |
| `reduce.c/h` / `reduce_avx.h` | Modular reduction operations |
| `drng.c/h` | Deterministic Random Number Generator |
| `auxfunc.c/h` | Auxiliary functions |
| `align.h` | Memory alignment definitions (Optimized Implementation) |
| `f1600x4.S` | SHA3-1600 assembly optimization (Optimized and Additional Implementation) |

### Header Files

| File | Description |
|------|-------------|
| `config.h` | Compilation configuration options |
| `params.h` | Security parameter definitions (different parameters for DARTS128/256/512) |

### Testing and Verification

| File | Description |
|------|-------------|
| `KAT_SIG.c` / `PQCgenKAT_sign.c` | Known Answer Tests - KAT generation program |
| `test/test_DARTS.c` | DARTS signature correctness test |
| `test/test_mul.c` | Polynomial multiplication test |
| `test/test_speed.c` | Performance benchmark test |
| `test/test_Sign.c` | Signature verification test (Additional Implementation) |
| `test/cpucycles.c/h` | CPU cycle counting tool |
| `test/speed_print.c/h` | Performance output formatting tool |

### Data Files

| Directory | Description |
|-----------|-------------|
| `precomputations_rANS/` | rANS precomputed data |
| `precomputations_rANS/prec_encoding.c` | rANS encoding precomputation code |
| `precomputations_rANS/rANS_*.txt` | rANS probability distribution tables |

### Other Files

| File | Description |
|------|-------------|
| `rans_byte.h` | Byte-level rANS implementation |
| `SIG_AlgorithmInstance.c/h` | Algorithm instance wrapper |
| `Makefile` | Build file |
| `README.txt` | Version-specific notes |
| `Third Party License/license.txt` | MIT License (Team HAETAE, 2023-2024) |

## Compilation and Running

### Reference Implementation (Reference_Implementation)

The reference implementation provides a basic, easy-to-understand implementation.

```bash
cd Reference_Implementation/DARTS128
make              # Compile all executables to bin/ directory
make test         # Generate test programs
make KAT          # Generate KAT program
make clean        # Clean build artifacts
```

Compiled executables are located in the `bin/` directory:
- `bin/KAT_SIG` - Known Answer Tests program
- `bin/test_DARTS` - DARTS signature test
- `bin/test_mul` - Polynomial multiplication test
- `bin/test_speed` - Performance benchmark test

### Optimized Implementation (Optimized_Implementation)

The optimized implementation provides AVX2 and NEON optimized versions to improve performance.

```bash
# AVX2 version
cd Optimized_Implementation/DARTS_AVX2/DARTS128
make              # Compile all executables to bin/ directory
make test         # Generate test programs
make KAT          # Generate KAT program
make clean        # Clean build artifacts
```

```bash
# NEON version
cd Optimized_Implementation/DARTS_neon/DARTS128
make              # Compile all executables to bin/ directory
make test         # Generate test programs
make KAT          # Generate KAT program
make clean        # Clean build artifacts
```

Compiled executables are located in the `bin/` directory, same as the reference implementation.

### Additional Implementation (Additional_Implementation - FIPS 202)

The additional implementation is based on the FIPS 202 standard and includes both optimized and reference implementations.

```bash
# Optimized version (FIPS 202)
cd Additional_Implementation/DARTS_FIPS202/Implementations/Optimized_Implementation/DARTS128
make              # Compile all executables to bin/ directory
make test         # Generate all test programs
make speed        # Generate performance test only
make clean        # Clean build artifacts
```

Compiled executables are located in the `bin/` directory:
- `bin/PQCgenKAT_sign` - KAT generation program
- `bin/test_speed` - Performance benchmark test
- `bin/test_Sign` - Signature verification test
- `bin/test_mul` - Polynomial multiplication test

## Parameter

DARTS provides three security levels of implementation:

| Version | Security Level | Parameter File |
|---------|----------------|----------------|
| DARTS128 | 128 bits | `params.h` |
| DARTS256 | 256 bits | `params.h` |
| DARTS512 | 512 bits | `params.h` |

The parameter differences for each version are defined in `params.h`, including polynomial modulus, coefficient ranges, etc.

## Examples

### Running KAT Tests

```bash
cd Reference_Implementation/DARTS128
make KAT
./bin/KAT_SIG
```

### Running Performance Benchmarks

```bash
cd Reference_Implementation/DARTS128
make
./bin/test_speed
```

### Verifying Signature Correctness

```bash
cd Reference_Implementation/DARTS128
make test
./bin/test_DARTS
```
