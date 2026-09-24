# NTRE Optimized Benchmark Summary

Date: 2026-06-27

## Inputs

- Raw before data: `Benchmark_Results/ntre_optimized_before.csv`
- Raw before log: `Benchmark_Results/ntre_optimized_before.log`
- Raw after data: `Benchmark_Results/ntre_optimized_after.csv`
- Raw after log: `Benchmark_Results/ntre_optimized_after.log`
- Rounds per case: 3
- Loop count per round: 10000
- Interface: NGCC `kem_*` API through `Baseline/bench/bench_kem.c`

## Build Profiles

- Document profile:
  - Reference: `gcc -O2 -std=c99 -Wpedantic -Wall -Wextra`
  - Optimized: `gcc -O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra`
- Same-flags sanity profile:
  - Reference and optimized both use the optimized profile.

## Final Source Changes

- `poly_baseinv()` now uses Montgomery batch inversion in the optimized NTRE algorithm layer.
- `poly_msg_mod2_to_bytes()` now assembles one output byte per 8 coefficients directly while preserving the original `center_mod_q()` semantics.
- `NTRE-128` and `NTRE-256`: `poly_sub()` uses the AVX2 assembly path in `asm/add.s`.
- `NTRE-512`: `poly_sub()` remains scalar C. The AVX2 variant was tested and not retained because it did not improve the benchmark.
- Optimized Makefiles now default to the documented optimized profile and support `make kat`.
- The attempted `CBD'_1` branchless rewrite was measured and rolled back in optimized code because it slowed `NTRE-256` and `NTRE-512` under the benchmark profile.
- NGCC support functions and fixed files are not optimized or modified in this revision.
- Full hand-written AVX2 replacements for base multiplication, packing, and CBD are not present in this revision.

## Optimized After vs Before

Positive values mean the final optimized implementation is faster than the before baseline.

| Instance | KeyGen | Encaps | Decaps |
| --- | ---: | ---: | ---: |
| NTRE-128 | 34.24% | 4.79% | 7.31% |
| NTRE-256 | 31.84% | 3.68% | 8.22% |
| NTRE-512 | 36.82% | 2.01% | 5.80% |

## Document Profile: Reference vs Optimized After

| Instance | KeyGen | Encaps | Decaps |
| --- | ---: | ---: | ---: |
| NTRE-128 | 38.01% | 19.50% | 29.35% |
| NTRE-256 | 47.60% | 37.88% | 53.08% |
| NTRE-512 | 63.40% | 51.38% | 60.96% |

## Same-Flags Sanity: Reference vs Optimized After

| Instance | KeyGen | Encaps | Decaps |
| --- | ---: | ---: | ---: |
| NTRE-128 | 33.39% | -0.90% | 6.07% |
| NTRE-256 | 36.06% | 15.89% | 30.28% |
| NTRE-512 | 46.51% | 23.24% | 33.19% |

## Verification

- `make clean all test` succeeded for all three optimized instances.
- The optimized test executables reported `count: 0`.
- `make kat` succeeded for all three optimized instances.
- Optimized KAT SHA-256 hashes matched `Test_Vectors/KAT_KEM_NTRE-128.txt`, `Test_Vectors/KAT_KEM_NTRE-256.txt`, and `Test_Vectors/KAT_KEM_NTRE-512.txt`.
