************************************Overview***********************************

SQISign2Dsquare is a digital signature scheme based on isogenies between
products of supersingular elliptic curves. This submission contains eight
algorithm instances covering Level1, Level2, Level3, and Level5 parameter
sets, with efficiency-oriented ("eff") and security-oriented ("sec") variants
at each level.

Each algorithm instance is provided as a separate directory, following the
required [AlgorithmInstance] directory layout. Both compressed and uncompressed
signature formats are supported in the same instance directory and are selected
through "config.h".

The reference implementation is written in ISO C and is intended to avoid
processor-specific instruction-set dependencies. The optimized implementation
keeps the same high-level signing, verification, and key-generation flow, while
using optimized finite-field and Fp2 arithmetic in the parameter-specific
"ec_arithmetic" directory.

This is a SIG-only submission. KEM and KEX implementations are not included.

*******************Submission Layout and File Description********************

This submission implements the digital signature algorithm SQISign2Dsquare.
It provides one reference implementation and one optimized implementation for
each algorithm instance.

Top-level directory:

    README.txt
        This file. It describes the implementation layout, build commands,
        configuration switches, and submission notes.

    Reference_Implementation/
        ISO C reference implementations. These implementations do not contain
        assembly source files and are intended to be independent of specific
        processor instruction sets.

    Optimized_Implementation/
        Optimized implementations for mainstream 64-bit PC processors. The
        finite-field and Fp2 arithmetic in "ec_arithmetic" uses handwritten
        assembly routines where available.

Algorithm instance directories:

    Reference_Implementation/SQISign2Dsquare-Level1-eff/
    Reference_Implementation/SQISign2Dsquare-Level1-sec/
    Reference_Implementation/SQISign2Dsquare-Level2-eff/
    Reference_Implementation/SQISign2Dsquare-Level2-sec/
    Reference_Implementation/SQISign2Dsquare-Level3-eff/
    Reference_Implementation/SQISign2Dsquare-Level3-sec/
    Reference_Implementation/SQISign2Dsquare-Level5-eff/
    Reference_Implementation/SQISign2Dsquare-Level5-sec/

    Optimized_Implementation/SQISign2Dsquare-Level1-eff/
    Optimized_Implementation/SQISign2Dsquare-Level1-sec/
    Optimized_Implementation/SQISign2Dsquare-Level2-eff/
    Optimized_Implementation/SQISign2Dsquare-Level2-sec/
    Optimized_Implementation/SQISign2Dsquare-Level3-eff/
    Optimized_Implementation/SQISign2Dsquare-Level3-sec/
    Optimized_Implementation/SQISign2Dsquare-Level5-eff/
    Optimized_Implementation/SQISign2Dsquare-Level5-sec/

The following file description applies to each algorithm instance directory.
Files with the same name have the same role in the reference and optimized
implementations unless explicitly noted.

    config.h
        Build-time configuration file. The macro COMPRESSED selects the
        uncompressed signature format (0) or compressed signature format (1).

    sqisign/Makefile
        Automated build script. It builds the demonstration program, the KAT
        generator, and, in the optimized implementation, the finite-field
        benchmark program.

    sqisign/SIG_AlgorithmInstance.h
        Public programming interface required by the submission API. It defines
        OUTPUT_BLANK_TEST_VECTORS, ALGORITHM_INSTANCE, key sizes, signature
        sizes, and the SIG API function prototypes.

    sqisign/SIG_AlgorithmInstance.c
        API adapter implementing the required SIG interface by calling the
        SQISign2Dsquare key generation, signing, and verification routines.

    sqisign/KAT_SIG.c
        Provided SIG known-answer-test driver. It generates deterministic KAT
        files using the provided DRNG and the SIG API.

    sqisign/keygen.c
        SQISign2Dsquare key generation implementation.

    sqisign/sign.c
        SQISign2Dsquare signature generation and verification implementation.

    sqisign/sqisigndim2.h
        Internal SQISign2Dsquare signing interface and data structures.

    sqisign/test_sqisigndim2.c, sqisign/test_sqisigndim2.h
        Functional and performance test program for key generation, signing,
        and verification.

    sqisign/bench_fp.c
        Optimized implementation only. Benchmark program for low-level finite
        field arithmetic.

    ec_arithmetic/
        Parameter-specific arithmetic and constants. It contains finite-field
        implementation files, extension-field constants, torsion constants,
        quaternion data, and endomorphism-action data. In the optimized
        implementation it also contains the handwritten assembly arithmetic
        files named "fp*_asm.S" and "fp2*_asm.S".

    ec_arithmetic/include/
        Parameter-specific finite-field headers generated or selected for the
        corresponding prime.

    fp.c, fp.h
        Common prime-field wrapper used by the higher-level code. It dispatches
        to the parameter-specific implementation in "ec_arithmetic".

    fp2.c, fp2.h
        Quadratic extension-field arithmetic used by elliptic-curve and
        isogeny routines.

    fp_portable.h
        Portable helper routines for finite-field multiplication on platforms
        where a 64-by-64-to-128-bit multiplication type is unavailable.

    ec.c, ec.h, curve_extras.h
        Elliptic-curve data structures and operations.

    dim2.c, dim2id2iso.c, dim2id2iso.h, dim4.c
        Dimension-2 and dimension-4 isogeny support routines.

    theta_structure.c, theta_structure.h
        Theta-structure data structures and operations.

    theta_isogenies.c, theta_isogenies.h
        Theta-isogeny construction and evaluation routines.

    xeval.c, xisog.c, isog_chains.c, isog.h
        Isogeny evaluation, isogeny construction, and isogeny-chain routines.

    basis.c, biextension.c, biextension.h
        Torsion-basis and biextension helper routines.

    pack.c
        Serialization and deserialization of public keys, secret keys, and
        signatures.

    intbig.c, intbig.h, integers.c, mp.c, mp.h
        Integer, multiprecision, and conversion utilities.

    quaternion.h, ideal.c, lattice.c, lll.c, matkermod.c
        Quaternion-order, ideal, lattice, LLL, and modular-kernel routines.

    klpt.h, klptx.c, klptx.h
        KLPT-related routines used by the signing algorithm.

    hd.c, hd.h, finit.c, algebra.c, internal.h, tools.c, tools.h, tutil.h,
    printer.c
        Supporting algebra, initialization, debugging, utility, and internal
        helper code.

    drng.c, drng.h
        Provided deterministic random number generator files used by the KAT
        generator and randomized algorithm steps.

    auxfunc.c, auxfunc.h
        Provided auxiliary hash and XOF functions used for KAT generation and
        preliminary performance evaluation.

    gmp/gmp.h, gmp/libgmp.dll.a
        GMP header and import library files used when building in environments
        that use the bundled GMP interface files. On Unix-like systems the
        system GMP library may be selected by the linker.

**********************Implementation Compliance Notes************************

1.  This submission is a digital signature (SIG) submission. KEM and KEX API
    files are not included because no KEM or KEX algorithm instance is
    submitted.

2.  The provided files "drng.c", "drng.h", "auxfunc.c", "auxfunc.h", and
    "sqisign/KAT_SIG.c" are kept identical across all 8 reference instances and
    all 8 optimized instances.

3.  The macro OUTPUT_BLANK_TEST_VECTORS is set to 0 in every
    "sqisign/SIG_AlgorithmInstance.h" so that KAT generation is enabled.

4.  The macro ALGORITHM_INSTANCE is set to the corresponding algorithm instance
    directory name in every "sqisign/SIG_AlgorithmInstance.h".

5.  The implementation uses the provided SIG programming interface in
    "sqisign/SIG_AlgorithmInstance.h" and "sqisign/SIG_AlgorithmInstance.c".

6.  The reference implementation contains no assembly source files. The
    optimized implementation keeps all parameter-specific assembly routines
    under "ec_arithmetic".

7.  The cryptographic hash and XOF functions used by the implementation are
    provided through "auxfunc.c" and "auxfunc.h".

8.  The implementation assumes little-endian byte order for multi-byte values.

9.  The implementation requires a compiler supporting ISO/IEC 9899:1999 (C99)
    or later.

10. For non-byte-aligned data operations, including DRNG outputs, partial-byte
    read and write operations use the most-significant-bit-first convention.

11. The Makefiles use GNU GCC by default. Users may still override the compiler
    explicitly by passing "CC=..." to make.

*****************************Build and Execution*****************************

1.  Enter the "sqisign" directory of the selected algorithm instance. For
    example:
        Reference_Implementation/SQISign2Dsquare-Level1-eff/sqisign/
        Optimized_Implementation/SQISign2Dsquare-Level1-eff/sqisign/

2.  The following 8 algorithm instance directories are provided:
        SQISign2Dsquare-Level1-eff   p = 2^131 * 3^78 - 1
        SQISign2Dsquare-Level1-sec   p = 2^137 * 3^84 - 1
        SQISign2Dsquare-Level2-eff   p = 61 * 2^161 * 3^96 - 1
        SQISign2Dsquare-Level2-sec   p = 11 * 2^168 * 3^101 - 1
        SQISign2Dsquare-Level3-eff   p = 2^263 * 3^156 - 1
        SQISign2Dsquare-Level3-sec   p = 2^264 * 3^163 - 1
        SQISign2Dsquare-Level5-eff   p = 11 * 2^514 * 3^319 - 1
        SQISign2Dsquare-Level5-sec   p = 17 * 2^536 * 3^334 - 1

    Each algorithm instance contains its own "ec_arithmetic" directory for
    parameter-specific finite-field, Fp2, elliptic-curve constants, and
    optimized arithmetic source files.

3.  Select the compression mode by editing the file "../config.h":
        #define COMPRESSED 0
    selects the uncompressed version, while
        #define COMPRESSED 1
    selects the compressed version.

    The compression mode is part of the build configuration. After changing
    "config.h", run "make" again; the affected files will be rebuilt
    automatically. It is not necessary to run "make clean".

4.  Build the test program by executing:
        make

5.  Build the KAT program by executing:
        make kat

6.  The release build uses the following compiler configurations:

    Reference implementation:
        gcc -std=c99 -Wpedantic -Wall -Wextra -O2

    Optimized implementation:
        gcc -std=c99 -Wpedantic -Wall -Wextra -O3 -march=x86-64 -mavx2
            -mtune=native -flto -fomit-frame-pointer

    The Makefiles also add "-MMD -MP" for dependency-file generation and
    "-DNDEBUG" for release builds.

7.  Each algorithm instance is built from its own directory. No parameter-set
    selector is required in the Makefile.

8.  After compilation, a directory named "build" will be created in the same
    directory as the Makefile. The generated executables are located under:
        build/release/bin/

9.  After entering "build/release/bin/", the generated test program or
    KAT program can be executed directly.

10. After running the KAT executable, a directory named "output" will be
    created under "build/release/bin/". The KAT file generated for the
    selected algorithm instance will be written into this directory.

11. Different algorithm instances are built in separate directories, so it is
    not necessary to run "make clean" before switching instances.

12. For the submission build, do not override COMPRESSED from the command line.
    In particular, avoid using EXTRA_CFLAGS="-DCOMPRESSED=..."; edit
    "config.h" instead. This keeps the build behavior simple and reproducible.
