# API_CryptHash

Short overview of the two top-level areas used with this project.

## `lib/`

Low-level cryptographic primitives and helpers:

- **`lib/low/ZuD-1280/`** — ZC-1280 permutation: reference **plain** (`plain/`), **AVX2** (`avx2/`), and **32-bit** (`32bit/`) implementations plus shared headers.
- **`lib/low/ZuD-1536/`** — ZC-1536 permutation: same layout as above (plain / avx2 / 32bit).
- **`lib/common/`** — Shared headers (e.g. endianness for portable builds).

The `Implementations/` tree links these sources into the CryptHash harness (reference, optimized, or embedded profiles).

