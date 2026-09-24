# NTRE Symmetric Microbenchmark Summary

Date: 2026-06-29

## Inputs

- CSV: `Benchmark_Results/ntre_symmetric_microbench.csv`
- Log: `Benchmark_Results/ntre_symmetric_microbench.log`
- Driver: `Benchmark_Results/ntre_symmetric_microbench.c`
- Script: `Benchmark_Results/run_ntre_symmetric_microbenchmarks.sh`
- Loop count: 10000
- Build profile: `gcc -O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra`

## Per-Function Cycles

| Instance | hash_H | hash_G | sample_psi1 | hash_F |
| --- | ---: | ---: | ---: | ---: |
| NTRE-128 | 19784 | 13755 | 5589 | 1925 |
| NTRE-256 | 35874 | 26777 | 10051 | 5761 |
| NTRE-512 | 90214 | 48302 | 16342 | 13338 |

## Interpretation

- `hash_H()` is the dominant Encaps/Decaps symmetric primitive for all three instances.
- `hash_G()` is also large because it hashes the full public key with SM3.
- `sample_psi1()` is relevant to KeyGen because `sample_f()` and `sample_g()` call it.
- `hash_F()` is smaller than `hash_H()` but still visible in Encaps/Decaps.

## Combined Priority With Polynomial Microbenchmarks

- KeyGen priority:
  1. `poly_baseinv()`
  2. `hash_G()`
  3. `sample_psi1()`
- Encaps priority:
  1. `hash_H()`
  2. `hash_G()`
  3. `poly_basemul_add()`
  4. `hash_F()`
- Decaps priority:
  1. `hash_H()`
  2. `poly_basemul()`
  3. `poly_msg_mod2_to_bytes()`
  4. `hash_F()`

## Recommended Next Target

Optimize the symmetric layer before writing more small polynomial assembly:

1. Profile `pseudoXOF()` and `sm3hash()` inside `auxfunc.c`.
2. Optimize `hash_H()` first, without changing its output bytes or `HASH_H_OUTBYTES`.
3. Then optimize `hash_G()` / SM3 public-key hashing.
4. In parallel, keep `poly_baseinv()` as the main KeyGen arithmetic target.
