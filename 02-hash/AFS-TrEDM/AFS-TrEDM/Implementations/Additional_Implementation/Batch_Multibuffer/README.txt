AFS-TrEDM Batch_Multibuffer Additional Implementation
=====================================================

This optional additional implementation provides batch/multi-buffer software
APIs and benchmarks. It does not replace the standard ICCS CryptHash() API.
Batch4, Batch8, BatchMany, mixed-length Batch16, and non-byte-aligned Batch16
inputs use scalar CryptHash() fallback. Batch scalar fallback is a
compatibility path. AVX512 Batch16 builds additionally provide a true 16-wide
hot path for same-length byte-aligned inputs. Batch16 AVX512 norm is the
true 16-way AVX512 multi-buffer throughput backend.
Batch16 AVX512 norm values are multi-buffer throughput normalized per message byte.
They are not single-message latency.

Default submitted targets per instance:

    make run-quick
    make run-benchmark
    make run-quick-batch16-avx512
    make run-benchmark-batch16-avx512

Default Batch_Multibuffer Makefiles build the backend through:

    Implementations/Optimized_Implementation/common/low/batch_multibuffer_common

Historical measurement and rejected/research targets are not part of the active
submission package.

The common/ directory here contains compatibility wrappers only. The physical
backend source is maintained in the optimized low-level backend tree to avoid
symlink-dependent packages and duplicated backend code.
