PolarLAC MLWE Optimized Implementation for x86
==============================================

This directory contains the optimized x86 implementations for the five
submitted PolarLAC MLWE KEM parameter sets.  The optimized instances preserve
the same API_PKC interface and data formats as the reference x86 instances,
while using AVX2 helpers for sampling, polynomial processing, NTT arithmetic,
and packing paths where applicable.

Directory mapping
-----------------

POLARLAC-Light     128-bit-light profile, q = 257, N = 256, K = 2.
POLARLAC-128       128-bit profile, q = 257, N = 256, K = 2.
POLARLAC-256       256-bit profile, q = 257, N = 512, K = 2.
POLARLAC-512       512-bit profile, q = 257, N = 1024, K = 2.
POLARLAC-512-Star  512-Star profile, q = 769, N = 1024, K = 2.

Parameter and data-format summary
---------------------------------

Instance           pk_seed  msg/ss  pk     sk     ct    c1 format                 c2 format
POLARLAC-Light     16       16      530    1570   608   byte-truncated u_coeff    3-bit packed v
POLARLAC-128       16       16      530    1570   640   byte-truncated u_coeff    4-bit packed v
POLARLAC-256       32       32      1060   3140   1280  byte-truncated u_coeff    4-bit packed v
POLARLAC-512       64       64      2116   6276   2560  byte-truncated u_coeff    4-bit packed v
POLARLAC-512-Star  64       64      2522   6682   2970  CRT-packed u_ntt          4-bit packed v

All sizes in the table are byte lengths.  The secret key format is
sk_KEM = raw_s_ntt_vec || pk || z, where z has KEM_REJECT_SEED_BYTES =
PKE_MESSAGE_BYTES.  The PKE secret key stores the raw NTT-domain secret vector
as int16_t coefficients and is not compressed.

Algorithm mapping
-----------------

KEM_AlgorithmInstance.c implements the FO KEM wrapper:
key generation, encapsulation, decapsulation, full-length ciphertext
comparison, and constant-time selection between ss_valid and ss_reject.

pke.c implements the MLWE PKE layer:
KeyGen computes b_ntt = A * s_ntt + e_ntt, Encrypt computes
u = A^T * r + e1 and v = b^T * r + e2 + Encode(m), and Decrypt recovers
m from v - <u, s>.  Light, 128, 256, and 512 transmit coefficient-domain c1;
512-Star transmits CRT-packed multiplication-domain c1.

sample.c implements GenA and ternary noise sampling.  The ternary
distributions are:
POLARLAC-Light and POLARLAC-256: {-1:1/8, 0:3/4, 1:1/8}.
POLARLAC-128 and POLARLAC-512-Star: {-1:3/16, 0:5/8, 1:3/16}.
POLARLAC-512: {-1:11/128, 0:106/128, 1:11/128}.
POLARLAC-512 uses FFT-domain rejection threshold RL_KEM_T = 1849.

poly.c implements public-key compression, c1/c2 serialization, and d-bit c2
packing.  Light, 128, 256, and 512 use fixed zero selector for pk.  512-Star
uses CRT packing for pk and c1.

Optimized NTT files
-------------------

The optimized NTT source and header files are:
ntt.c, ntt.h, ntt_avx2.c, ntt_avx2.h, ntt_avx2_params.h, and ntt_tables.c.
Each optimized NTT file has a copyright header in the project format with
author Ying Liu.

Build and KAT
-------------

Run make in a parameter-set directory on an x86-64 machine with AVX2 support.
The Makefiles default to BIT_USE_SHAKE=0 and can be built with BIT_USE_SHAKE=1
when SHAKE is required.

The submitted optimized test vectors are stored under:
../../../Test_Vector/Optimized_Implementation/x86/

API_PKC template notes
----------------------

Each parameter-set directory keeps the API_PKC template README.txt.  The files
drng.c, drng.h, auxfunc.c, auxfunc.h, and KAT_KEM.c are template files and
should not be modified.  The submitted KEM interface is implemented in
KEM_AlgorithmInstance.c and declared in KEM_AlgorithmInstance.h, with
OUTPUT_BLANK_TEST_VECTORS set to 0 and ALGORITHM_INSTANCE set to the directory
name.
