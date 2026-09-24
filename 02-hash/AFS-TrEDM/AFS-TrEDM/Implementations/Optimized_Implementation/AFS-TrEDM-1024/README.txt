AFS-TrEDM optimized implementation for AFS-TrEDM-1024
=====================================================

This directory contains the optimized implementation for mainstream 64-bit PC
processors.  It preserves the ICCS CryptHash() API and produces bit-identical
outputs to the reference implementation.

Implemented optimization layers:

1. Portable opt64, the generated scalar optimized S6 target and default
   non-SIMD optimized target.
   - uint64_t lane-contiguous state A[25];
   - precomputed public round/lane constants cropped to the instance profile;
   - inlined and unrolled AFS-64 ARX lane operation;
   - unrolled g/h split: 12 + 12 rounds;
   - direct word-level absorption for full rate blocks;
   - no dynamic memory allocation in CryptHash() or the hash core.

2. Canonical AVX2 hybrid target, exposed as benchmark_avx2 / quick_test_avx2.
   - built with AVX2 flags selected by the Makefile;
   - uses the canonical S6 single-message path: AVX2 AFS-64 S-box + opt64 S6
     linear;
   - keeps the same ICCS CryptHash() API and bit-level output as reference
     and portable opt64.

3. Measurement and regression targets.
   - Historical AVX2/AVX512 pre-S6 candidates are not included in this
     cleaned submission package and are not active submission hot paths.

Main build commands:
  make clean && make
  ./quick_test
  ./benchmark --quick
  ./benchmark --full

Canonical AVX2 hybrid commands:
  make clean && make quick_test_avx2 hash_cli_avx2 benchmark_avx2
  ./quick_test_avx2
  ./benchmark_avx2 --quick
  ./benchmark_avx2 --full
  make profile_info_avx2 microbench_rounds microbench_rounds_opt64
  ./profile_info_avx2
  ./microbench_rounds --full

The canonical AVX2 hybrid backend is intentionally reported as
  sbox_backend=avx2
  linear_backend=opt64-s6
because Stage S6-02B did not adopt a single-message AVX2 S6 linear layer.

The S6 linear layer is a lane-major 25 x 64-bit linear layer built from a
bitsliced GF(32) Cauchy MDS, AFS lane rotation, a 1+24 long-cycle lane
permutation, per-lane invertible diffusion, and six projective directions.

The optimized implementation must produce the same digest and KAT files as the
reference implementation.
