AFS-TrEDM-512 Additional Batch Implementation
=============================================

This directory builds optional multi-buffer entry points for AFS-TrEDM-512:

- CryptHash_Batch4()
- CryptHash_Batch8()
- CryptHash_Batch16() on AVX512 builds
- CryptHash_BatchMany()

The standard ICCS CryptHash() API remains unchanged. Batch4, Batch8, BatchMany,
mixed-length Batch16, and non-byte-aligned Batch16 inputs use scalar
CryptHash() fallback. Batch scalar fallback is a compatibility path. AVX512
Batch16 builds additionally provide a true 16-wide hot path for same-length
byte-aligned inputs. Batch16 AVX512 true is the 16-way multi-buffer throughput
backend. Batch16 AVX512 values are multi-buffer throughput normalized per
message byte. They are not single-message latency.

Default submitted build/test targets:

    make clean
    make run-quick
    make run-benchmark
    make run-quick-batch16-avx512
    make run-benchmark-batch16-avx512

The default Makefile compiles shared batch backend sources from:

    ../../../Optimized_Implementation/common/low/batch_multibuffer_common

Historical measurement targets are not part of the default submitted build
surface or active submission package.
