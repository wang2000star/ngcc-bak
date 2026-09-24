# Optimized AVX2 implementation

This directory contains API_PKC wrappers for the existing Frost optimized x86
implementation. The five instances are:

- `MAMBA-Frost-128`
- `MAMBA-Frost-192`
- `MAMBA-Frost-256`
- `MAMBA-Frost-384`
- `MAMBA-Frost-512`

It also contains API_PKC wrappers for the Frost-CC optimized x86 implementation:

- `MAMBA-Frost-CC-128`
- `MAMBA-Frost-CC-192`
- `MAMBA-Frost-CC-256`
- `MAMBA-Frost-CC-384`
- `MAMBA-Frost-CC-512`

Each instance has an independent `Makefile` and exposes the official API_PKC KEM
interface from `KEM_AlgorithmInstance.h/.c`:

- `kem_keygen`
- `kem_enc`
- `kem_dec`
- `kem_get_pk_len_bytes`
- `kem_get_sk_len_bytes`
- `kem_get_ct_len_bytes`
- `kem_get_ss_len_bytes`

The optimized build uses `_FAST_`, `-mavx2`, and `-maes`. It compiles
`Frost/src/frost*.c`, `Frost/src/kem.c`, `Frost/src/noise.c`,
`Frost/src/frost_macrify.c`, `Frost/src/util.c`, `common/aes/aes_ni.c`,
and `common/sha3/fips202.c`. In this API_PKC tree `fips202.c` is an auxiliary
adapter: the Frost/Frost-CC `shake128` and `shake256` call sites invoke the
official `pseudoXOF()` function from `auxfunc.c`. The Keccak times4 AVX2 source
is not compiled by the default optimized build. `Reference_Implementation/` is
not used by these builds.

## Sizes

| instance | pk | sk | ct | ss |
|---|---:|---:|---:|---:|
| MAMBA-Frost-128 | 5152 | 6736 | 5192 | 16 |
| MAMBA-Frost-192 | 9712 | 11528 | 9760 | 24 |
| MAMBA-Frost-256 | 16776 | 19416 | 15552 | 32 |
| MAMBA-Frost-384 | 25096 | 29032 | 37736 | 48 |
| MAMBA-Frost-512 | 36432 | 41728 | 72944 | 64 |
| MAMBA-Frost-CC-128 | 5152 | 6736 | 5192 | 16 |
| MAMBA-Frost-CC-192 | 9712 | 11528 | 9760 | 24 |
| MAMBA-Frost-CC-256 | 16776 | 19416 | 15552 | 32 |
| MAMBA-Frost-CC-384 | 37628 | 43492 | 25204 | 48 |
| MAMBA-Frost-CC-512 | 72832 | 83328 | 36544 | 64 |

The values come from each copied `Frost/src/api_frost*.h` file and are checked by
the local `params.h` bridge.

## Commands

From one instance directory:

```sh
make
make check
make kat-generate
make kat-repro
make kat-install
make perf-run
make clean
```

From `API_PKC/`:

```sh
make optimized-all
make optimized-check
make optimized-kats
make optimized-kat-repro
make optimized-perf
make optimized-clean
```

For Frost-CC only:

```sh
make cc-optimized-all
make cc-optimized-check
make cc-optimized-kats
make cc-optimized-kat-repro
make cc-optimized-perf
```

From the repository root:

```sh
make api-opt
make api-opt-check
make api-opt-kats
make api-opt-kat-repro
make api-opt-perf
make api-opt-clean
```

`make check` runs 1000 keypair/encaps/decaps agreement rounds for each instance.
`make kat-repro` regenerates and byte-compares the KAT file. `make perf-run`
writes a per-instance CSV containing average cycles, ops/s, compile flags, CPU
feature requirement, and pk/sk/ct/ss sizes. LTO is not enabled by default because
GCC/MinGW reports a false `-Wuninitialized` warning in the inlined AVX2 core
under `-flto`; callers can still override `CFLAGS` explicitly.

## Requirements

- GCC or Clang on x86/x86_64.
- Runtime CPU support for AVX2 and AES-NI. The `check_avx2` helper fails with a
  clear error before optimized binaries are run if support is missing.
- No third-party dependency for the default AES128 matrix backend.

The KAT RNG is the official API_PKC DRNG (`drng.c`) through
`randombytes_adapter.c`; Frost/Frost-CC hash/XOF calls are routed to the
official API_PKC `pseudoXOF()` auxiliary function by the local
`common/sha3/fips202.c` adapter.
