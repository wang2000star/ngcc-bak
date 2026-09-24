MAMBA-NIKE — NGCC API Implementations
=====================================

This API_PKC package contains five one-pass KEX instances.  Each instance
has a portable Reference implementation and an x86-64 Optimized implementation.

Quick Start
-----------
  # Canonical Reference KATs for all five profiles
  bash generate_all_kats.sh

  # One optimized AVX2 instance
  cd Implementations/Optimized_Implementation/MAMBA-NIKE-128
  make clean && make AVX2=1
  ./KAT_KEX

  # Portable fallback from the same optimized source
  make clean && make AVX2=0

Arithmetic
----------
  Reference multiplication: Toom-Cook-4 negacyclic convolution.
  AVX2 multiplication:      fixed-loop 16-lane poly_mul_small() accumulation.
  Reduction:                final mask by q-1, q=8192.

The AVX2 path preserves the Reference byte layout and KAT output.  It has
fixed public loop bounds, fixed memory-access positions, and does not skip
zero coefficients.  parameters.json and all params.h files are frozen and
are not changed by this optimization.

Canonical Files
---------------
  KAT/MAMBA-NIKE-*/PQCkexKAT_*.req
  KAT/MAMBA-NIKE-*/PQCkexKAT_*.rsp
  Test_Vectors/KAT_KEX_MAMBA-NIKE-*.txt
  KAT_MANIFEST.sha256
