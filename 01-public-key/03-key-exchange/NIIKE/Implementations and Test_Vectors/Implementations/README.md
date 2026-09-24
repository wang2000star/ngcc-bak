# NIIKE

This repository contains the reference implementation, optimized implementation, and additional AVX-512IFMA-based implementation of NIIKE. The build system uses CMake.

## Building

Enter the directory of the implementation you wish to build, then run:
```
$ mkdir -p build
$ cd build
$ cmake ..
$ make
```

## Project Structure

Code shared across all algorithm instances resides in the root of the implementation directory, while instance-specific code is placed in the corresponding algorithm instance subdirectory.

- `common`: common code for the PRNG and machine word-size detection
- `gf`: GF(p²) and GF(p) arithmetic
- `ec`: elliptic curves and isogenies
- `precomp`: constants and precomputed values
- `protocols`: key exchange protocol implementations
- `ngccapi`: programming interface provided by the Institute of Commercial Cryptography Standards

## Known Answer Tests (KAT)

To generate the KATs, run the following compiled program:
```
build/NIIKE-<level>/ngccapi/KAT_KEX_NIKKE-<level>
```