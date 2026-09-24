# TRIKE Implementations

This repository provides two versions of the TRIKE KEM code:

- `Reference_Implementation/`: reference implementation code without platform-specific instruction-set dependencies.
- `Optimized_Implementation/`: optimized implementation for mainstream 64-bit PC processors.
- `Additional_Implementation/`: placeholder for additional implementations (e.g., hardware implementations) to be added in the future. 

Both versions include the same parameter-set folders:

- `TRIKE-2/`
- `TRIKE-5/`
- `TRIKE-7/`
- `TRIKE-9/`

*Note: While the TRIKE specification covers six parameter sets (TRIKE-1/2/3/5/7/9), this repository focuses exclusively on TRIKE-2/5/7/9 to meet the specific requirements of the Institute of Commercial Cryptography Standards (ICCS) submission. The NIST-specific variants (TRIKE-1/3) are not included here.*

## Common Folder Layout (per `TRIKE-x/`)

- `CMakeLists.txt`: build configuration for this parameter set.
- `ICCS/`: auxiliary functions provided by the Institute of Commercial Cryptography Standards (ICCS).
	- `drng.c`: source file of Deterministic Random Number Generator.
	- `drng.h`: header file of Deterministic Random Number Generator.
	- `auxfunc.c`: source file of auxiliary functions.
	- `auxfunc.h`: header file of auxiliary functions.
- `src/`: core TRIKE KEM source code.
	- `KEM_AlgorithmInstance.c`: source file of KEM algorithm instance.
	- `KEM_AlgorithmInstance.h`: header file of KEM algorithm instance.
	- `decoder.c`: source file of decoding routines.
	- `decoder.h`: header file of decoding routines.
	- `gf2x.c`: source file of GF2X polynomial operations.
	- `gf2x.h`: header file of GF2X polynomial operations.
	- `sample.c`: source file of sampling routines.
	- `sample.h`: header file of sampling routines.
	- `trike_params.h`: header file of parameter definitions.
	- `trike_types.h`: header file of shared data types.
- `tests/`: test code provided by ICCS.
	- `KAT_KEM.c`: source file for generating test vector files of key encapsulation mechanism (KEM) scheme.