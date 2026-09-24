==============================================================================
SQIsignTriangle — ICCS API_PKC implementation package
Next-generation Commercial Cryptographic Algorithms Program (NGCC)
Function: Digital Signature (SIG)
==============================================================================

1. DIRECTORY STRUCTURE
----------------------
\Implementations
  \Reference_Implementation        Portable ISO C (no platform-specific ISA)
    \SQIsignTriangle_lvl1            classical security level 128-bit
    \SQIsignTriangle_lvl2            classical security level 160-bit
    \SQIsignTriangle_lvl5            classical security level 256-bit
    \SQIsignTriangle_lvl6            classical security level 512-bit
  \Optimized_Implementation        Optimized for mainstream 64-bit PCs
    \SQIsignTriangle_lvl1            (Intel "Broadwell"/AVX2 backend)
    \SQIsignTriangle_lvl2
    \SQIsignTriangle_lvl5
    \SQIsignTriangle_lvl6
  \README                          This file.

The four parameter sets cover the three mandatory classical security strengths
required by the call (128 / 256 / 512-bit) plus the 160-bit set:

  instance               classical  public key  secret key  signature
                          strength    (bytes)     (bytes)     (bytes)
  SQIsignTriangle_lvl1     128           65          353         204
  SQIsignTriangle_lvl2     160           81          437         255
  SQIsignTriangle_lvl5     256          129          701         408
  SQIsignTriangle_lvl6     512          257         1409         816

The Reference_Implementation and Optimized_Implementation of a given level
implement exactly the same algorithm and therefore produce identical key pairs,
signatures and test vectors; they differ only in the finite-field arithmetic
backend (portable C vs. Broadwell-optimized).

2. FILES IN EACH INSTANCE FOLDER
--------------------------------
  SIG_AlgorithmInstance.h   API_PKC SIG programming interface + instance name
                            (ALGORITHM_INSTANCE, OUTPUT_BLANK_TEST_VECTORS).
  SIG_AlgorithmInstance.c   Implementation of the SIG interface (sig_keygen /
                            sig_sign / sig_verify). It wraps the SQIsignTriangle
                            NIST API (crypto_sign_keypair / crypto_sign /
                            crypto_sign_open) and routes randombytes() through
                            the ICCS DRNG. Every function is commented.
  KAT_SIG.c                 ICCS test-vector generator. UNCHANGED template file.
  drng.c, drng.h            ICCS Deterministic Random Number Generator.
                            UNCHANGED template files.
  auxfunc.c, auxfunc.h      ICCS auxiliary hash/XOF (SM3 / pseudo-hash /
                            pseudo-XOF). UNCHANGED template files.
  CMakeLists.txt            Automated build entry (single parameter set).
  build.sh                  Configure + build the KAT generator.
  generate_kat.sh           Build, run, and copy the KAT vector into
                            ..\..\..\Test_Vectors.
  README.txt                Per-instance description.
  sqisigntriangle\          Self-contained SQIsignTriangle C source for this
                            parameter set (see section 4).

3. BUILDING AND GENERATING TEST VECTORS
---------------------------------------
Requirements: a C11 compiler, CMake >= 3.13, and GMP (libgmp / libgmp-dev).

  cd Reference_Implementation/SQIsignTriangle_lvl1
  ./build.sh            # configures and builds KAT_SIG_SQIsignTriangle_lvl1
  ./generate_kat.sh     # runs it and writes the vector to ../../../Test_Vectors

The same steps apply to every instance under either implementation directory.
GMP backend selection (CMake option GMP_LIBRARY): SYSTEM (default; requires an
installed GMP), BUILD (download and build GMP), or MINI (bundled mini-gmp).

4. USE OF THE ICCS AUXILIARY HASH/XOF (Note 5 / requirement 3.4(5))
------------------------------------------------------------------
The submission requirements mandate that the cryptographic hash and XOF used by
the implementation be the auxiliary functions supplied by ICCS (auxfunc.c).
SQIsignTriangle originally used SHAKE256 (FIPS-202). To comply, the FIPS-202
module of the bundled source,

  sqisigntriangle/src/common/generic/fips202.c

has been replaced by an adapter that implements the SHAKE/SHA3 programming
interface on top of the ICCS auxiliary functions:

  * SHAKE256 (the only hash/XOF the scheme uses, for the Fiat-Shamir
    "hash-to-challenge") is realized with pseudoXOF(), i.e. the GB/T 32918.4
    SM3-based key-derivation function. Because pseudoXOF is a counter-mode KDF
    it is prefix-consistent, so the incremental absorb/squeeze behaviour of the
    sponge is reproduced exactly and the test vectors are deterministic.
  * sha3_256 -> sm3hash(256); sha3_512 -> pseudohash(512) (provided for
    interface completeness; not used by the scheme).

No other source file of the scheme was modified for this purpose, and the ICCS
template files (KAT_SIG.c, drng.*, auxfunc.*) are bytewise unchanged.

Note (as the requirements state) these auxiliary functions are intended only
for correctness verification and preliminary performance evaluation; they will
be replaced by standardized hash/XOF functions in later evaluation rounds.
==============================================================================
