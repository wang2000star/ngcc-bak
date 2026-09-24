# NTRE Polynomial Microbenchmark Summary

Date: 2026-06-29

## Inputs

- CSV: `Benchmark_Results/ntre_poly_microbench.csv`
- Log: `Benchmark_Results/ntre_poly_microbench.log`
- Driver: `Benchmark_Results/ntre_poly_microbench.c`
- Script: `Benchmark_Results/run_ntre_poly_microbenchmarks.sh`
- Loop count: 10000
- Build profile: `gcc -O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra`

## Per-Function Cycles

| Instance | baseinv | basemul_add | basemul | mod2 decode | ntt | invntt | tobytes | frombytes | cbd1_prime | cbd1 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| NTRE-128 | 7702 | 4114 | 3198 | 616 | 6498 | 3576 | 481 | 196 | 90 | 107 |
| NTRE-256 | 15590 | 7912 | 6978 | 1186 | 1766 | 1756 | 1015 | 443 | 248 | 200 |
| NTRE-512 | 26827 | 13915 | 12459 | 1917 | 2842 | 2475 | 1753 | 757 | 429 | 362 |

## Interpretation

- `poly_baseinv()` now uses batch inversion. It is still a major KeyGen primitive, but no longer dominates as heavily as before.
- `poly_msg_mod2_to_bytes()` now emits one byte per 8 coefficients directly while preserving the original centered mod-q semantics.
- For Encaps and Decaps, the largest remaining polynomial-side targets are `poly_basemul_add()` and `poly_basemul()`.
- `poly_sub()` and `poly_double()` are already small enough that further work there is not a meaningful priority.
- The Encaps/Decaps KEM totals are much larger than the sum of these polynomial primitives, so symmetric code (`hash_H`, `hash_F`, `hash_G`, `sample_psi1`) likely needs its own microbenchmark before choosing the next implementation target.

## Recommended Next Target

1. Keep NGCC support functions out of the optimization scope.
2. If KeyGen remains the priority, inspect the remaining `poly_baseinv()` precompute and prefix-product work.
3. If Encaps/Decaps are the priority, optimize `poly_basemul_add()` and `poly_basemul()` next.
