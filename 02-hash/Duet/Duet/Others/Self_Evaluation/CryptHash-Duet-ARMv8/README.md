# Hash Algorithm - Duet ARMv8 Performance-Optimized Version

This directory contains the ARMv8 NEON performance-optimized implementations and
self-evaluation scripts for the three Duet parameter sets: Duet-512, Duet-768,
and Duet-1024.

Each parameter set contains:

- `CryptHash_Duet-*-c-neon.c`: ARMv8 NEON optimized implementation.
- `CryptHash_Duet-*.h`: public interface header for the corresponding parameter
  set.
- `KAT_CryptHash.c`, `drng.c`, `drng.h`: files required for KAT generation.
- `README`: instance notes.

## Compilation

Run all parameter sets:

```sh
./build_benchmark.sh
```

Build Duet-512 only:

```sh
./build_benchmark.sh --bits 512 --build-only
```

By default, the script uses the compiler specified by the `CC` environment
variable; if `CC` is not set, it uses `cc`.
