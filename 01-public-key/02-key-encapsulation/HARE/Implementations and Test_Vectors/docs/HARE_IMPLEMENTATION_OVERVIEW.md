# HARE implementation overview

## Active algorithm line

This KR-only package implements HARE v1.5 with KR `[51,41]_2` covering-code compression as `C2`.

## Directory matrix

| Directory | Instances | Purpose |
|---|---|---|
| `Reference_Implementation` | HARE-128/256/384/512 KR | Portable C99 reference |
| `Optimized_Implementation` | HARE-128/256/384/512 KR x86 | Main optimized 64-bit PC implementation |
| `Additional_Implementation` | HARE-128/256/384/512 KR ARM/SVE | Additional ARM/SVE implementation |

## Final KR parameter and API-size source

The machine-readable parameter source is `PARAMETER_MANIFEST.tsv`. Instance `api.h` and `parameters.h` files are checked against it by:

```bash
bash tools/gates/check_generated_artifacts.sh
```

The submitted API secret key is the expanded layout:

```text
dkKEM = ekKEM || dkPKE || sigma || seedKEM
```

## x86 optimized implementation

```text
PCLMUL 64x64 carry-less base multiplication
public-parameter top-level Toom-3 for KR instances
dense Karatsuba/PCLMUL submultiplication
AVX2-assisted X^PARAM_N-1 reduction
AVX2 add/compare/truncate and public-address support scan
PCLMUL GF(2^8)
AVX2 Hadamard-style RM with erasure output preserved
erasure-aware RS with static generator constants
```

## ARM/SVE Additional implementation

```text
SVE public-length vector add/compare/truncate
SVE public-address support-to-vector mask scan
fixed-loop GF(2^8)
public-parameter top-level Toom-3 GF2X for KR instances
dense Karatsuba GF2X submultiplication
NEON PMULL 64x64 base multiply when enabled
software CLMUL fallback when PMULL is disabled
SVE-assisted X^PARAM_N-1 reduction
conservative RM path
erasure-aware RS with static generator constants
```

## Security boundary

All implementation lines preserve:

```text
dense public-size GF2X multiplication
no secret sparse multiplication
no secret-support indexed write
full-length ciphertext comparison
masked implicit rejection
RM nearest/second-nearest erasure rule
RS error+erasure decoding
```
