# MAMBA-Frost / MAMBA-Frost-CC API_PKC submission layout

`Implementations/Reference_Implementation/` contains independent scalar KEM
instances for MAMBA-Frost and MAMBA-Frost-CC. `Implementations/Optimized_Implementation/` contains the matching
AVX2/AES-NI optimized instances. Each instance includes the official
API_PKC KEM interface, unmodified official KAT/DRNG/auxiliary sources, the small
RNG/API adapters, and the exact subset of existing Frost core sources needed to
build it.
`Official_Template/` retains the original unmodified API_PKC template and its
blank vectors for audit purposes.

## Package scope

`API_PKC/` is the single top-level submission package for this audit. It contains
two KEM families/variants: default MAMBA-Frost and MAMBA-Frost-CC. Each
AlgorithmInstance has its own directory; both `Reference_Implementation/` and
`Optimized_Implementation/` cover all ten instances, and `Test_Vectors/` contains
the corresponding KEM KAT text files. `Implementations/Additional_Implementation/`
is a placeholder only and is not used by the build, test, KAT, or performance
targets.

Audit note: because some submission text may be interpreted as requiring one
archive per algorithm family, authors should confirm that one combined `API_PKC/`
package for Frost and Frost-CC is acceptable before final submission.

The reference builds use the scalar/reference arithmetic path, AES-128 public
matrix expansion, and E8 message codec. Frost/Frost-CC core call sites named
`shake128` and `shake256` are routed by `common/sha3/fips202.c` to the official
API_PKC auxiliary `pseudoXOF()` function. No security parameter, ciphertext
encoding, FO transform, or constant-time implicit-rejection logic is changed by
the wrapper.

The optimized builds are kept under `Optimized_Implementation/` and use `_FAST_`
with `-std=c99 -Wpedantic -Wall -Wextra -O3 -march=x86-64 -mavx2 -maes -mtune=native -flto -fomit-frame-pointer`, `frost_macrify.c`, and `aes_ni.c`. Their default build also
routes `shake128`/`shake256` through API_PKC `pseudoXOF()` and does not compile
the Keccak times4 AVX2 source. They do not use or modify the reference
submission directories.

## Commands

From `API_PKC/`:

```sh
make                 # build every KAT generator and API test
make smoke           # quick 5-round agreement/rejection test per parameter set
make check           # full 1000-round agreement and rejection tests per parameter set
make kats            # populate Test_Vectors/KAT_KEM_MAMBA-Frost-*.txt
make kat-repro       # generate every KAT twice and compare byte-for-byte
make clean
```

Optimized AVX2 builds:

```sh
make optimized-all        # build all optimized API wrappers, KATs, tests, perf tools
make optimized-smoke      # quick 5-round optimized correctness test
make optimized-check      # full 1000-round agreement tests per optimized parameter set
make optimized-kats       # populate Test_Vectors/KAT_KEM_MAMBA-Frost-*.txt
make optimized-kat-repro  # generate every optimized KAT twice and compare
make optimized-perf       # run 100-iteration cycles/ops/s measurements
make optimized-clean
```

Frost-CC-only targets are also available:

```sh
make cc-all
make cc-smoke
make cc-check
make cc-kats
make cc-kat-repro
make cc-optimized-all
make cc-optimized-smoke
make cc-optimized-check
make cc-optimized-kats
make cc-optimized-kat-repro
make cc-optimized-perf
make cc-clean
```

The source requires a C99 compiler. The API_PKC copy retains compile-time size checks through a C99-compatible `FROST_STATIC_ASSERT` macro. Reference builds use `-std=c99 -Wpedantic -Wall -Wextra -O2`. The Makefile test and KAT recipes run the generated binaries with `ulimit -s unlimited` so the large 512-bit stack workspaces do not depend on a small shell stack limit.
The default target is AMD64; portable reference builds may override the core's
existing architecture selector, for example `make ARCH_DEFINE=_ARM_`.
Optimized builds require an x86/x86_64 CPU with AVX2 and AES-NI; the build runs
`check_avx2` before executing optimized binaries and fails clearly if those CPU
features are unavailable.

## Exact KEM sizes

The KEM secret key layout is `sk = PackSec(S) || pk || h_pk || z`.
`PackSec(S)` has `ceil(n * ell_r * t_s / 8)` bytes, `h_pk` is 32 bytes,
and `z` has `SHAREDSECRETBYTES` bytes. Therefore
`SECRETKEYBYTES = PUBLICKEYBYTES + ceil(n * ell_r * t_s / 8) + 32 + SHAREDSECRETBYTES`.

| Instance | Public key | Private key | Ciphertext | Shared secret |
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
