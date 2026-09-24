AFS-TrEDM Additional_Implementation
===================================

This directory contains optional implementations beyond the required
Reference_Implementation and Optimized_Implementation trees.

Layout:

    Batch_Multibuffer/
        Optional PC software batch/multi-buffer implementation.  It provides
        CryptHash_Batch4(), CryptHash_Batch8(), CryptHash_Batch16(), and
        CryptHash_BatchMany() entry points for throughput-oriented workloads.
        Batch4, Batch8, BatchMany, mixed-length Batch16, and non-byte-aligned
        Batch16 inputs dispatch through scalar CryptHash() fallback.
        AVX512 Batch16 builds additionally provide the submitted true hot path
        for same-length byte-aligned 16-wide inputs in all three S6 instances.

Current submitted additional implementations:

    Batch_Multibuffer

The submitted batch behavior is:

- Batch16 AVX512 true path for same-length byte-aligned 16-wide messages.
- Batch4, Batch8, BatchMany, mixed-length Batch16, and non-byte-aligned
  Batch16 use scalar CryptHash() fallback.

Unsupported inputs fall back to the standard CryptHash() API lane by lane,
preserving bit-level correctness.
