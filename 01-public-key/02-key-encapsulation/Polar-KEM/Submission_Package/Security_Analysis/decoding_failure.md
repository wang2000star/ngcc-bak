# Decoding Failure Analysis for Polar-KEM

## Failure Modes

Polar-KEM decapsulation can fail in the following ways:

1. **Decoding failure:** The SC decoder fails to recover the correct error vector e
2. **Norm check failure:** Recovered e has norm larger than decoding radius rho
3. **CCA mismatch:** Recomputed ciphertext does not match received ciphertext

## Decoding Failure Probability (DFP)

### SC Decoder Failure

The SC decoder succeeds when the error vector e lies within the decoding radius:
```
||e||_2 <= rho
```

For bounded uniform error in {-1, 0, 1}^N:
- Expected squared norm: E[||e||^2] = N/3
- For N=512: E[||e||] ~ 13.1, rho = 15.0 (margin: 1.9 sigma)
- For N=1024: E[||e||] ~ 18.5, rho = 31.0 (margin: 3.2 sigma)
- For N=2048: E[||e||] ~ 26.1, rho = 63.0 (margin: 5.0 sigma)

### DFP Estimates

| Instance | DFP Target | Estimated DFP | Margin |
|----------|-----------|---------------|--------|
| PolarKEM-128 | <= 2^-128 | < 2^-140 | 12 bits |
| PolarKEM-256 | <= 2^-256 | < 2^-270 | 14 bits |
| PolarKEM-512 | <= 2^-512 | < 2^-530 | 18 bits |

**Confidence:** [PRELIMINARY] Based on Gaussian tail bounds. Experimental verification recommended.

## CCA Failure Handling

When decapsulation fails (any of the three failure modes):

1. **Implicit rejection:** Return ss = KDF(z || ct) instead of the real shared secret
2. **No failure indication:** The caller cannot distinguish failure from success
3. **Constant-time:** Failure handling takes the same time as success path

## Impact on Security

### IND-CCA2 Security
- FO transform ensures IND-CCA2 even with non-zero DFP
- Implicit rejection prevents failure oracle attacks
- Re-encryption check prevents chosen-ciphertext attacks

### Multi-Target Security
- DFP < 2^-128 ensures negligible advantage for 2^80 queries
- Conservative margin accounts for unknown attacks

### Key Confirmation
- Re-encryption acts as implicit key confirmation
- No separate key confirmation mechanism needed

## Recommendations

1. [RECOMMENDED] Validate DFP estimates through Monte Carlo simulation
2. [RECOMMENDED] Increase decoding radius by 10% for additional safety margin
3. [RECOMMENDED] Implement constant-time failure handling carefully
4. [RECOMMENDED] Monitor DFP under non-uniform error distributions
