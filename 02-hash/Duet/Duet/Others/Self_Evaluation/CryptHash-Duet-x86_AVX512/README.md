# Hash Algorithm - Duet x86_AVX512 Performance-Optimized Version

This directory contains the x86 AVX512 C performance-optimized implementations
and self-evaluation scripts for the three Duet parameter sets: Duet-512,
Duet-768, and Duet-1024.

Each parameter set contains:

- `CryptHash_Duet-*-c-avx512.c`: x86-64 AVX512 optimized C implementation.
- `CryptHash_Duet-*.h`: public interface header for the corresponding parameter
  set.
- `KAT_CryptHash.c`, `drng.c`, `drng.h`: files required for KAT generation.
- `README`: instance notes.

## Compilation

Run all parameter sets:

```sh
./build_benchmark.sh
```

Build Duet-1024 only:

```sh
./build_benchmark.sh --bits 1024 --build-only
```

By default, the script uses `gcc` and enables
`-mavx2 -mavx512f -mavx512vl -mavx512bw -mavx512dq -mtune=native`.
