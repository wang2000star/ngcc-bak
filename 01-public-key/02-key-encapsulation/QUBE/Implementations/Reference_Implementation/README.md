# QUBE Reference Implementation

This directory contains a PDF-aligned QUBE-SM3 reference implementation for the
API_PKC KEM interface. The implementation covers all five parameter sets from the PDF:
QUBE-128, QUBE-192, QUBE-256, QUBE-384, and QUBE-512.

## Layout

```text
Reference_Implementation/
├── CMakeLists.txt
├── qube-128/
├── qube-192/
├── qube-256/
├── qube-384/
└── qube-512/
```

Each `qube-*` directory is a self-contained API_PKC instance:

```text
qube-*/
├── CMakeLists.txt
├── KAT/                    # KAT file and SHA-256 checksum for this instance
├── lib/
│   └── api_pkc/            # Official auxfunc/drng files, kept unchanged
├── src/
│   ├── common/             # KEM wrapper, SM3 wrappers, code and utilities
│   └── ref/                # Parameters, PDF PKE, packing, sampling, ring arithmetic
└── test/
    ├── KAT_KEM.c           # API_PKC KAT driver
    ├── test_components.c   # Packing, sampling, ring, code, PKE tests
    ├── test_kem.c          # API length/KEM/fallback smoke test
    └── test_soak.c         # Multi-iteration KEM soak test
```

## Build

Build all five instances through the umbrella root:

```bash
cmake -S . -B /tmp/qube-all-build
cmake --build /tmp/qube-all-build --parallel
```

Executables are written to `/tmp/qube-all-build/bin/`.

Build a single self-contained instance:

```bash
cmake -S qube-128 -B /tmp/qube-128-build
cmake --build /tmp/qube-128-build --parallel
```

## Test

Run the full local test suite:

```bash
ctest --test-dir /tmp/qube-all-build --output-on-failure
```

The CTest suite builds and runs 20 tests: smoke, component, soak, and KAT tests
for each of the five parameter sets.

Run one instance:

```bash
ctest --test-dir /tmp/qube-128-build --output-on-failure
```

Run a longer QUBE-128 soak test:

```bash
/tmp/qube-all-build/bin/soak-qube-128 100000
```

Verify committed KAT checksums:

```bash
(cd qube-128/KAT && shasum -a 256 -c SHA256SUMS)
(cd qube-192/KAT && shasum -a 256 -c SHA256SUMS)
(cd qube-256/KAT && shasum -a 256 -c SHA256SUMS)
(cd qube-384/KAT && shasum -a 256 -c SHA256SUMS)
(cd qube-512/KAT && shasum -a 256 -c SHA256SUMS)
```

The API_PKC KAT driver writes output to `../KAT` relative to its working
directory. CTest sets the KAT test working directory to the instance `test/`
directory, so regenerated vectors land in that instance's `KAT/` directory.

## API Behavior

The public API is `kem_qube.h`:

```c
unsigned long long kem_get_pk_len_bytes(void);
unsigned long long kem_get_sk_len_bytes(void);
unsigned long long kem_get_ss_len_bytes(void);
unsigned long long kem_get_ct_len_bytes(void);

int kem_keygen(unsigned char *pk, unsigned long long *pk_len_bytes,
               unsigned char *sk, unsigned long long *sk_len_bytes);
int kem_enc(unsigned char *pk, unsigned long long pk_len_bytes,
            unsigned char *ss, unsigned long long *ss_len_bytes,
            unsigned char *ct, unsigned long long *ct_len_bytes);
int kem_dec(unsigned char *sk, unsigned long long sk_len_bytes,
            unsigned char *ct, unsigned long long ct_len_bytes,
            unsigned char *ss, unsigned long long *ss_len_bytes);
```

The caller/test driver must define and initialize:

```c
DRNG_ctx drng_algorithm;
```

Length-correct tampered ciphertexts use FO implicit rejection and return a
fallback shared secret with API success. Null pointers or invalid lengths return
API errors.

## Dependency Notes

The cryptographic auxiliary functions and deterministic random generator are
only taken from each instance's `lib/api_pkc/auxfunc.[ch]` and
`lib/api_pkc/drng.[ch]`. Those official files are compiled as a separate CMake
object target and are not modified by this refactor.
