# Pavelor Implementations

This directory contains the reference and optimized software implementations of the Pavelor cryptographic hash algorithm. The implementations follow the `CryptHash` programming interface provided by the Institute of Commercial Cryptography Standards (ICCS) for submissions to the Next-generation Commercial Cryptographic Algorithms Program.

## 1. Directory Structure

```text
Implementations/
  README
  Reference_Implementation/
    Pavelor-512/
      CryptHash_AlgorithmInstance.c
      CryptHash_AlgorithmInstance.h
      KAT_CryptHash.c
      drng.c
      drng.h
    Pavelor-768/
      CryptHash_AlgorithmInstance.c
      CryptHash_AlgorithmInstance.h
      KAT_CryptHash.c
      drng.c
      drng.h
    Pavelor-1024/
      CryptHash_AlgorithmInstance.c
      CryptHash_AlgorithmInstance.h
      KAT_CryptHash.c
      drng.c
      drng.h
  Optimized_Implementation/
    Pavelor-512/
      CryptHash_AlgorithmInstance.c
      CryptHash_AlgorithmInstance.h
      KAT_CryptHash.c
      drng.c
      drng.h
    Pavelor-768/
      CryptHash_AlgorithmInstance.c
      CryptHash_AlgorithmInstance.h
      KAT_CryptHash.c
      drng.c
      drng.h
    Pavelor-1024/
      CryptHash_AlgorithmInstance.c
      CryptHash_AlgorithmInstance.h
      KAT_CryptHash.c
      drng.c
      drng.h
```

No additional implementation is included in this submission package.

## 2. Algorithm Instances

The following algorithm instances are provided as separate implementation directories:

| Instance | Digest length | Rate | Capacity | Implementation directories |
| --- | ---: | ---: | ---: | --- |
| `Pavelor-512` | 512 bits | 1536 bits | 1024 bits | `Reference_Implementation/Pavelor-512`, `Optimized_Implementation/Pavelor-512` |
| `Pavelor-768` | 768 bits | 1024 bits | 1536 bits | `Reference_Implementation/Pavelor-768`, `Optimized_Implementation/Pavelor-768` |
| `Pavelor-1024` | 1024 bits | 512 bits | 2048 bits | `Reference_Implementation/Pavelor-1024`, `Optimized_Implementation/Pavelor-1024` |

Each instance directory is self-contained and can be compiled independently.

## 3. File Descriptions

The files in each instance directory have the following purposes:

| File | Description |
| --- | --- |
| `CryptHash_AlgorithmInstance.c` | Implementation of the selected Pavelor instance. It defines the `CryptHash` function and the internal permutation, padding, absorption, and squeezing routines. |
| `CryptHash_AlgorithmInstance.h` | ICCS interface header. It defines the algorithm instance name, digest length, test-vector output mode, and the prototype of `CryptHash`. |
| `KAT_CryptHash.c` | ICCS known-answer-test generator for cryptographic hash submissions. It generates `KAT_2_12`, `KAT_2_23`, `KAT_2_33`, and `KAT_Loop` files. |
| `drng.c` | Deterministic random number generator used by the ICCS KAT generator. |
| `drng.h` | Header file for `drng.c`. |

## 4. Programming Interface

All implementations provide the following function:

```c
int CryptHash(int digest_len_bits,
              const unsigned char *msg,
              unsigned long long msg_len_bits,
              unsigned char *digest);
```

The parameters are as follows:

| Parameter | Description |
| --- | --- |
| `digest_len_bits` | Requested digest length in bits. It must match the instance in the current directory. |
| `msg` | Pointer to the input message. For an empty message, this pointer may be `NULL` only when `msg_len_bits` is zero. |
| `msg_len_bits` | Input message length in bits. Bit-oriented messages are supported. |
| `digest` | Pointer to the output buffer. The buffer size must be at least `digest_len_bits / 8` bytes. |

The function returns `0` on success and a non-zero value on error.

Each separated instance accepts only its own digest length. For example, the `Pavelor-512` implementation accepts `digest_len_bits = 512` and returns an error for other digest lengths.

## 5. Reference Implementation

The reference implementation is located in:

```text
Implementations/Reference_Implementation/
```

It is written in ISO C and does not rely on platform-specific AES instruction intrinsics. It is intended primarily for clarity, portability, and independent verification of the algorithm specification.

To compile the KAT generator for a reference implementation, enter the corresponding instance directory and run:

```sh
gcc -O2 -std=c99 -Wall -Wextra KAT_CryptHash.c drng.c CryptHash_AlgorithmInstance.c -o kat
```

On Windows/MSYS2, the output executable may be named `kat.exe`:

```sh
gcc -O2 -std=c99 -Wall -Wextra KAT_CryptHash.c drng.c CryptHash_AlgorithmInstance.c -o kat.exe
```

## 6. Optimized Implementation

The optimized implementation is located in:

```text
Implementations/Optimized_Implementation/
```

It is intended for mainstream 64-bit PC processors supporting AES-NI-compatible AES round instructions. The implementation uses 128-bit AES round intrinsics for the internal permutation.

To compile the KAT generator for an optimized implementation, enter the corresponding instance directory and run:

```sh
gcc -O3 -std=c99 -Wall -Wextra -maes -msse2 KAT_CryptHash.c drng.c CryptHash_AlgorithmInstance.c -o kat
```

On Windows/MSYS2, the output executable may be named `kat.exe`:

```sh
gcc -O3 -std=c99 -Wall -Wextra -maes -msse2 KAT_CryptHash.c drng.c CryptHash_AlgorithmInstance.c -o kat.exe
```

If the target compiler does not support AES intrinsics or the target processor does not support the corresponding instruction set, the reference implementation should be used instead.

## 7. KAT Generation

The KAT generator uses the macros in `CryptHash_AlgorithmInstance.h`:

```c
#define OUTPUT_BLANK_TEST_VECTORS 0
#define ALGORITHM_INSTANCE "Pavelor-512"   /* or "Pavelor-768", "Pavelor-1024" */
#define DIGEST_BIT_LENGTH 512              /* or 768, 1024 */
```

For formal KAT generation, `OUTPUT_BLANK_TEST_VECTORS` must be set to `0`. If it is set to `1`, the generator produces blank test-vector templates rather than digest values.

After compiling the KAT executable, run:

```sh
./kat
```

or, on Windows/MSYS2:

```sh
./kat.exe
```

The generated files are written to the `output/` directory under the current instance directory:

```text
output/KAT_2_12_[AlgorithmInstance].txt
output/KAT_2_23_[AlgorithmInstance].txt
output/KAT_2_33_[AlgorithmInstance].txt
output/KAT_Loop_[AlgorithmInstance].txt
```

For final submission, copy these files into the top-level `Test_Vectors/` directory using the names generated by the official KAT program, for example:

```text
Test_Vectors/KAT_2_12_Pavelor-512.txt
Test_Vectors/KAT_2_23_Pavelor-512.txt
Test_Vectors/KAT_2_33_Pavelor-512.txt
Test_Vectors/KAT_Loop_Pavelor-512.txt
```

The same procedure should be repeated for `Pavelor-768` and `Pavelor-1024`.

Note: generation of `KAT_2_33` requires a message buffer of size `2^33` bits, i.e., 1 GiB, plus additional working memory. A 64-bit build environment with sufficient memory is recommended. The loop test also takes a relatively long time because it performs 1,000,000 hash computations.

## 8. Suggested Build Workflow

A typical workflow for generating KAT files for one optimized instance is:

```sh
cd Implementations/Optimized_Implementation/Pavelor-512
gcc -O3 -std=c99 -Wall -Wextra -maes -msse2 KAT_CryptHash.c drng.c CryptHash_AlgorithmInstance.c -o kat.exe
./kat.exe
```

A typical workflow for generating KAT files for one reference instance is:

```sh
cd Implementations/Reference_Implementation/Pavelor-512
gcc -O2 -std=c99 -Wall -Wextra KAT_CryptHash.c drng.c CryptHash_AlgorithmInstance.c -o kat.exe
./kat.exe
```
