CTL KEM Algorithm Implementation
================================================================================

This repository contains the implementation of the CTL Key Encapsulation Mechanism (KEM) algorithm, submitted to the Next-generation Commercial Cryptographic Algorithms Program (NGCC).

--------------------------------------------------------------------------------

DIRECTORY STRUCTURE
--------------------------------------------------------------------------------

Implementations/
  +-- Reference_Implementation/     # Reference implementation of CTL KEM
  |     +-- CTL-257-512/           # Algorithm instance for CTL-257-512 parameter set
  |     +-- CTL-769-1024/          # Algorithm instance for CTL-769-1024 parameter set
  |     +-- CTL-3329-2048/         # Algorithm instance for CTL-3329-2048 parameter set
  |
  +-- Optimized_Implementation/     # Optimized implementation of CTL KEM (AVX2)
  |     +-- CTL-257-512/           # Algorithm instance for CTL-257-512 parameter set
  |     +-- CTL-769-1024/          # Algorithm instance for CTL-769-1024 parameter set
  |     +-- CTL-3329-2048/         # Algorithm instance for CTL-3329-2048 parameter set
  |
  +-- readme.txt                    # This file

--------------------------------------------------------------------------------

ALGORITHM INSTANCES
--------------------------------------------------------------------------------

Each algorithm instance directory contains:
  - KEM_AlgorithmInstance.c : KEM implementation wrapper
  - KEM_AlgorithmInstance.h : KEM header file
  - api.c            : Common API implementation
  - api_XXX.c        : Instance-specific API implementation
  - kemXXX.c         : KEM core implementation
  - keygen.c         : Key generation module
  - KAT_KEM.c        : KAT vector generation program
  - test_kem.c       : Correctness test program
  - benchmark.c      : Performance benchmark program
  - drng.c/h         : Deterministic Random Number Generator
  - auxfunc.c/h      : Auxiliary functions
  - readme.txt       : Instance-specific documentation

--------------------------------------------------------------------------------

ALGORITHM PARAMETERS
--------------------------------------------------------------------------------

  Parameter Set    Security Level    Public Key    Secret Key    Ciphertext
  --------------   --------------    ----------    ----------    ----------
  CTL-257-512      128 bits          521 bytes     2953 bytes    473 bytes
  CTL-769-1024     192 bits          1230 bytes    6030 bytes    1006 bytes
  CTL-3329-2048    256 bits          3009 bytes    15617 bytes   2353 bytes

  Parameter Set    Shared Secret    Dimension    Modulus
  --------------   -------------    ---------    -------
  CTL-257-512      16 bytes         512          q = 257
  CTL-769-1024     32 bytes         1024         q = 769
  CTL-3329-2048    48 bytes         2048         q = 3329

--------------------------------------------------------------------------------

BUILD AND TEST
--------------------------------------------------------------------------------

Reference Implementation:
  cd Reference_Implementation/CTL-257-512
  make all
  ./test_kem.exe
  ./benchmark.exe

Optimized Implementation (AVX2):
  cd Optimized_Implementation/CTL-257-512
  make all
  ./test_kem.exe
  ./benchmark.exe

Dependencies:
  - GCC compiler (C11 standard, AVX2 support for optimized version)
  - GMP library (GNU Multiple Precision Arithmetic Library)
  - Quadmath library (for extended precision arithmetic)

--------------------------------------------------------------------------------

PERFORMANCE BENCHMARK
--------------------------------------------------------------------------------

The benchmark program measures the performance of key generation, encapsulation,
and decapsulation operations in clock cycles per operation.

Output Format:
  CTL-257-512 KEM Performance Benchmark (AVX2 Optimized)
  Iterations: 10000

  Keygen:   123456 cycles/op
  Encaps:   78901 cycles/op
  Decaps:   234567 cycles/op
  Total:    436924 cycles/op

================================================================================
self-evaluation：
test_kem_correctness_ctl.c
benchmark_selfeval_ctl.c
