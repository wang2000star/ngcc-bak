# Attack Analysis for Polar-KEM

## 1. Direct Key Recovery (LIP Attack)

**Attack:** Given Q_pub = U^T * Q_0 * U, recover secret unimodular U.

**Method:** BKZ lattice reduction on the Gram matrix Q_pub.

**Complexity Estimates:**

| Instance | BKZ Blocksize | Classical Cost | Quantum Cost |
|----------|--------------|----------------|--------------|
| PolarKEM-128 | ~507 | 2^150 | 2^134 |
| PolarKEM-256 | ~1014 | 2^296 | 2^269 |
| PolarKEM-512 | ~2116 | 2^618 | 2^561 |

**Confidence:** [HEURISTIC] Based on Core-SVP model calibrated against known lattice attacks.

## 2. BDD Attack (Ciphertext Decryption)

**Attack:** Given ciphertext c and Q_pub, recover error e without secret key.

**Method:** Reduce BDD to uSVP via Kannan embedding, then BKZ.

**Complexity Estimates:**

| Instance | BKZ Blocksize | Classical Cost | Quantum Cost |
|----------|--------------|----------------|--------------|
| PolarKEM-128 | ~430 | 2^126 | 2^114 |
| PolarKEM-256 | ~861 | 2^251 | 2^228 |
| PolarKEM-512 | ~1799 | 2^525 | 2^477 |

**Note:** BDD is easier than LIP, which is consistent with the security hierarchy.

## 3. Structural Attacks on Polar Lattices

### 3.1 Polar Structure Detection
**Question:** Can an attacker detect that Q_pub comes from a polar lattice (rather than random)?

**Analysis:**
- The public key shows Q_pub = U^T * Q_polar * U for secret U
- Without knowing U, Q_pub appears as a random positive-definite quadratic form
- [CONJECTURAL] The unimodular transformation effectively hides the polar structure

**Countermeasures:**
- Random interleaving of coordinates
- Hidden permutation of lattice basis

### 3.2 Frozen-Set Pattern Leakage
**Risk:** If frozen set pattern is known, attacker can exploit polar code structure.

**Mitigation:** Frozen sets are secret (part of sk). Different key pairs use different frozen sets.

### 3.3 Construction D Level Leakage
**Risk:** Multi-level structure might be detectable.

**Analysis:** [HEURISTIC] The hidden isomorphism U destroys the visible level structure.

## 4. Multi-Key Attacks

Attacking k keys simultaneously provides at most sqrt(k) speedup.

| k | Speedup | PolarKEM-128 Cost | PolarKEM-256 Cost |
|---|---------|-------------------|-------------------|
| 2 | 1.4x | 2^149 | 2^295 |
| 4 | 2.0x | 2^149 | 2^295 |
| 16 | 4.0x | 2^148 | 2^294 |

## 5. Invalid Ciphertext Attacks (CCA)

**Attack:** Submit malformed ciphertexts to decapsulation oracle.

**Defense:**
- FO transform with re-encryption verification
- Implicit rejection (no failure indication)
- Constant-time decapsulation

## 6. Side-Channel Attacks

### Timing Attacks
- **Risk:** Decoder timing depends on error pattern
- **Mitigation:** Constant-time SC decoder (always processes all N positions)

### Power Analysis
- **Risk:** Gaussian sampling might leak information
- **Mitigation:** Bounded uniform sampling (no Gaussian needed in encaps)

## 7. Quantum Attacks

| Algorithm | Speedup | Effective Against |
|-----------|---------|-------------------|
| Grover | sqrt(N) | Search (limited use) |
| Quantum BKZ | polynomial | Lattice reduction (0.265 vs 0.292) |
| Quantum sieving | sub-exponential | SVP solving |

Quantum security uses Core-SVP with 0.265 exponent instead of 0.292.
