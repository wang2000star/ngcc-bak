# x86 and ARM/SVE optimization matrix

| Module | Reference KR | x86 Optimized KR | ARM/SVE Additional KR | Optimizations not claimed in this package |
|---|---|---|---|---|
| `vector.c` | C99 dense/vector utilities | AVX2 add/compare/truncate; public-address support scan | SVE add/compare/truncate; SVE public-address support scan | Additional vector tuning is outside this package |
| `gf.c` | fixed-loop GF(2^8) | PCLMUL GF(2^8) | fixed-loop GF(2^8) | PMULL/bitsliced GF(2^8) is outside this package |
| `gf2x.c` | dense software GF2X | selected PCLMUL + Toom-3/Karatsuba + AVX2 reduction | selected dense GF2X: public-parameter Toom-3/Karatsuba, PMULL/software base products, SVE-assisted reduction | PMULL2 batching, generated ARM kernels, or workspace tuning are outside this package |
| `reed_muller.c` | RM top-1/top-2 erasure decoding | AVX2 Hadamard-style path preserving erasures | conservative path preserving erasures | SVE Hadamard and peak extraction are outside this package |
| `reed_solomon.c` | erasure-aware RS | erasure-aware RS with static constants and x86 GF | erasure-aware RS with static constants | syndrome/root/Forney vectorization is outside this package |

The selected optimized paths preserve PKE/KEM, parameters, KAT layout, dense public-size GF2X multiplication, RM erasure semantics, and RS error+erasure semantics.
