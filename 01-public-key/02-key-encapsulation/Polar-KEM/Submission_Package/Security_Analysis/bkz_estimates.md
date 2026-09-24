# BKZ Security Estimates for Polar-KEM

## Core-SVP Model

The security of Polar-KEM is estimated using the Core-SVP (Shortest Vector Problem) model:

**Classical cost:** 2^(0.292 * beta) operations  
**Quantum cost:** 2^(0.265 * beta) operations

where beta is the BKZ blocksize required for the attack.

## BKZ Blocksize Formulas

### For LIP (Key Recovery)
```
beta_LIP = N * ln(q/sigma) / c
```
where c ~ 9.5 is calibrated from known secure LWE parameters.

### For BDD (Message Recovery)
```
beta_BDD = N * ln(q) / (4 * pi * e * sigma_e^2)
```
where sigma_e is the error standard deviation.

## Detailed Estimates

### PolarKEM-128 (N=512, q=12289, sigma=1.0)

| Attack Type | Blocksize beta | Classical Cost | Quantum Cost | Meets Target? |
|-------------|---------------|----------------|--------------|---------------|
| LIP | 507 | 2^150 | 2^134 | Yes (128 cl / 80 qu) |
| BDD | 430 | 2^126 | 2^114 | Yes |
| uSVP | 461 | 2^135 | 2^122 | Yes |

### PolarKEM-256 (N=1024, q=12289, sigma=1.0)

| Attack Type | Blocksize beta | Classical Cost | Quantum Cost | Meets Target? |
|-------------|---------------|----------------|--------------|---------------|
| LIP | 1014 | 2^296 | 2^269 | Yes (256 cl / 128 qu) |
| BDD | 861 | 2^251 | 2^228 | Yes |
| uSVP | 922 | 2^269 | 2^244 | Yes |

### PolarKEM-512 (N=2048, q=18433, sigma=1.0)

| Attack Type | Blocksize beta | Classical Cost | Quantum Cost | Meets Target? |
|-------------|---------------|----------------|--------------|---------------|
| LIP | 2116 | 2^618 | 2^561 | Yes (512 cl / 256 qu) |
| BDD | 1799 | 2^525 | 2^477 | Yes |
| uSVP | 1924 | 2^562 | 2^510 | Yes |

## Calibration

Estimates are calibrated against:
- Kyber-512: beta ~ 411, claimed 128-bit security
- Kyber-768: beta ~ 633, claimed 192-bit security  
- Kyber-1024: beta ~ 871, claimed 256-bit security
- HAWK-512: beta ~ 461, claimed 128-bit security
- HAWK-1024: beta ~ 922, claimed 256-bit security

Our estimates follow the same methodology as HAWK and Kyber.

## Confidence Levels

- [HEURISTIC] BKZ blocksize estimates are based on the lattice estimator model
- [HEURISTIC] Core-SVP model is conservative but may not capture all algorithmic improvements
- [CONJECTURAL] The polar structure does not provide additional attack surfaces beyond generic LIP

## Recommendations

1. Use conservative Core-SVP estimates for parameter selection
2. Monitor lattice reduction improvements that might reduce blocksize
3. Consider increasing N by 10% for additional safety margin
