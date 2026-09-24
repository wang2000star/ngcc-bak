# Hash Algorithm - Duet x86 Performance-Optimized Version

This directory contains the x86 AVX2 C performance-optimized implementations and
self-evaluation scripts for the three Duet parameter sets: Duet-512, Duet-768,
and Duet-1024.

Each parameter set contains:

- `CryptHash_Duet-*-c-avx2.c`: x86-64 AVX2 optimized C implementation.
- `CryptHash_Duet-*.h`: public interface header for the corresponding parameter
  set.
- `KAT_CryptHash.c`, `drng.c`, `drng.h`: files required for KAT generation.
- `README`: instance notes.

## Compilation

Run all parameter sets:

```sh
./build_benchmark.sh
```

Build Duet-768 only:

```sh
./build_benchmark.sh --bits 768 --build-only
```

By default, the script uses `gcc` and enables
`-mavx2 -mbmi -mbmi2 -madx -mtune=native`.
