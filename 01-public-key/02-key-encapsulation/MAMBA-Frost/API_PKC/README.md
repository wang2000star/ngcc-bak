MAMBA-Frost: Plain-LWE KEM with Public Dither Quantization
=============================================================================

`MAMBA-Frost` / `Frost.KEM` is a plain-LWE key encapsulation mechanism based on
public dither quantization.

The active implementation is located in [`Frost/`](Frost/). Default builds,
correctness tests, KAT generation, and benchmark scripts use this directory.

## Security level variants

The implementation currently provides five KEM instances:

- `MAMBA-Frost-128`
- `MAMBA-Frost-192`
- `MAMBA-Frost-256`
- `MAMBA-Frost-384`
- `MAMBA-Frost-512`

The `Frost-CC/` tree provides the companion `MAMBA-Frost-CC-128/192/256/384/512`
KEM instances, with matching API_PKC reference and AVX2 optimized wrappers.

All five profiles use the u16 implementation family in both REFERENCE and
FAST/AVX2 builds. `MAMBA-Frost-128` has `q = 2^15` but still uses the same u16
storage and arithmetic path; `MAMBA-Frost-192/256/384/512` use `q = 2^16`.
The E8 message codec treats `ell_r = 8` as the E8 block dimension and uses
`ell_s` E8 blocks per ciphertext, so the FO plaintext size is
`b_msg * ell_r * ell_s` bits.

| Profile | n | m | ell_r | ell_s | q | p_pk | p_u | p_v | eta_s | eta_r | b_msg | pk bytes | ct bytes | sk bytes | ss bytes |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| MAMBA-Frost-128 | 512 | 512 | 8 | 8 | 2^15 | 2^10 | 2^10 | 2^5 | 2 | 2 | 2 | 5152 | 5192 | 6736 | 16 |
| MAMBA-Frost-192 | 880 | 880 | 8 | 8 | 2^16 | 2^11 | 2^11 | 2^6 | 1 | 1 | 3 | 9712 | 9760 | 11528 | 24 |
| MAMBA-Frost-256 | 1288 | 1288 | 8 | 8 | 2^16 | 2^13 | 2^12 | 2^8 | 1 | 1 | 4 | 16776 | 15552 | 19416 | 32 |
| MAMBA-Frost-384 | 1928 | 1928 | 8 | 12 | 2^16 | 2^13 | 2^13 | 2^9 | 1 | 1 | 4 | 25096 | 37736 | 29032 | 48 |
| MAMBA-Frost-512 | 2600 | 2600 | 8 | 16 | 2^16 | 2^14 | 2^14 | 2^7 | 1 | 1 | 4 | 36432 | 72944 | 41728 | 64 |

For KEM submissions, the secret key layout is `sk = PackSec(S) || pk || h_pk || z`.
`PackSec(S)` has `ceil(n * ell_r * t_s / 8)` bytes, `h_pk` is 32 bytes,
and `z` has `SHAREDSECRETBYTES` bytes. Thus
`SECRETKEYBYTES = PUBLICKEYBYTES + ceil(n * ell_r * t_s / 8) + 32 + SHAREDSECRETBYTES`.

## Public matrix expansion backend

The default build uses `MATRIX_A_BACKEND=AES128`. In this mode, the public
matrix `A` is expanded from the public seed `seed_A` with AES-128-ECB.

The optional `MATRIX_A_BACKEND=SHAKE128` path is a test backend. It changes only
public matrix expansion and leaves the rest of the KEM logic unchanged.

## Repository contents

- [`Frost/`](Frost/): active `MAMBA-Frost` implementation, tests, KAT targets,
  and benchmark scripts.
- [`API_PKC/`](API_PKC/): official NGCC KEM API adapters, self-contained
  reference and AVX2 optimized submission directories, deterministic KAT
  generators, and vectors for all five parameter sets.
- [`common/`](common/): shared AES, SHA3, and randomness utilities used by the C
  build.
- [`Makefile`](Makefile): root build entry point that forwards to `Frost/`.

## Build

From the repository root, run:

    make clean
    make

A successful build also runs the size test and prints:

    Frost size test PASSED

The root Makefile forwards to the active implementation under `Frost/`.

Build and test the official API_PKC wrappers separately with:

    make api
    make api-check
    make api-kats
    make api-kat-repro

Build and test the API_PKC AVX2 optimized wrappers with:

    make api-opt
    make api-opt-check
    make api-opt-kats
    make api-opt-kat-repro
    make api-opt-perf

Build and test only the Frost-CC API_PKC wrappers with:

    make api-cc
    make api-cc-check
    make api-cc-kats
    make api-cc-kat-repro
    make api-cc-opt
    make api-cc-opt-check
    make api-cc-opt-kats
    make api-cc-opt-kat-repro
    make api-cc-opt-perf

## Correctness tests

To run the default correctness test suite from the repository root, use:

    make check

To run the size test only, use:

    make size_test

The same tests can be run directly for REFERENCE and FAST/AVX2 builds with E8
enabled:

    make -C Frost clean
    make -C Frost OPT_LEVEL=REFERENCE FROST_USE_E8_CODE=1 tests test_e8_codec size_test

    for p in 128 192 256 384 512; do
        FROST_KEM_TEST_ITERATIONS=100 Frost/frost$p/test_KEM
        Frost/frost$p/test_e8_codec
    done

    make -C Frost clean
    make -C Frost OPT_LEVEL=FAST FROST_USE_E8_CODE=1 tests test_e8_codec size_test

    for p in 128 192 256 384 512; do
        FROST_KEM_TEST_ITERATIONS=100 Frost/frost$p/test_KEM
        Frost/frost$p/test_e8_codec
    done

Each per-level KEM test performs repeated key generation, encapsulation, and
decapsulation checks. A successful run prints:

    Tests PASSED. All session keys matched.

## KAT generation and verification

KAT support is provided under `Frost/`.

Build the KAT executables with E8 enabled:

    make -C Frost clean
    make -C Frost OPT_LEVEL=FAST FROST_USE_E8_CODE=1 KATS

This builds one `PQCtestKAT_kem` executable for each parameter profile:

    Frost/frost128/PQCtestKAT_kem
    Frost/frost192/PQCtestKAT_kem
    Frost/frost256/PQCtestKAT_kem
    Frost/frost384/PQCtestKAT_kem
    Frost/frost512/PQCtestKAT_kem

Run the KAT executables as follows:

    for p in 128 192 256 384 512; do
        (cd Frost/frost$p && ./PQCtestKAT_kem)
    done

A successful KAT run prints:

    Known Answer Tests PASSED.

The KAT runs generate response files under the corresponding `KAT/` directories.
For example:

    Frost/frost128/KAT/PQCkemKAT_6736.rsp
    Frost/frost192/KAT/PQCkemKAT_11528.rsp
    Frost/frost256/KAT/PQCkemKAT_19416.rsp
    Frost/frost384/KAT/PQCkemKAT_29032.rsp
    Frost/frost512/KAT/PQCkemKAT_41728.rsp

The generated KAT files and temporary build products can be removed with:

    make -C Frost clean

## Benchmarking and profiling

The full-flow benchmark script is located at:

    Frost/scripts/bench_levels_ref_avx2.sh

Run it from the repository root for all five profiles, REFERENCE and FAST/AVX2,
with E8 enabled and AES128 public-matrix expansion:

    BENCH_LEVELS="128 192 256 384 512" MESSAGE_CODEC_FLAGS=1 MATRIX_A_BACKENDS=AES128 RUN_REFERENCE=1 RUN_AVX2=1 Frost/scripts/bench_levels_ref_avx2.sh /tmp/frost_bench_ref_fast.csv

A successful benchmark run prints:

    [done] Benchmark complete. CSV written to /tmp/frost_bench_ref_fast.csv

Component-level profiling is available through:

    PROFILE_LEVELS="128 192 256 384 512" MESSAGE_CODEC_FLAGS=1 MATRIX_A_BACKENDS=AES128 RUN_REFERENCE=1 RUN_AVX2=1 FROST_PROFILE_ITERATIONS=10 Frost/scripts/profile_breakdown_ref_avx2.sh /tmp/frost_breakdown.csv

Remove benchmark output and generated build products with:

    rm -f /tmp/frost_bench_ref_fast.csv /tmp/frost_breakdown.csv
    make -C Frost clean

## Clean build tree

To remove generated executables, object files, KAT outputs, and temporary build
directories, run:

    make clean

or directly inside the implementation directory:

    make -C Frost clean
