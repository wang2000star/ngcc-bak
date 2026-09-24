# Side-Channel Considerations for Polar-KEM

## Constant-Time Requirements

All operations that depend on secret data MUST be constant-time:

### KeyGen
- Unimodular matrix sampling: constant-time
- Gram matrix computation: constant-time
- Secret key encoding: constant-time

### Encaps
- Error vector sampling: rejection-free, constant-time
- Extractor computation: constant-time

### Decaps (Critical)
- Polar SC decoder: MUST run in constant time
  - Always process all N positions
  - No early termination based on LLR values
  - No branching on decoded bits
- Error norm check: constant-time comparison
- CCA re-encryption check: constant-time comparison
- Failure path selection: constant-time (CT_select)
- KDF computation: constant-time

## Secret-Dependent Operations

| Operation | Secret Data | Constant-Time? |
|-----------|-------------|----------------|
| Polar SC decoder | sk (frozen sets) | Yes |
| Error recovery | sk (U matrix) | Yes |
| Norm verification | e (recovered error) | Yes |
| CCA check | ct comparison | Yes |
| Failure handling | z (secret seed) | Yes |

## Implementation Guidelines

### CT_select (Conditional Selection)
```c
uint32_t ct_select(uint32_t a, uint32_t b, uint32_t mask) {
    return (a & mask) | (b & ~mask);  // mask = all 1s or all 0s
}
```

### CT_equal (Constant-Time Compare)
```c
uint32_t ct_equal(const uint8_t *a, const uint8_t *b, size_t len) {
    uint32_t r = 0;
    for (size_t i = 0; i < len; i++) r |= a[i] ^ b[i];
    return (1 & ((r - 1) >> 8)) - 1;  // 0 if equal, 0xFF if different
}
```

### CT_leq (Constant-Time Less-Than-Or-Equal)
```c
uint32_t ct_leq(uint32_t a, uint32_t b) {
    return (uint32_t)(((int64_t)a - (int64_t)b - 1) >> 63) - 1;
}
```

## Timing Attack Mitigations

1. **Decoder timing:** SC decoder always runs for exactly N*log(N) LLR operations
2. **Memory access:** No secret-dependent memory access patterns
3. **Branch elimination:** All conditional logic replaced with CT_select

## Power Analysis Considerations

- **Bounded uniform sampling:** No Gaussian sampling needed (avoids complex samplers)
- **Fixed-point arithmetic:** All decoder operations use integer LLRs
- **No lookup tables:** Secret data not used as table indices

## Hardware Countermeasures

For high-security deployments:
- Masking of critical operations
- Shuffling of decoder iterations
- Dummy operations to balance power consumption

## Validation

[RECOMMENDED] Implementors should:
1. Verify constant-time properties using dudect or similar tools
2. Perform power analysis on physical implementations
3. Test with fixed vs random inputs to detect timing differences
