# Hash Algorithm - Duet x86 Performance-Optimized Version

This directory contains the x86 AVX2 C performance-optimized implementations for
the three Duet parameter sets: Duet-512, Duet-768, and Duet-1024.

This package is organized according to the primary optimized implementation
location in the Cuishen-submit layout. Duet currently does not submit a
single-file x86 assembly implementation, so this directory contains the retained
`02-c-avx2` C implementation.

Each parameter set contains:

- `CryptHash_Duet-*-c-avx2.c`: AVX2 optimized C implementation.
- `CryptHash_Duet-*.h`: public interface header for the corresponding parameter
  set.
- `KAT_CryptHash.c`, `drng.c`, `drng.h`: files required for KAT generation.
- `README`: instance notes.

## Compilation

The recommended way to build the KAT generators is to use `generate_kat.sh` in
this directory. Example manual compilation for Duet-512:

```sh
gcc -O3 -std=c99 -Wpedantic -Wall -Wextra \
  -mavx2 -mbmi -mbmi2 -madx -mtune=native \
  -I Duet-512 \
  Duet-512/CryptHash_Duet-512-c-avx2.c \
  <test_or_benchmark_sources> \
  -o <output>
```

## Notes

- This package targets x86-64 AVX2/BMI2/ADX evaluation environments.
- The AVX512 implementation is located in
  `../Additional_Implementation/Duet-*/AVX512/`.
- The ARMv8 NEON implementation is located in
  `../Additional_Implementation/Duet-*/ARMv8/`.
