AFS_KEX_C128 Reference Implementation Bundle

This directory is a self-contained ISO C reference implementation bundle for
the AFS_KEX_C128 KEX instance.

File summary

  KEX_AlgorithmInstance.h/.c
      ICCS KEX programming interface and AFS_KEX_C128 wrapper implementation

  auxfunc.c/.h
      ICCS auxiliary hash and XOF helper functions

  drng.c/.h
      ICCS deterministic random number generator used by KAT and wrappers

  KAT_KEX.c
      ICCS KAT driver for key exchange protocols

  params.h, kem.*, indcpa.*, poly.*, polyvec.*, BWcoding.*
      AFS_KEX_C128 reference implementation core

  cbd.*, ntt.*, reduce.*, verify.*
      Arithmetic, sampling, and support modules required by the reference core

  symmetric.h, symmetric-iccs.c
      Symmetric abstraction and ICCS auxiliary-function backend

Build and KAT generation

  make
      Build the local KAT executable under build/

  make kat
      Generate the KAT file and copy it to:
      ../../../Test_Vector/KAT_KEX_AFS_KEX_C128.txt

  make clean
      Remove local build artifacts

Important notes

1.  This bundled implementation is KEX-only.
2.  The bundle uses the ICCS KEX programming interface in KEX_AlgorithmInstance.h.
3.  Hash and XOF calls used by the bundled implementation are routed through
    ICCS auxiliary functions in auxfunc.c/.h.
4.  This program assumes a little-endian byte order for multi-byte values.
5.  This program requires compilation with a C99-compatible compiler or later.
