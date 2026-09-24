# Locally Quasi-Cyclic Twisted McEliece 1 5000-Run Experiment Report

## Experiment Setup

- Generated at: `2026-04-28 10:41:14 EDT`
- Instance: `QCTM128`
- Parameters: `(m,n,t,l)=(18,10070,142,19)`
- Experiments: `1` calls to `crypto_kem_keypair()`
- RNG initialization: deterministic KAT-style seed (`entropy_input[i]=i`, `randombytes_init(..., NULL, 256)`)
- Platform: `Darwin 24.6.0 arm64`

## Outcome Summary

- Successful key generations: `1/1`
- Failed key generations: `0/1`
- Runs that needed more than one internal seeded attempt: `0`
- Final observation: every successful run eventually obtained a systematic block-circulant parity-check matrix, because `goppa_keygen()` returned full rank (`m*t`) before `crypto_kem_keypair()` completed.

## Attempt Statistics

- Total internal seeded attempts: `1`
- Average internal attempts per experiment: `1.0000`
- Attempts per experiment (`min / median / p95 / max`): `1 / 1 / 1 / 1`
- Aggregate support-construction rejects: `0`
- Aggregate Goppa-polynomial rejects: `0`
- Aggregate systematic-form rejects inside `goppa_keygen()`: `0`
- Aggregate `goppa_init()` rejects: `0`

## Timing Statistics

- Total wall-clock time: `11.906 s`
- Average time per experiment: `11906.303 ms`
- Time per experiment (`min / median / p95 / max`): `11906.303 / 11906.303 / 11906.303 / 11906.303 ms`

## Output Files

- Summary report: `QCTM128_5000_report.md`
- Raw per-run data: `QCTM128_5000_results.csv`
