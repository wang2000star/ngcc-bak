This repository contains reference and optimized implementations of the CHIME cryptographic hash algorithm family (CHIME-512 and CHIME-1024), along with known-answer test (KAT) vectors.

1. Top-Level Structure
-------------------

Implementations/

	Additional_Implementation/

	Optimized_Implementation/
		Contains performance-oriented C/C++ implementations and test/benchmark programs.

		CHIME-512/
			Optimized CHIME-512 implementation package.

			- chime512.cpp
				Core optimized CHIME-512 hashing implementation.
			- chime512.hpp
				Public declarations and constants for CHIME-512 optimized hashing.
			- CryptHash_AlgorithmInstance.c
				C API adapter that exposes the standardized CryptHash entry for CHIME-512.
			- CryptHash_AlgorithmInstance.h
				API definitions/macros for algorithm instance name, digest length, and CryptHash prototype.
			- drng.c
				Deterministic random number generator implementation used by KAT generation.
			- drng.h
				Header for DRNG context and function declarations.
			- KAT_CryptHash.c
				Test-vector generator program for producing KAT output files.
			- main.cpp
				Correctness test program that verifies optimized CHIME-512 against reference vectors.
			- makefile
				Build rules for test, benchmark, and vector-generation binaries.
			- P.cpp
				Optimized permutation round implementation used internally by CHIME-512.
			- P.hpp
				Permutation state/type/macro declarations for optimized round functions.
			- sha_openssl.h
				OpenSSL-based SHA helper wrappers used for comparison/testing.
			- sha512.cpp
				Manual SHA-512 implementation used by benchmark utilities.
			- sha512.h
				Header for manual SHA-512 helper functions/classes.
			- throughput.cpp
				Throughput benchmark program for CHIME-512 and SHA-512 comparisons.

		CHIME-1024/
			Optimized CHIME-1024 implementation package.

			- chime1024.cpp
				Core optimized CHIME-1024 hashing implementation.
			- chime1024.hpp
				Public declarations and constants for CHIME-1024 optimized hashing.
			- CryptHash_AlgorithmInstance.c
				C API adapter that exposes the standardized CryptHash entry for CHIME-1024.
			- CryptHash_AlgorithmInstance.h
				API definitions/macros for algorithm instance name, digest length, and CryptHash prototype.
			- drng.c
				Deterministic random number generator implementation used by KAT generation.
			- drng.h
				Header for DRNG context and function declarations.
			- KAT_CryptHash.c
				Test-vector generator program for producing KAT output files.
			- main.cpp
				Correctness test program that verifies optimized CHIME-1024 against reference vectors.
			- makefile
				Build rules for test, benchmark, and vector-generation binaries.
			- P.cpp
				Optimized permutation round implementation used internally by CHIME-1024.
			- P.hpp
				Permutation state/type/macro declarations for optimized round functions.
			- sha_openssl.h
				OpenSSL-based SHA helper wrappers used for comparison/testing.
			- sha512.cpp
				Manual SHA-512 implementation used by benchmark utilities.
			- sha512.h
				Header for manual SHA-512 helper functions/classes.
			- throughput.cpp
				Throughput benchmark program for CHIME-1024 and SHA-512 comparisons.

	Reference_Implementation/
		Contains baseline/reference C implementations intended for correctness and KAT generation.

		CHIME-512/
			Reference CHIME-512 implementation package.

			- CryptHash_AlgorithmInstance.c
				Reference implementation of the CHIME-512 hashing logic behind the standard API.
			- CryptHash_AlgorithmInstance.h
				API interface and configuration macros for the reference CHIME-512 instance.
			- KAT_CryptHash.c
				Program that generates KAT files using the reference CHIME-512 implementation.
			- README.txt
				Local instructions for modifying/building/running the reference submission package.
			- drng.c
				Deterministic random number generator implementation required by KAT generation.
			- drng.h
				Header for DRNG declarations and context structure.
			- makefile
				Build script to compile and run the reference KAT generator.

		CHIME-1024/
			Reference CHIME-1024 implementation package.

			- CryptHash_AlgorithmInstance.c
				Reference implementation of the CHIME-1024 hashing logic behind the standard API.
			- CryptHash_AlgorithmInstance.h
				API interface and configuration macros for the reference CHIME-1024 instance.
			- KAT_CryptHash.c
				Program that generates KAT files using the reference CHIME-1024 implementation.
			- README.txt
				Local instructions for modifying/building/running the reference submission package.
			- drng.c
				Deterministic random number generator implementation required by KAT generation.
			- drng.h
				Header for DRNG declarations and context structure.
			- makefile
				Build script to compile and run the reference KAT generator.

Test_Vector/
	Contains generated known-answer test vectors for both algorithm variants.

	- KAT_2_12_CHIME-1024.txt
		CHIME-1024 digests for message lengths from 0 to 2^12 bits.
	- KAT_2_12_CHIME-512.txt
		CHIME-512 digests for message lengths from 0 to 2^12 bits.
	- KAT_2_23_CHIME-1024.txt
		CHIME-1024 digest for a 2^23-bit message.
	- KAT_2_23_CHIME-512.txt
		CHIME-512 digest for a 2^23-bit message.
	- KAT_2_33_CHIME-1024.txt
		CHIME-1024 digest for a 2^33-bit message.
	- KAT_2_33_CHIME-512.txt
		CHIME-512 digest for a 2^33-bit message.
	- KAT_Loop_CHIME-1024.txt
		CHIME-1024 loop-test output (iterative chaining test).
	- KAT_Loop_CHIME-512.txt
		CHIME-512 loop-test output (iterative chaining test).

2. Build and Binary Outputs
------------------------

Dependency note for optimized builds:
- The makefile in both optimized directories links against OpenSSL libcrypto (`-lcrypto`).
- Please install OpenSSL development files before running `make`.
- On Debian/Ubuntu: `sudo apt-get install libssl-dev`
- On RHEL/CentOS/Fedora: `sudo dnf install openssl-devel` (or `sudo yum install openssl-devel`)

Implementations/Optimized_Implementation/CHIME-512/
	Build commands:
	- make
	- Optional targets: make test, make bench, make gen_test_vecs, make clean

	Produced binaries:
	- test
		Runs correctness verification for optimized CHIME-512 against known vectors.
	- bench
		Runs throughput benchmarks for CHIME-512 and SHA-512 helpers.
	- gen_test_vecs
		Generates KAT vector files via the standardized CryptHash/DRNG flow.

Implementations/Optimized_Implementation/CHIME-1024/
	Build commands:
	- make
	- Optional targets: make test, make bench, make gen_test_vecs, make clean

	Produced binaries:
	- test
		Runs correctness verification for optimized CHIME-1024 against known vectors.
	- bench
		Runs throughput benchmarks for CHIME-1024 and SHA-512 helpers.
	- gen_test_vecs
		Generates KAT vector files via the standardized CryptHash/DRNG flow.

Implementations/Reference_Implementation/CHIME-512/
	Build commands:
	- make
	- Optional targets: make run, make clean

	Produced binaries:
	- gen_test_vecs
		Generates reference KAT vector files (2^12, 2^23, 2^33, and loop test outputs).

Implementations/Reference_Implementation/CHIME-1024/
	Build commands:
	- make
	- Optional targets: make run, make clean

	Produced binaries:
	- gen_test_vecs
		Generates reference KAT vector files (2^12, 2^23, 2^33, and loop test outputs).
