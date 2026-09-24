# QCTM Implementations

This directory contains the source-code implementations submitted for the QCTM KEM.

- `Reference_Implementation/`: portable reference implementation.
- `Optimized_Implementation/`: x86-oriented optimized implementation used for the final KAT and performance checks.

Both implementation directories include the `QCTM128`, `QCTM256`, and `QCTM512` parameter sets. Each parameter-set directory provides the KEM API adapter files (`api.h`, `KEM_AlgorithmInstance.c`, and `KEM_AlgorithmInstance.h`) together with the scheme source files and the CryptHash adapter files used by the implementation.

The final Known Answer Test files are provided in `../Test_Vectors/`.
