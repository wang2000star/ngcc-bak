MAMBA-NIKE-384 AVX2 Optimized Implementation
================================================

This directory implements the same protocol, parameters, serialization, and KAT
outputs as the matching Reference profile.

AVX2 path
---------
When AVX2 is enabled, protocol products with one centered-binomial operand use
poly_mul_small().  The routine uses fixed public loops, fixed addresses, four
16-lane accumulators, exact modulo-2^16 lane wraparound, and one final q-1 mask.
It does not skip zero coefficients.  The build also links the submitted AVX2
ChaCha20 assembly.

Portable fallback
-----------------
When AVX2 is disabled, the same source falls back to coefficient-domain
Toom-Cook-4.

Build and run
-------------
  make clean && make AVX2=1
  ./KAT_KEX

  make clean && make AVX2=0
  ./KAT_KEX

Profile constants
-----------------
  n=2048, q=8192, eta=2, (t_pk,t_u,t_v)=(11,11,6)
  pk=2848 bytes, sk=6944 bytes, M1=3360 bytes, ss=48 bytes

The raw KAT output must match the canonical Reference vector byte for byte.
parameters.json and params.h are not modified by this optimization.
