# HARE-384 / KR / x86 optimized implementation

Active HARE v1.5 KR `[51,41]_2` covering-code backend.

## Role

x86 AVX2/PCLMUL performance implementation using the shared optimized kernels and the same API/KAT format as Reference.

API algorithm name: `HARE-384-kr`.

## Public API sizes

| Field | Bytes |
|---|---:|
| Public key | 13157 |
| Expanded secret key | 13301 |
| Ciphertext | 23693 |
| Shared secret | 48 |

The expanded secret key layout is `ekKEM || dkPKE || sigma || seedKEM`.  The
seed-only reconstruction size is `48` bytes, but this implementation
uses the expanded API layout above.

## Main parameters

| Parameter | Value |
|---|---:|
| `PARAM_N` | 104869 |
| `PARAM_K` (bytes) | 48 |
| `PARAM_OMEGA = PARAM_OMEGA_R` | 193 |
| `PARAM_OMEGA_E` | 361 |
| `PARAM_N1` | 91 |
| `PARAM_N2` | 1152 |
| `PARAM_L1 = PARAM_N1 * PARAM_N2` | 104832 |
| `PARAM_ALPHA` | 15 |
| `PARAM_COMP_N` | 51 |
| `PARAM_COMP_K` | 41 |
| covering radius | 2 |

## Files

```text
api.h                         public KEM byte sizes and instance name
parameters.h                  HARE instance parameters and derived sizes
reed_solomon.h                parameter-derived Reed-Solomon declarations
KEM_AlgorithmInstance.c/.h    API_PKC-facing wrapper functions
```
