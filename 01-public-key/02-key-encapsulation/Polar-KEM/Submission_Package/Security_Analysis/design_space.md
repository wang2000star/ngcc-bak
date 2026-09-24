# Polar-KEM Master Design Document

## 1. Overview

Polar-KEM is a Lattice Isomorphism Problem (LIP)-inspired post-quantum Key Encapsulation Mechanism that replaces the Barnes-Wall lattice (from nested Reed-Muller codes in the baseline LIP-KEM framework) with polar-code-defined lattices via Construction D.

## 2. Final Parameter Sets

| Parameter | PolarKEM-128 | PolarKEM-256 | PolarKEM-512 |
|-----------|-------------|-------------|-------------|
| Security target | 128 bits (cl) / 80 bits (qu) | 256 bits (cl) / 128 bits (qu) | 512 bits (cl) / 256 bits (qu) |
| Dimension N | 512 | 1024 | 2048 |
| Polar depth n | 9 | 10 | 11 |
| Levels L | 5 | 5 | 6 |
| Base rate R_0 | 1/2 | 1/2 | 1/2 |
| Modulus q | 12289 | 12289 | 18433 |
| Error bound B | 1 | 1 | 1 |
| Decoding radius rho | 15.0 | 31.0 | 63.0 |
| Shared secret | 128 bits | 256 bits | 512 bits |
| Ciphertext size | ~N*log2(q) bits | ~N*log2(q) bits | ~N*log2(q) bits |
| Public key size (compressed) | ~186 KB | ~742 KB | ~3117 KB |
| DFP target | <= 2^{-128} | <= 2^{-256} | <= 2^{-512} |

## 3. Polar Lattice Construction

Construction D from nested polar codes:
- L_Polar = C_0 + 2*C_1 + 4*C_2 + ... + 2^{L-1}*C_{L-1} + 2^L * Z^N
- C_i = P(N, K_i) with frozen sets F_0 <= F_1 <= ... <= F_L
- Rate progression: R_i = 2^{-i} for i = 0, ..., L-1
- Frozen sets chosen by polar code design (GA method)

## 4. Core Algorithms (IND-CPA)

### KeyGen:
1. Generate base polar lattice L_0 with Gram matrix Q_0
2. Sample secret unimodular U in GL(N, Z) with bounded entries
3. Compute Q_pub = U^T * Q_0 * U
4. sk = (U, decoder_state, frozen_sets)
5. pk = Q_pub (compressed)

### Encaps:
1. Sample error e uniformly from {-1, 0, 1}^N (bounded uniform)
2. Compute c = q * e mod q (ciphertext component)
3. Derive seed rho from randomness
4. Compute A from rho (uniform matrix)
5. Compute k = (det Q_pub)^{-1} * (A * Q_pub * e') mod q
6. ss = KDF(k || c || rho)
7. ct = (c, rho)

### Decaps:
1. Parse ct = (c, rho)
2. Compute y = U * c
3. y_decoded = PolarSCDecode(y, decoder_state)
4. e_recovered = U^{-1} * (y - y_decoded)
5. Verify ||e_recovered|| <= rho in constant-time
6. Recompute k and ss if valid
7. If invalid, return pseudorandom ss from secret z (implicit rejection)

## 5. CCA Transform (FO with Implicit Rejection)

- Re-encryption check: recompute c' from recovered e, compare with c
- Constant-time select: use CT_select for all conditional operations
- Fallback: derive ss from secret seed z when ciphertext invalid
- No information leaked about which branch taken

## 6. Decoder

Successive Cancellation (SC) decoder:
- Input: LLR vector, frozen set F
- Output: decoded codeword
- Complexity: O(N log N) per level
- Total: O(L * N log N)
- Fully constant-time implementation

## 7. Error Distribution

Bounded uniform over {-1, 0, 1}^N:
- Sampling: 2 random bits per coordinate
- Support: each coordinate in {-1, 0, +1}
- Expected squared norm: N/3
- Max squared norm: N
- Min-entropy: high (> N bits)

## 8. Extractor and KDF

Two-stage extraction:
1. Extractor: Universal hash family H_{m,N,q,B} = {f_A(x) = A*x mod q}
2. KDF: SHAKE-256(k || ct || pk_hash, |ss|)

## 9. Security Estimates

| Attack | PolarKEM-128 | PolarKEM-256 | PolarKEM-512 |
|--------|-------------|-------------|-------------|
| BKZ blocksize (LIP) | ~507 | ~1014 | ~2116 |
| BKZ blocksize (BDD) | ~430 | ~861 | ~1799 |
| Classical security | ~150 bits | ~296 bits | ~618 bits |
| Quantum security | ~134 bits | ~269 bits | ~561 bits |
| Decoding failure | < 2^{-128} | < 2^{-256} | < 2^{-512} |

## 10. Implementation Requirements

- Reference: C99, no platform-specific code
- Optimized: x86_64 with AVX2
- Constant-time: all secret-dependent operations
- Replaceable hash/XOF API
- KAT generation built-in
- Benchmark tools included
