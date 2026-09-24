# Polar-KEM: Post-Quantum Key Encapsulation Mechanism

## Overview

**Polar-KEM** is a Lattice Isomorphism Problem (LIP)-inspired post-quantum Key Encapsulation Mechanism that replaces the Barnes-Wall lattice (from nested Reed-Muller codes in the baseline LIP-KEM framework) with polar-code-defined lattices via Construction D.

This is a **KEM** (Key Encapsulation Mechanism), not a digital signature scheme.

## Algorithm Instances

| Instance | Classical Security | Quantum Security | Dimension N | Modulus q | Shared Secret |
|----------|-------------------|------------------|-------------|-----------|---------------|
| PolarKEM-128 | ~150 bits | ~134 bits | 512 | 12289 | 128 bits |
| PolarKEM-256 | ~296 bits | ~269 bits | 1024 | 12289 | 256 bits |
| PolarKEM-512 | ~618 bits | ~561 bits | 2048 | 18433 | 512 bits |

## Directory Structure

```
Submission_Package/
  Algorithm_Text/
    polarkem-spec.tex       - LaTeX algorithm specification
    references.bib          - BibTeX references
  Implementations/
    Reference_Implementation/
      PolarKEM-128/         - C99 reference code
      PolarKEM-256/
      PolarKEM-512/
    Optimized_Implementation/
      PolarKEM-128/         - x86_64 optimized code
      PolarKEM-256/
      PolarKEM-512/
    Additional_Implementation/
      README
  Test_Vectors/
    KAT_KEM_PolarKEM-128.txt
    KAT_KEM_PolarKEM-256.txt
    KAT_KEM_PolarKEM-512.txt
  Security_Analysis/
    design_space.md         - Design exploration document
    attacks.md              - Attack analysis
    bkz_estimates.md        - BKZ security estimates
    decoding_failure.md     - Decoding failure analysis
    side_channel.md         - Side-channel considerations
    fhe_mpc_circuit.md      - FHE/MPC circuit analysis
    rejected_designs.md     - Rejected design alternatives
```

## Core Design

### Polar Lattice Construction
The scheme uses Construction D applied to a nested family of polar codes:

```
L_Polar = C_0 + 2*C_1 + 4*C_2 + ... + 2^{L-1}*C_{L-1} + 2^L * Z^N
```

where `C_i = P(N, K_i)` are nested polar codes with frozen sets `F_0 <= F_1 <= ... <= F_L`.

### Core Algorithms
- **KeyGen**: Sample secret unimodular U, compute public quadratic form `Q_pub = U^T * Q_0 * U`
- **Encaps**: Sample bounded uniform error e, produce ciphertext, derive shared secret via extractor
- **Decaps**: Use secret decoder to recover e, verify via CCA re-encryption check, derive ss

### CCA Security
Fujisaki-Okamoto transform with **implicit rejection**:
- Invalid ciphertexts produce a pseudorandom shared secret derived from a secret seed
- No information leaks about decapsulation failure
- All operations are constant-time

### Decoder
Successive Cancellation (SC) decoder for polar codes:
- Complexity: O(L * N log N)
- Fully constant-time implementation
- No floating-point arithmetic

## Security Assumptions

1. **polar-LIP**: Finding the secret isomorphism U from Q_pub is hard
2. **Hidden-Isomorphism Decoding (HID)**: Decoding without U is hard

Security estimates based on BKZ lattice reduction with Core-SVP model.

## Implementation Notes

### Reference Implementation
- ISO C99, no platform-specific code
- Constant-time secret-dependent operations
- Replaceable hash/XOF API (default: SHAKE256)
- Build: `make test_kem` (run tests), `make kat_gen` (generate KATs), `make benchmark`

### Optimized Implementation
- Targets x86_64 with AVX2
- Same API as reference implementation
- Compile with: `make CFLAGS='-O3 -mavx2 -mbmi2'`

## Test Vectors

Known Answer Test vectors are provided in NIST KAT format:
- `KAT_KEM_PolarKEM-128.txt` - 10 test vectors
- `KAT_KEM_PolarKEM-256.txt` - 10 test vectors
- `KAT_KEM_PolarKEM-512.txt` - 10 test vectors

Vectors include normal cases, boundary cases, and malformed ciphertext tests.

## Compilation

### Requirements
- C compiler with C99 support (gcc, clang)
- GNU Make
- (Optional) LaTeX distribution for PDF compilation

### Build Reference Implementation
```bash
cd Implementations/Reference_Implementation/PolarKEM-128
make test_kem   # Build and run tests
make kat_gen    # Build KAT generator
make benchmark  # Build benchmark tool
```

### Build LaTeX Specification
```bash
cd Algorithm_Text
pdflatex polarkem-spec.tex   # Run twice for TOC
```

## Features

- **Innovation**: First KEM using polar-code-defined lattices
- **Decodable**: Efficient SC decoder with O(N log N) complexity
- **Constant-time**: All secret operations are isochronous
- **CCA-secure**: FO transform with implicit rejection
- **Modular**: Replaceable hash/XOF components
- **Flexible**: Parameter sets for 3 security levels

## Known Limitations

- Public key sizes (186-3117 KB compressed) are larger than LWE-based KEMs
- Security estimates contain heuristic and conjectural components
- Polar lattice smoothing bounds are not rigorously proven
- No hardware implementation yet

## Intellectual Property

This is a research proposal. No patents are known to cover this specific design.

## Version

- Version: 1.0
- Date: 2026-04-30
