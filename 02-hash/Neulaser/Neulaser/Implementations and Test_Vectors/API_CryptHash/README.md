# Neulaser API_CryptHash-V2 Package

This directory contains the C reference implementation and test vectors for the
fixed-output Neulaser hash family.

Neulaser is a PRNG-based hash construction.  The three submitted fixed-output
instances share the same coupled-NLSR primitive and differ only in public
parameters, IV prefix length, and digest length.

## Submitted Instances

| Instance | Digest length `n` | Seed/key length `k` | Chaining length `v` | PRNG state size `v+k` | NLSR modules `mu` |
| --- | ---: | ---: | ---: | ---: | ---: |
| Neulaser-512 | 512 | 960 | 576 | 1536 | 3 |
| Neulaser-768 | 768 | 1216 | 832 | 2048 | 4 |
| Neulaser-1024 | 1024 | 1472 | 1088 | 2560 | 5 |

All bit lengths in the table are measured in bits.

## Directory Layout

```text
API_CryptHash-V2/
  Implementations/
    Reference_Implementation/
      Makefile
      benchmark_hash.c
      Neulaser-512/
        CryptHash_AlgorithmInstance.c
        CryptHash_AlgorithmInstance.h
        KAT_CryptHash.c
        drng.c
        drng.h
      Neulaser-768/
        ...
      Neulaser-1024/
        ...
  Test_Vector/
    KAT_2_12_Neulaser-*.txt
    KAT_2_23_Neulaser-*.txt
    KAT_2_33_Neulaser-*.txt
    KAT_Loop_Neulaser-*.txt
  Statistical_Tests/
    randomness_tests.c
```

## Public API

Each instance exposes the required API:

```c
int CryptHash(
    int digest_len_bits,
    const unsigned char *msg,
    unsigned long long msg_len_bits,
    unsigned char *digest
);
```

The `digest_len_bits` argument must match the selected instance:
`512`, `768`, or `1024`.  Message lengths are measured in bits.  For
non-byte-aligned inputs, the implementation follows the MSB-first convention
used by the supplied KAT generator.

## Build

The reference implementation is written in ISO C99 and has no external crypto
library dependency.  It can be built with GCC, for example under MSYS2:

```sh
cd API_CryptHash-V2/Implementations/Reference_Implementation
make clean
make all
```

This builds `KAT_CryptHash.exe` for the three submitted instances.

## Test Vectors

The generated-answer test vectors are stored in `Test_Vector/`.
For each Neulaser instance, the package contains:

| File family | Purpose |
| --- | --- |
| `KAT_2_12_Neulaser-*.txt` | KATs up to `2^12` bits |
| `KAT_2_23_Neulaser-*.txt` | KATs for `2^23`-bit messages |
| `KAT_2_33_Neulaser-*.txt` | KATs for `2^33`-bit messages |
| `KAT_Loop_Neulaser-*.txt` | loop-test KATs |

To regenerate the vectors:

```sh
cd API_CryptHash-V2/Implementations/Reference_Implementation
make kat
```

The `2^33`-bit KAT generation requires enough memory to hold a 1 GiB message
buffer and may take a long time.

## Statistical Tests

`Statistical_Tests/randomness_tests.c` contains the standalone randomness test
driver used for the statistical evaluation of Neulaser outputs.  Build it
together with one selected instance implementation and header path when
reproducing the randomness tests.

## Notes

- The three reference source files `CryptHash_AlgorithmInstance.c` are intended
  to implement the same algorithm logic; the instance headers set the public
  name and digest length.
- Multi-byte words are encoded in big-endian order inside the Neulaser
  specification and implementation.
- The implementation targets mainstream little-endian x86/x86-64 development
  environments with a C99 compiler.
