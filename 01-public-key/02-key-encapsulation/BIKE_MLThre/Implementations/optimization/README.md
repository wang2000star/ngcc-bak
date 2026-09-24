# bikekem_v2

This directory contains the trimmed BIKE KEM + ML threshold implementation needed to build and run the current experiments.

The public interface should use security targets:

- `SECURITY_BITS=128`
- `SECURITY_BITS=256`
- `SECURITY_BITS=512`

`SECURITY_BITS=192` is still available for compatibility, but the main targets are 128/256/512.

## Layout

- `bike_kem_ml/`: C/CMake implementation, including 128/256 optimized decoders and experimental 512 support.
- `model/`: required MLP model JSON files and the fixed-point C exporter.
- `scripts/`: minimal build/test wrappers for 128/256/512.

## Required Models

Only these JSON models are required for the main 128/256/512 targets:

- `model/aws_l1_mlthre_mlp_1000.json` for 128-bit
- `model/aws_l5_mlthre_mlp_1000.json` for 256-bit
- `model/bike512_l7_ref_dynamic_mlp_1000.json` for 512-bit

## Current 512-bit Parameters

The bundled `bike_kem_ml` copy uses these experimental 512-bit candidate
parameters:

- `R_BITS=150001`
- `D=273`
- `T=524`

For `SECURITY_BITS=512`, the message, internal seed, private-key fallback
value, ciphertext `c1` component, and shared secret are all 64 bytes. This is a
functional 512-bit-width evaluation profile; it is not a claim that the
experimental parameter set has a proven 512-bit classical security level.

## API_PKC KEM KAT Test

This package includes the unchanged API_PKC KEM KAT driver and DRNG under
`bike_kem_ml/kat/`. The adapter maps the API_PKC `kem_*` functions to the
native BIKE KEM API:

- `crypto_kem_keypair(pk, sk)`
- `crypto_kem_enc(ct, ss, pk)`
- `crypto_kem_dec(ss, ct, sk)`

The KEM core uses the API_PKC evaluation primitives:

- 128/192/256 targets use `sm3hash(256, ...)`.
- The 512 target uses `pseudohash(512, ...)`.
- Sparse-vector sampling uses a stateful adapter over `pseudoXOF(...)`.
- `auxfunc.c` and `auxfunc.h` are copied byte-for-byte from
  `API_PKC/Implementations/Reference_Implementation/AlgorithmInstance/`.

For each key-generation or encapsulation call, the adapter obtains 64 bytes
from `drng_algorithm`. The variable-length AES-CTR DRBG initializer absorbs all
64 bytes in two updates (48 bytes followed by 16 bytes); no suffix is ignored.

Requirements for the top-level Makefile KAT flow:

- `make`
- a C99 compiler, tested with `gcc`
- OpenSSL development headers and `libcrypto`
- the standard math library

## Reproducibility and C99 Scope

This package is built and tested in C99 compilation mode. The top-level
Makefile passes `-std=c99`, and the CMake build flags in `bike_kem_ml` also use
`-std=c99`.

The 128-bit, 256-bit, and 512-bit API_PKC KEM KAT runs have been verified with
GCC on Linux x86_64. For reproducibility, describe this package as requiring a
C99-compatible compiler and as tested with GCC using `-std=c99`.

Do not describe it as a pure ISO C99 portable implementation. The code still
depends on the normal project build environment, including OpenSSL/libcrypto,
GCC/Clang-style compiler support, x86_64, and SIMD-related build flags used by
the BIKE implementation.

Run the API_PKC KEM KAT test from this directory:

```bash
make kat128
make kat256
make kat512
```

Each target creates a separate build directory, compiles the KEM with
`USE_NIST_RAND` and `USE_API_PKC_AUX`, builds the `api-pkc-kat` executable,
and runs 10 deterministic `keygen -> enc -> dec` test cases. The driver
compares the encapsulated and decapsulated shared secrets and exits with code
0 on success.

Generated outputs are written inside each build directory:

- `build_kat_128/output/KAT_KEM_BIKEKEM_v2_128.txt`
- `build_kat_256/output/KAT_KEM_BIKEKEM_v2_256.txt`
- `build_kat_512/output/KAT_KEM_BIKEKEM_v2_512.txt`

Verified reference vectors are also included in `test_vectors/`:

- `test_vectors/KAT_KEM_BIKEKEM_v2_128.txt`
- `test_vectors/KAT_KEM_BIKEKEM_v2_256.txt`
- `test_vectors/KAT_KEM_BIKEKEM_v2_512.txt`

The expected first-case output lengths are:

| Target | PK | SK | CT | SS |
| --- | ---: | ---: | ---: | ---: |
| 128 | 1541 | 5223 | 1573 | 32 |
| 256 | 5122 | 16494 | 5154 | 32 |
| 512 | 18751 | 58501 | 18815 | 64 |

These files are provided for reproducibility and result comparison. They are
not required as input to the KAT program; running `make kat128`, `make kat256`,
or `make kat512` regenerates the corresponding output inside the matching
`build_kat_*` directory.

Clean generated KAT build directories:

```bash
make distclean
```

## Script Usage

When running helper scripts from this trimmed directory, set:

```bash
ROOT_DIR=/home/lyb/BIKE/bikekem_v2
```

Example:

```bash
cd /home/lyb/BIKE/bikekem_v2
ROOT_DIR=/home/lyb/BIKE/bikekem_v2 \
  TESTS=10 \
  RESULTS_DIR=/home/lyb/BIKE/bikekem_v2/results_security512_base_10 \
  ./scripts/test-bike-kem-512-base.sh
```

Direct base-test wrappers:

```bash
./scripts/test-bike-kem-128-base.sh
./scripts/test-bike-kem-256-base.sh
./scripts/test-bike-kem-512-base.sh
```

512-bit MLP test:

```bash
./scripts/test-bike-kem-512-ml.sh
```

Cycle-count performance collection:

```bash
./scripts/collect-bike-kem-perf-security.sh
```

Direct CMake builds should also use security bits:

```bash
cmake -S bike_kem_ml -B build_512 -DSECURITY_BITS=512
```

Build/result directories and generated datasets were intentionally not copied.
