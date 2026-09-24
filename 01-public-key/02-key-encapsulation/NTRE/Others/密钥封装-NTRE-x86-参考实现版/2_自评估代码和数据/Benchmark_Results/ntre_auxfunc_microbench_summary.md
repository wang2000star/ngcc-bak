# NTRE Auxfunc Microbenchmark Summary

Date: 2026-06-29

## Inputs

- CSV: `Benchmark_Results/ntre_auxfunc_microbench.csv`
- Log: `Benchmark_Results/ntre_auxfunc_microbench.log`
- Driver: `Benchmark_Results/ntre_auxfunc_microbench.c`
- Script: `Benchmark_Results/run_ntre_auxfunc_microbenchmarks.sh`
- Loop count: 10000
- Build profile: `gcc -O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra`

## Results

| Instance | Function shape | Input bytes | Output bytes | SM3 calls | Cycles |
| --- | --- | ---: | ---: | ---: | ---: |
| NTRE-128 | pseudoXOF hash_H | 74 | 347 | 11 | 19781 |
| NTRE-128 | pseudoXOF hash_F | 41 | 41 | 2 | 1929 |
| NTRE-128 | pseudoXOF sample_psi1 | 33 | 162 | 6 | 5557 |
| NTRE-128 | sm3hash pk | 972 | 32 | 1 | 13592 |
| NTRE-256 | pseudoXOF hash_H | 114 | 631 | 20 | 35713 |
| NTRE-256 | pseudoXOF hash_F | 82 | 81 | 3 | 5390 |
| NTRE-256 | pseudoXOF sample_psi1 | 33 | 324 | 11 | 10202 |
| NTRE-256 | sm3hash pk | 1944 | 32 | 1 | 26142 |
| NTRE-512 | pseudoXOF hash_H | 177 | 1072 | 34 | 91302 |
| NTRE-512 | pseudoXOF hash_F | 145 | 144 | 5 | 13437 |
| NTRE-512 | pseudoXOF sample_psi1 | 33 | 576 | 18 | 16636 |
| NTRE-512 | sm3hash pk | 3456 | 32 | 1 | 46832 |

## Interpretation

- The measured `pseudoXOF` shapes match the higher-level `hash_H`, `hash_F`, and `sample_psi1` timings, so the wrapper layer is not the main cost.
- `hash_H()` is expensive because `pseudoXOF()` calls SM3 once for every 32 output bytes.
- `hash_G()` is expensive because `sm3hash()` hashes the complete public key.
- `pseudoXOF()` also allocates temporary buffers on every call, but the dominant cost is the repeated SM3 compression work.
- `auxfunc.c` is shared/fixed NGCC-style support code. Directly changing it can harm template compatibility; optimized alternatives should be byte-for-byte tested against the current functions.

## Next Optimization Candidates

1. Add byte-for-byte tests for a candidate optimized `pseudoXOF` and `sm3hash` implementation.
2. Implement a specialized `pseudoXOF` path for byte-aligned NTRE calls:
   - `hash_H`: fixed input/output lengths per instance.
   - `hash_F`: fixed input/output lengths per instance.
   - `sample_psi1`: fixed 33-byte input and instance-dependent output.
3. Implement or import an optimized SM3 compression routine only after the byte-for-byte tests are in place.
4. Keep `poly_baseinv()` as the main arithmetic-side KeyGen target.
