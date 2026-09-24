# HARE x86 Optimized Implementation

x86 optimized implementation for the active KR line:

```text
HARE-128/256/384/512 KR x86
```

The optimized line uses AVX2/PCLMUL kernels for vector operations, GF(2^8), dense GF2X multiplication, Reed-Muller decoding, and erasure-aware Reed-Solomon decoding, while preserving the Reference API, KAT format, PKE/KEM semantics, RM erasure semantics, and RS error+erasure semantics.
