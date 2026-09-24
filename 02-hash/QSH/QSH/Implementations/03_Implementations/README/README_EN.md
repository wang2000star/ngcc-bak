# QuantaSylva Hash (QSH) — Implementation Code (README)

This directory contains all implementation code for the QuantaSylva Hash (QSH) algorithm,
organized according to Section 3.4 of the *Cryptographic Hash Algorithm Submission Requirements*.
This file describes the structure of `03_Implementations/` and gives a brief description of each file.

---

## 1. Algorithm instances

Three algorithm instances are submitted. Every implementation covers all three:

| Instance | Word width w | Digest length | Notes |
|----------|--------------|---------------|-------|
| QSH-512  | 32 bits | 512 bits  | Mandatory instance |
| QSH-768  | 64 bits | 768 bits  | Optional instance |
| QSH-1024 | 64 bits | 1024 bits | Mandatory instance |

The underlying permutation is ChaCha-Bahru (9 full R-rounds + 1 final column-only layer),
used in a binary-tree mode: internal state h = 2048, message block m = h/2, chunk = 16 blocks.

Conventions: message bits are MSB-first within bytes; words and the 128-bit length are
little-endian; the digest is serialized little-endian.

---

## 2. Directory layout

```
03_Implementations/
├── README/
│   ├── README.md                          ← Chinese version
│   └── README_EN.md                       ← this file
│
├── 1_Reference_Implementation/            Reference implementation (pure ISO C99, no platform ISA)
│   ├── README.txt
│   ├── QSH-512/
│   ├── QSH-768/
│   └── QSH-1024/
│
├── 2_Optimized_Implementation/            Optimized implementation (mainstream 64-bit PC, x86-64 AVX2)
│   ├── QSH-512/
│   ├── QSH-768/
│   ├── QSH-1024/
│   
│
└── 3_Additional_Implementation/           Additional implementation (ARM AArch64 / ARMv8-A, NEON)
    ├── QSH-512/
    ├── QSH-768/
    └── QSH-1024/
```

Each `QSH-512/`, `QSH-768/`, `QSH-1024/` subfolder is a self-contained project. Building it
produces an executable `katgen`, which writes the known-answer-test (KAT) vector files for that
instance into `./output/` (`KAT_2_12_*`, `KAT_2_23_*`, `KAT_2_33_*`, `KAT_Loop_*`), matching the
test vectors in `04_TestVectors/` of this submission package.

---

## 3. Files inside each instance folder

| File | Description |
|------|-------------|
| `CryptHash_AlgorithmInstance.h` | Programming-interface header, using the official API (`API_CryptHash`) provided by the Commercial Cryptography Standardization Institute. Defines this instance's `ALGORITHM_INSTANCE` and `DIGEST_BIT_LENGTH`; declares `CryptHash()`. |
| `CryptHash_AlgorithmInstance.c` | The QSH algorithm itself — the `CryptHash()` implementation, covering padding, the chunk loop and the binary-tree mode. |
| `drng.c` / `drng.h` | Official ICCS deterministic RNG (DRNG) used to generate test messages. Unmodified. |
| `KAT_CryptHash.c` | Official KAT generator; calls `CryptHash()` to produce the 4 classes of known-answer test vectors. |
| `build.sh` | Build script that compiles the executable `katgen`. |
| `CMakeLists.txt` | CMake build file (present in the reference implementation only). |
| `README.txt` | Per-instance notes (present in the reference implementation only). |

Common interface:

```c
int CryptHash(int digest_len_bits,
              const unsigned char *msg,
              unsigned long long   msg_len_bits,
              unsigned char       *digest);
```

---

## 4. The three implementations

### 4.1 Reference — `1_Reference_Implementation/`

- Written in pure ISO C99, no compiler intrinsics, no platform-specific ISA; fully portable.
- Serves as the authoritative reference for the algorithm semantics; the optimized and additional
  implementations are bit-identical to it.
- Build: `sh build.sh`, or `cmake -B build && cmake --build build`.
- Build command (excerpt): `gcc -std=c99 -Wpedantic -Wall -Wextra -O2 drng.c KAT_CryptHash.c CryptHash_AlgorithmInstance.c -o katgen`

### 4.2 Optimized — `2_Optimized_Implementation/`

- Targets mainstream 64-bit PC processors using the x86-64 AVX2 instruction set (AVX2 required).
- SIMD strategy is *within-permutation*: the 16 mutually independent G functions of each layer are
  computed in parallel across 16 SIMD lanes, keeping a permutation's full 64-word state in registers;
  the mode (padding, chunk loop, binary tree) is scalar.
- Bit-identical to the reference implementation for all instances and all lengths.
- Build: `sh build.sh`.
- Build command (excerpt): `gcc -O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 ...`
- Subfolder `Optimized_Implementation_WithinPerm/` is a within-permutation SIMD variant tuned for
  low latency: faster on short messages and competitive on long ones; also requires AVX2.

### 4.3 Additional — `3_Additional_Implementation/`

- Targets ARM AArch64 / ARMv8-A using NEON.
- Strategy: within-permutation for w=32; 2-way batch for w=64.
- Build: `sh build.sh`.
- Build command (excerpt): `gcc -O3 -march=armv8-a -flto -fomit-frame-pointer -std=c99 ...`
- Note: the NEON path was not validated in the authoring environment; KAT-validate on ARM/qemu
  after porting.

---

## 5. Build & generate test vectors

In any instance folder:

```sh
sh build.sh        # builds the executable katgen
./katgen           # writes KAT_2_12 / KAT_2_23 / KAT_2_33 / KAT_Loop vectors into ./output/
```

Per Section 3.5 of the submission requirements, the KAT generator produces digests for: messages
of length 0 to 2^12 bits, a message of length 2^23 bits, a message of length 2^33 bits, and a
looped test on a 2^13-bit message.

> Build requirements: a C99-compatible compiler (e.g. GCC). The optimized implementation requires
> an AVX2-capable x86-64 host; the additional implementation requires an ARM AArch64 toolchain.
