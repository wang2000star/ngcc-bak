# BAG-Loong Implementations

This directory contains the BAG-Loong KEM implementation packages.

The current `Reference_Implementation/` tree is a pure C99/API_PKC-oriented
reference implementation of BAG-Loong.KEM. It implements the four submitted
parameter sets:

| Instance | Classical security target | Reference directory |
|---|---:|---|
| BAG-Loong-128 | 128 bit | `Reference_Implementation/Loong-Block-ms-128` |
| BAG-Loong-256 | 256 bit | `Reference_Implementation/Loong-Block-ms-256` |
| BAG-Loong-384 | 384 bit | `Reference_Implementation/Loong-Block-ms-384` |
| BAG-Loong-512 | 512 bit | `Reference_Implementation/Loong-Block-ms-512` |

## Reference implementation

Each parameter-set directory is self-contained. It contains its own `src/`,
`lib/`, `test/`, and `Makefile`, and does not require files from any external
`ref/`, notes, checksum, or development directory.

The implementation follows the API_PKC KEM interface:

- `kem_get_pk_len_bytes`
- `kem_get_sk_len_bytes`
- `kem_get_ss_len_bytes`
- `kem_get_ct_len_bytes`
- `kem_keygen`
- `kem_enc`
- `kem_dec`

The API_PKC helper files used by the KAT driver are included
inside each instance under `lib/api_pkc/`, and the KAT driver is kept as
`test/KAT_KEM.c`.

The hash and XOF layer is implemented through the API_PKC SM3-family interfaces:

- `sm3hash(256, ...)` for the 256-bit public-key identifier `ID(pk)`;
- `pseudohash(512, ...)` for the fixed 512-bit SFO function `G`;
- `pseudoXOF(...)` for variable-length seed expansion, sampling streams, and KDF
  output.

The API-level KEM ciphertext is encoded as:

```text
ct_api = ct_core || salt
```

where `salt` is 128 bits.

## Build and KAT generation

Enter one parameter-set directory and run:

```sh
make all
make kat
```

`make kat` builds and runs `test/KAT_KEM.c`. The generated KAT text file is
written to the instance-local `output/` directory.

For a clean build/run/clean local check, run:

```sh
make submission-check
```

This target performs:

```text
make distclean
make kat
make distclean
```

It verifies that the instance can be built from a clean tree, that the KAT driver
runs successfully, and that generated build artifacts are removed afterwards. It
does not depend on development-only checksum files.

## Test vectors

The repository-level `Test_Vectors/` directory contains the API_PKC-style KEM
text vectors for the four BAG-Loong instances:

```text
KAT_KEM_BAG-Loong-128.txt
KAT_KEM_BAG-Loong-256.txt
KAT_KEM_BAG-Loong-384.txt
KAT_KEM_BAG-Loong-512.txt
```

## Portability notes

On Unix-like systems, including Linux, macOS, WSL, and MSYS2/MinGW environments,
the reference instances can be built directly with `make` and a C99 compiler. The
Makefiles use only ordinary C compilation, local include paths, and local source
files. Native Windows environments without a POSIX-like `make` should use WSL or
MSYS2/MinGW.
