AFS-TrEDM Implementations README
================================

Purpose
-------
This README is the authoritative implementation directory description for the
submitted AFS-TrEDM package.  It replaces the earlier duplicated README.md /
README.txt notes in the development tree and gives the directory layout and a
brief description of each submitted source file class.

Function comments
-----------------
Submitter-written C sources include comments immediately before function
definitions to explain each function's role.  ICCS-provided helper files
(KAT_CryptHash.c, drng.c, drng.h) are kept as supplied by API_CryptHash.zip and
therefore retain their original ICCS comments and layout.

Submitted algorithm instances
-----------------------------
  AFS-TrEDM-512   512-bit digest; AFS-p-S6[1600,12]; g+h split 6+6
  AFS-TrEDM-768   768-bit digest; AFS-p-S6[1600,20]; g+h split 10+10
  AFS-TrEDM-1024  1024-bit digest; AFS-p-S6[1600,24]; g+h split 12+12

Top-level layout
----------------
  Implementations/
    README.txt
      This file.  Directory and file descriptions for the submitted
      implementations.

    Reference_Implementation/
      AFS-TrEDM-512/
      AFS-TrEDM-768/
      AFS-TrEDM-1024/
        Portable ISO C reference implementations.  These do not require
        platform-specific instruction sets and are intended as readable golden
        implementations for correctness evaluation.

    Optimized_Implementation/
      AFS-TrEDM-512/
      AFS-TrEDM-768/
      AFS-TrEDM-1024/
        Optimized 64-bit PC software implementations.  The default build is
        portable opt64.  Explicit AVX2 targets are provided for x86-64 hosts
        with AVX2 support.
      common/
        Shared optimized S6, dispatch, and batch/multibuffer backend sources
        used by the optimized and additional implementation Makefiles.

    Additional_Implementation/
      README.txt
        Description of optional implementations beyond Reference and Optimized.
      Batch_Multibuffer/
        Optional batch/multibuffer software implementation for throughput-
        oriented 64-bit PC evaluation.  Standard CryptHash() remains the
        mandatory API; batch entry points are additional APIs.

Reference_Implementation instance files
---------------------------------------
Each of Reference_Implementation/AFS-TrEDM-{512,768,1024}/ contains:

  Makefile
    Automated build script.  Targets include all, clean, kat, run-quick,
    run-benchmark, and performance-profile variants.  The kat target builds
    the ICCS KAT_CryptHash.c helper; running ./kat generates all four required
    KAT files into output/.

  CryptHash_AlgorithmInstance.c
    ICCS CryptHash API entry point wrapper for the instance.

  CryptHash_AlgorithmInstance.h
    Instance configuration header: ALGORITHM_INSTANCE string, digest length, and
    CryptHash() prototype.

  afs_tredm.c / afs_tredm.h
    Aligned TrEDM sponge/hash mode implementation and public internal hash
    interface.

  afs_p1600.c / afs_p1600.h
    Portable public permutation AFS-p-S6[1600,nr] implementation and prototypes.

  afs_lmds1600_s6.c / afs_lmds1600_s6.h
    Portable AFS-LMDS-1600-S6 linear layer implementation and prototypes.

  afs_sbox64.c / afs_sbox64.h
    Portable AFS64_t5_k2 64-bit ARX S-box implementation and prototypes.

  KAT_CryptHash.c
    ICCS-provided known-answer-test generator, kept byte-identical to the
    KAT_CryptHash.c file from API_CryptHash.zip.  Running ./kat generates the
    required KAT_2_12, KAT_2_23, KAT_2_33, and KAT_Loop files into output/.

  drng.c / drng.h
    Deterministic random/message generator used by the KAT generator.

  quick_test.c
    Small self-test executable source for build and correctness smoke testing.

  hash_cli.c
    Command-line hashing utility for manual testing.

  benchmark.c
    Single-message benchmark driver.

  profile_info.c
    Instance/profile metadata printer used by benchmark tooling.

  README.txt
    Per-instance summary and quick build notes.

Specification utility scripts
-----------------------------
The S6 constant-regeneration and algebra-check Python scripts explicitly named
in the algorithm specification are placed in the project-level tools/ directory:

  ../tools/gen_s6_iv.py
    Re-derives the three S6 IV constant sets from the documented FNV-1a64 +
    SplitMix64 domain strings.

  ../tools/check_round_constants.py
    Regenerates the public RC32(round,lane) SplitMix64 schedule for the
    12/20/24-round S6 profiles and verifies that constants are non-zero and
    collision-free within each profile.

  ../tools/check_s6_algebra.py
    Performs lightweight algebra sanity checks for GF(32), the Cauchy MDS
    matrix, pi_AFS, and the per-lane mu diffusion.

Run these scripts from the project root as:
  python3 tools/gen_s6_iv.py
  python3 tools/check_round_constants.py
  python3 tools/check_s6_algebra.py

Optimized_Implementation instance files
---------------------------------------
Each of Optimized_Implementation/AFS-TrEDM-{512,768,1024}/ contains:

  Makefile
    Automated optimized build script.  Targets include all, clean, kat,
    run-quick, run-benchmark, AVX2 build/test/benchmark targets, dispatch
    targets, and performance-profile variants.  The kat target builds the ICCS
    KAT_CryptHash.c helper; running ./kat generates all four required KAT
    files into output/.

  CryptHash_AlgorithmInstance.c / CryptHash_AlgorithmInstance.h
    ICCS CryptHash API wrapper and instance configuration.

  afs_tredm.c / afs_tredm.h
    Optimized aligned TrEDM mode implementation.

  afs_p1600.c / afs_p1600.h
    Portable optimized permutation backend.

  afs_p1600_avx2.c
    AVX2 hybrid permutation backend used by explicit AVX2 targets.

  afs_sbox64.c / afs_sbox64.h
    Optimized AFS64_t5_k2 S-box implementation and prototypes.

  KAT_CryptHash.c
    KAT generator compatible with the ICCS CryptHash API and the same selectors
    as the reference implementation.

  drng.c / drng.h
    Deterministic random/message generator for KAT generation.

  quick_test.c
    Optimized implementation smoke test.

  hash_cli.c
    Command-line hashing utility.

  benchmark.c
    Benchmark driver for optimized, AVX2, and performance-profile builds.

  microbench_rounds.c
    Microbenchmark driver for per-round/permutation profiling.

  profile_info.c
    Instance/profile metadata printer.

  kat_2_33_stream.c
    Streaming helper for 2^33-bit KAT handling where present.

  README.txt
    Per-instance summary and quick build notes.

Optimized_Implementation shared files
-------------------------------------
  common/s6/afs_lmds1600_s6_opt64.c
    Shared opt64 implementation of the AFS-LMDS-1600-S6 linear layer.

  common/s6/afs_lmds1600_s6_opt64.h
    Header for the shared opt64 S6 linear layer.

  common/s6/microbench_rounds.c
    Shared microbenchmark support for S6 round profiling.

  common/s6/generated/afs_lmds_s6_round_0.inc ... afs_lmds_s6_round_5.inc
    Generated S6 linear-layer round include files used by the opt64 backend.

  common/dispatch/afs_dispatch.c
    Runtime dispatch helper for portable/AVX2 CryptHash backend selection.

  common/dispatch/afs_dispatch.h
    Dispatch helper header.

  common/dispatch/dispatch_quick_test.c
    Dispatch-path smoke test.

  common/low/batch_multibuffer_common/CryptHash_Batch.c
    Batch API implementation shared by Batch_Multibuffer instance Makefiles.

  common/low/batch_multibuffer_common/CryptHash_Batch.h
    Batch API header.

  common/low/batch_multibuffer_common/batch_quick_test.c
    Batch API quick test.

  common/low/batch_multibuffer_common/batch_benchmark.c
    Batch API benchmark driver.

  common/low/batch_multibuffer_common/batch_hardening_test.c
    Batch API hardening/edge-case test driver.

  common/low/batch_multibuffer_common/afs_batch16_s6_avx512.c
    AVX512 Batch16 S6 true hot path for same-length byte-aligned 16-wide input.

  common/low/batch_multibuffer_common/afs_batch16_s6_avx512.h
    AVX512 Batch16 S6 backend header.

  common/low/batch_multibuffer_common/batch16_avx512_selftest.c
    AVX512 Batch16 self-test source.

  common/low/batch_multibuffer_common/generated/afs_batch16_rc.inc
    Generated round-constant include file for Batch16 AVX512.

  common/low/batch_multibuffer_common/generated/afs_s6_batch16_r0.inc
  common/low/batch_multibuffer_common/generated/afs_s6_batch16_r1.inc
  common/low/batch_multibuffer_common/generated/afs_s6_batch16_r2.inc
  common/low/batch_multibuffer_common/generated/afs_s6_batch16_r3.inc
  common/low/batch_multibuffer_common/generated/afs_s6_batch16_r4.inc
  common/low/batch_multibuffer_common/generated/afs_s6_batch16_r5.inc
    Generated S6 Batch16 AVX512 round include files.

Additional_Implementation files
-------------------------------
  Additional_Implementation/README.txt
    Overview of optional additional implementations.

  Additional_Implementation/Batch_Multibuffer/README.txt
    Overview of the optional Batch_Multibuffer implementation.

  Additional_Implementation/Batch_Multibuffer/AFS-TrEDM-{512,768,1024}/Makefile
    Per-instance build script for batch/multibuffer quick tests and benchmarks.
    The Makefile reuses optimized common sources via relative paths.

  Additional_Implementation/Batch_Multibuffer/AFS-TrEDM-{512,768,1024}/README.txt
    Per-instance batch implementation notes.

Build and quick test
--------------------
Run from the package root:

  for b in 512 768 1024; do
    make -C Implementations/Reference_Implementation/AFS-TrEDM-$b clean all
    make -C Implementations/Reference_Implementation/AFS-TrEDM-$b run-quick

    make -C Implementations/Optimized_Implementation/AFS-TrEDM-$b clean all \
      quick_test_avx2 hash_cli_avx2 benchmark_avx2
    make -C Implementations/Optimized_Implementation/AFS-TrEDM-$b run-quick
    ./Implementations/Optimized_Implementation/AFS-TrEDM-$b/quick_test_avx2

    make -C Implementations/Additional_Implementation/Batch_Multibuffer/AFS-TrEDM-$b \
      clean all-portable
    make -C Implementations/Additional_Implementation/Batch_Multibuffer/AFS-TrEDM-$b \
      run-quick-batch16-avx512
  done

On hosts without AVX512F, the guarded Batch16 AVX512 run target may skip rather
than execute the AVX512 binary.  Use the Makefile run target or the full
executable path; do not invoke quick_test_batch16_avx512 from the package root
without its relative path.

KAT generation from implementation directories
----------------------------------------------
The KAT generator can be built and run per instance:

  make -C Implementations/Reference_Implementation/AFS-TrEDM-512 clean kat
  (cd Implementations/Reference_Implementation/AFS-TrEDM-512 && ./kat)

With no selector, ./kat writes KAT_2_12_AFS-TrEDM-512.txt,
KAT_2_23_AFS-TrEDM-512.txt, KAT_2_33_AFS-TrEDM-512.txt, and
KAT_Loop_AFS-TrEDM-512.txt into that instance's output/ directory.  The same
pattern applies to AFS-TrEDM-768 and AFS-TrEDM-1024.  Selectors 2_12, 2_23,
2_33, and loop may be used for individual files.
