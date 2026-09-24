# FHE/MPC Circuit Analysis for Polar-KEM

## Suitability for FHE/MPC

Polar-KEM has several features that make it suitable for Fully Homomorphic Encryption (FHE) and Multi-Party Computation (MPC) applications:

### Advantages

1. **Integer arithmetic:** All core operations use integer arithmetic (no floating-point)
2. **Simple decoder:** SC decoder consists of min() and addition operations
3. **Regular structure:** Polar codes have highly regular recursive structure
4. **Small error space:** Error coordinates in {-1, 0, 1} are FHE-friendly

### Circuit Depth

| Operation | Circuit Depth | Complexity |
|-----------|--------------|------------|
| Polar SC decoder | O(log N) per level, O(L log N) total | O(L N log N) gates |
| Norm check | O(log N) | O(N) gates |
| CCA comparison | O(log |ct|) | O(|ct|) gates |
| KDF (SHAKE256) | O(log rounds) | Fixed cost |

Total decapsulation depth: **O(L log N) = O(log^2 N)**

For N=512: depth ~ O(81), for N=1024: depth ~ O(100), for N=2048: depth ~ O(121)

## MPC Implementation

### KeyGen in MPC
- Polynomial coefficients can be sampled jointly
- Gram matrix computation is local after secret sharing
- Lattice basis completion requires secure inversion

### Encaps in MPC
- Error sampling: coin tossing protocol
- Ciphertext computation: local after shared error

### Decaps in MPC
- SC decoder: each min() and addition done via MPC protocol
- Total communication: O(L * N * log N) field elements per party

## FHE Implementation

### Bootstrapping Considerations
- Small error space {-1, 0, 1} reduces noise growth
- SC decoder operations (min, add) are FHE-friendly
- Total multiplicative depth manageable for TFHE/CKKS

### Estimated Performance
| Operation | FHE-encrypted latency (estimated) |
|-----------|----------------------------------|
| Decaps (N=512) | ~10-100 seconds (TFHE) |
| Decaps (N=1024) | ~30-300 seconds (TFHE) |
| Decaps (N=2048) | ~100-1000 seconds (TFHE) |

**Note:** These are rough estimates. Actual performance depends on the FHE scheme and parameters.

## Recommendations

1. [RECOMMENDED] Implement SC decoder using only addition and comparison operations
2. [RECOMMENDED] Use look-up tables for min() in FHE context
3. [RECOMMENDED] Consider smaller N for FHE-optimized variant (e.g., N=256)
4. [RECOMMENDED] Explore batched FHE evaluation for throughput
