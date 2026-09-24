# YuanYang DSA YuanYang-1024 Reference Implementation

This directory contains the submission-facing reference C implementation for
YuanYang DSA YuanYang-1024. It contains only the signature API, signature codecs,
key generation, signing, verification, KAT tools, and benchmark harnesses for
this parameter set.

## Targets

- `make all`: build `KAT_SIG`, `SIG_bench`, `SIG_bench_batch`, `check_kat`,
  `verify_kat`, and `functional_test`.
- `make KAT_SIG`: build the NGCC-style signature KAT generator.
- `make check_kat`: build the deterministic KAT replay checker.
- `make verify_kat`: build the verifier-only KAT checker.
- `make benchmark`: build and run the full keygen/sign/verify benchmark.
- `make benchmark_batch`: build and run the full signing versus offline
  presampling benchmark.
- `make benchmark-generic`: build and run the benchmark with portable generic
  C flags.
- `make kat_ngcc`: build with `-DNGCC_KATS`, generate KATs, replay them, and
  verify them.
- `make functional_test`: build a keygen/sign/verify and malformed-input test.
- `make clean`: remove local build products and generated KAT output.

The signature KAT generator writes `output/KAT_SIG_yuanyang-1024.txt`.

## Layout

- `SIG_AlgorithmInstance.c/.h`: exported signature API.
- `KAT_SIG.c`, `check_kat.c`, `verify_kat.c`: KAT generation and checking.
- `benchmark.c`, `benchmark_batch.c`, `functional_test.c`: local validation and
  performance harnesses.
- `yuanyang_params.h`, `yuanyang_inner.h`: parameter constants and internal
  signature types.
- `codec.c`, `common.c`, `ntt.c`, `poly_inv_ntt.c`: encodings and ring helpers.
- `keygen/`: PairGen, NTRUSolve integration, security-loss checks, and signing
  precomputation export.
- `sign.c`, `sign_ntt.c`, `sampler.c`, `vrfy.c`: signing, signing NTT helpers,
  hybrid sampler, and verification.
- `auxfunc.[ch]`, `drng.[ch]`, `drng_algorithm.c`: submission auxiliary hash
  and deterministic RNG support.
