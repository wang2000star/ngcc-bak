# API_PKC x86 self-evaluation audit note

## Scope

* Algorithm category: key encapsulation mechanism (KEM).
* Algorithm families/variants: MAMBA-Frost and MAMBA-Frost-CC.
* Submission layout: one `API_PKC/` package containing both families, with one
  directory per AlgorithmInstance under both `Reference_Implementation/` and
  `Optimized_Implementation/`.
* Additional implementation: `Implementations/Additional_Implementation/` is a
  placeholder and is not part of the build/test/KAT targets in this audit.

## Parameter sets

The audited KEM secret key layout is `sk = PackSec(S) || pk || h_pk || z`.
`PackSec(S)` has `ceil(n * ell_r * t_s / 8)` bytes, `h_pk` is 32 bytes,
and `z` has `SHAREDSECRETBYTES` bytes, so
`SECRETKEYBYTES = PUBLICKEYBYTES + ceil(n * ell_r * t_s / 8) + 32 + SHAREDSECRETBYTES`.

| Instance | pk bytes | sk bytes | ct bytes | ss bytes |
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

## Build environment and options

* Compiler version used in this audit: recorded by `cc --version` when the audit
  commands are run.
* Reference flags: per-instance Makefiles use `-std=c99 -Wpedantic -Wall -Wextra -O2` for the scalar/reference path.
* Optimized flags: optimized Makefiles use `-std=c99 -Wpedantic -Wall -Wextra -O3 -march=x86-64 -mavx2 -maes -mtune=native -flto -fomit-frame-pointer` for the `_FAST_` path.
* Target platform: Linux x86/x86_64. Optimized execution requires CPU AVX2 and
  AES-NI support. The Makefile test and KAT recipes run generated binaries with an unlimited stack limit for the large 512-bit workspaces.
* C99 compatibility: API_PKC replaces direct `_Static_assert` usage with `FROST_STATIC_ASSERT`, which maps to `_Static_assert` in C11 and to a typedef-based compile-time assertion in C99. No algorithm behavior or byte layout is changed by this compatibility macro.

## Official API_PKC interface usage

Each AlgorithmInstance directory contains and builds through:

* `KEM_AlgorithmInstance.h`
* `KEM_AlgorithmInstance.c`
* `KAT_KEM.c`
* `drng.c` / `drng.h`
* `auxfunc.c` / `auxfunc.h`

The public KEM wrapper functions return 0 on success, negative errors on invalid
arguments/internal failure, write actual output lengths on success, and validate
input public-key/secret-key/ciphertext lengths before calling the core KEM.

## DRNG and auxiliary-function use

* KAT randomness uses the official DRNG through `get_random_number()` via the
  local `randombytes_adapter.c` bridge.
* SHAKE call sites are routed through the official `pseudoXOF()` by the local
  `common/sha3/fips202.c` adapter.
* The default Makefile paths do not use OpenSSL and do not compile standalone
  Keccak for SHAKE.

## Verification commands

Reference implementation:

```sh
cd API_PKC
make clean
make
make smoke
make check
make kats
make kat-repro
```

Optimized implementation:

```sh
cd API_PKC
make optimized-all
make optimized-smoke
make optimized-check
make optimized-kats
make optimized-kat-repro
make optimized-perf
```

`make smoke` runs a quick 5-round correctness test for every submitted instance; `make check` keeps the full 1000-round correctness test for every submitted instance.

KAT correctness is checked by generating KAT files with the official `KAT_KEM.c`
harness and by `kat-repro`, which generates vectors twice and compares them
byte-for-byte.

## Performance and resources

* Performance command: `make optimized-perf`.
* Resource consumption: not measured in this audit.
* Cycle counts and memory consumption are not reported here unless produced by a
  separate benchmark run; do not infer them from this document.

## Submission-layout risk for author confirmation

This package intentionally keeps MAMBA-Frost and MAMBA-Frost-CC together under a
single `API_PKC/` directory. If the receiving authority interprets the submission
rules as requiring one archive per algorithm family, the authors should confirm
whether a single combined package is acceptable before final submission.
