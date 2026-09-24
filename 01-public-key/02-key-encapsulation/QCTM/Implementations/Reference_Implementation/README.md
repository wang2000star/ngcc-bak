# QCTM reference implementation

This directory contains the reference implementation for QCTM128, QCTM256, and
QCTM512.

Each parameter-set directory includes the `KEM_AlgorithmInstance.c` and
`KEM_AlgorithmInstance.h` adapter files for the official `API_PKC.zip` KEM KAT
interface.

The KEM KAT files in `../../Test_Vectors/` are generated with the same
`API_PKC.zip` interface and match the optimized implementation outputs.
