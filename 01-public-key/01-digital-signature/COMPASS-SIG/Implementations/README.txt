Reference and Optimized Implementations of COMPASS-SIG
=======================================================

Directory Structure
-------------------

\Implementations
\Reference_Implementation     C reference implementation (ISO C, no platform-specific code)
  \COMPASS-SIG-128             128-bit classical / 80-bit quantum security
  \COMPASS-SIG-256             256-bit classical / 128-bit quantum security
  \COMPASS-SIG-384             384-bit classical / 192-bit quantum security
  \COMPASS-SIG-512             512-bit classical / 256-bit quantum security
\Optimized_Implementation     Optimized implementation for 64-bit PC processors
  \COMPASS-SIG-128
  \COMPASS-SIG-256
  \COMPASS-SIG-384
  \COMPASS-SIG-512
\Additional_Implementation    Additional platform implementations (optional)

File Description (per Algorithm Instance)
------------------------------------------

Official NGCC API files (DO NOT MODIFY):
  drng.c / drng.h              Deterministic Random Number Generator (SM3-based)
  auxfunc.c / auxfunc.h        Auxiliary hash/XOF functions (sm3hash, pseudohash, pseudoXOF)
  KAT_SIG.c                    Known Answer Test vector generator for digital signatures
  SIG_AlgorithmInstance.h      NGCC digital signature programming interface

Algorithm implementation files (MODIFIED by submitter):
  SIG_AlgorithmInstance.c      Bridge: NGCC API <-> internal crypto functions
  sign.c / sign.h              Core signature scheme (keygen, sign, verify)
  packing.c / packing.h        Key/signature serialization
  poly.c / poly.h              Polynomial operations (NTT, sampling, packing)
  polyvec.c / polyvec.h        Polynomial vector operations
  ntt.c / ntt.h                Number Theoretic Transform
  reduce.c / reduce.h          Modular reduction
  rounding.c / rounding.h      Power2Round, Decompose
  symmetric-shake.c / symmetric.h  Symmetric primitives (via pseudoXOF/pseudohash)
  params.h                     Algorithm parameters (per security level)
  config.h                     Build configuration
  api.h                        Key/signature size definitions
  Makefile                     Automated build script

Build & Generate KAT
--------------------
  make kat          Build KAT generation program
  ./test/test_kat*  Run KAT generation (output saved to ./output/)

Notes
-----
- The cryptographic hash and XOF functions use the official auxiliary functions
  (sm3hash, pseudohash, pseudoXOF) provided by ICCS.
- The DRNG (SM3-based) is used for deterministic key generation in KAT.
- Reference implementation uses ISO C (C99).
- All implementations support COMPASS_SIG_MODE = 128, 256, 384, 512.
