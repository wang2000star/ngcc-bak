# Implementations

The submitted scalar builds are under `Reference_Implementation`, one complete
directory per MAMBA-Frost and MAMBA-Frost-CC parameter set.

The AVX2/AES-NI builds are under `Optimized_Implementation`, also one complete
directory per parameter set. Those directories use the official API_PKC KEM
interface but compile Frost's `_FAST_` path and optimized source files. The
optimized sources are not copied into or built from `Reference_Implementation`.

Both implementation families route Frost/Frost-CC `shake128`/`shake256` call
sites to the official API_PKC `pseudoXOF()` auxiliary function through the local
`common/sha3/fips202.c` adapter included in each instance directory.

`Additional_Implementation` remains a placeholder for future non-reference,
non-AVX2 implementations.
