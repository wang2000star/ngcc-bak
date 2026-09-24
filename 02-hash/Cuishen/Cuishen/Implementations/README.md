# Cuishen Submission Package Notes

## 1. Scope

This directory contains the implementation source code for the Cuishen
cryptographic hash algorithm. The directory is organized by submission material
type: reference implementation, primary optimized implementation, and additional
optimized implementations. It covers three algorithm instances:

- `Cuishen-512`
- `Cuishen-768`
- `Cuishen-1024`

All instances use the same public interface:

```c
int CryptHash(int digest_len_bits, const unsigned char *msg,
              unsigned long long msg_len_bits, unsigned char *digest);
```

The `digest_len_bits` argument must match the digest length of the selected
instance.

## 2. Directory Layout

```text
Implementations/
  README
  Reference_Implementation/
    generate_kat.sh
    Cuishen-512/
    Cuishen-768/
    Cuishen-1024/
  Optimized_Implementation/
    README.md
    generate_kat.sh
    Cuishen-512/
    Cuishen-768/
    Cuishen-1024/
  Additional_Implementation/
    generate_kat_armv8.sh
    generate_kat_avx512.sh
    Cuishen-512/
      ARMv8/
      AVX512/
      ASIC/
    Cuishen-768/
      ARMv8/
      AVX512/
      ASIC/
    Cuishen-1024/
      ARMv8/
      AVX512/
      ASIC/
```

`Reference_Implementation/` contains the portable ISO C reference
implementation. It describes the algorithm logic and can be used to generate
the standard KAT output.

`Optimized_Implementation/` contains the primary optimized implementation for
the submission. It targets mainstream 64-bit PC processors and uses x86-64
AVX2/BMI2 assembly.

`Additional_Implementation/` contains implementations for additional
platforms, including an ARMv8 SHA3/XAR implementation and an x86-64 AVX512
implementation. It also includes round-based ASIC RTL implementations with
simulation testbenches and post-synthesis reports. Additional implementations
are organized as
`Cuishen-*/platform/`.

## 3. Files in Each Algorithm Instance Directory

Reference implementation directories `Reference_Implementation/Cuishen-*/`
contain:

- `CryptHash_Cuishen-*.c`: reference C implementation of the instance.
- `CryptHash_Cuishen-*.h`: instance parameters, digest length, and declaration
  of the `CryptHash` interface.
- `KAT_CryptHash.c`: entry point of the KAT generation program.
- `drng.c`, `drng.h`: deterministic random number generator used by the KAT
  program.
- `README`: brief notes for the instance directory.

Primary optimized implementation directories `Optimized_Implementation/Cuishen-*/`
contain:

- `CryptHash_Cuishen-*_x86.S`: optimized x86-64 AVX2/BMI2 assembly
  implementation.
- `CryptHash_Cuishen-*.h`: instance parameters, digest length, and declaration
  of the `CryptHash` interface.
- `KAT_CryptHash.c`: entry point of the KAT generation program.
- `drng.c`, `drng.h`: deterministic random number generator used by the KAT
  program.
- `README`: brief notes for the instance directory.

ARMv8 additional implementation directories
`Additional_Implementation/Cuishen-*/ARMv8/` contain:

- `CryptHash_Cuishen-*_ARM_dispatch.c`: ARMv8 runtime dispatch entry point,
  selecting either the SHA3/XAR backend or the backend without SHA3/XAR.
- `CryptHash_Cuishen-*_ARM_sha3.c`: ARMv8 SHA3/XAR optimized implementation.
- `CryptHash_Cuishen-*_ARM_nosha3.c`: ARMv8 fallback implementation for
  processors without SHA3/XAR instructions.
- `CryptHash_Cuishen-*.h`: instance parameters, digest length, and declaration
  of the `CryptHash` interface.
- `KAT_CryptHash.c`, `drng.c`, `drng.h`, `README`: KAT program and directory
  notes.

AVX512 additional implementation directories
`Additional_Implementation/Cuishen-*/AVX512/` contain:

- `CryptHash_Cuishen-*_avx512_select.c`: AVX512 selection entry point, choosing
  the AMD- or Intel-tuned version according to compile-time macros or the
  target CPU.
- `CryptHash_Cuishen-*_avx512_amd.c`: AVX512 implementation tuned for AMD Zen
  platforms.
- `CryptHash_Cuishen-*_avx512_intel.c`: AVX512 implementation tuned for Intel
  platforms.
- `CryptHash_Cuishen-*.h`: instance parameters, digest length, and declaration
  of the `CryptHash` interface.
- `KAT_CryptHash.c`, `drng.c`, `drng.h`, `README`: KAT program and directory
  notes.

ASIC additional implementation directories
`Additional_Implementation/Cuishen-*/ASIC/` contain:

- `cuishen.v`: 32-bit memory-mapped wrapper and synthesis top module.
- `cuishen_core.v`: round-based Cuishen core, using one round per clock cycle
  without pipelining or loop unrolling.
- `cuishen_key_mem.v`: shared key-schedule sliding-window logic.
- `cuishen_iv_constants.v`: IV constants for the selected instance.
- `cuishen_pi_constants.v` or `cuishen_e_constants.v`: round-constant table
  used by the selected instance.
- `tb_cuishen_*.v`: self-checking Icarus Verilog testbenches for short KAT
  vectors and long all-zero/all-one compression-path vectors.
- `README.md`: instance-specific ASIC notes, testbench commands. 

## 4. Script Usage

Reference implementation KAT:

```sh
cd Reference_Implementation
./generate_kat.sh
```

By default, the script builds and runs the KAT generation programs for
`Cuishen-512`, `Cuishen-768`, and `Cuishen-1024` in sequence. To run only one
instance:

```sh
./generate_kat.sh --bits 512
```

Primary optimized implementation KAT:

```sh
cd Optimized_Implementation
./generate_kat.sh
```

This script should be run on a machine that supports x86-64 AVX2/BMI2/ADX. To
run only one instance:

```sh
./generate_kat.sh --bits 768
```

ARMv8 additional implementation KAT:

```sh
cd Additional_Implementation
./generate_kat_armv8.sh
```

This script should be run on an ARMv8/aarch64 machine. To run only one
instance:

```sh
./generate_kat_armv8.sh --bits 1024
```

AVX512 additional implementation KAT:

```sh
cd Additional_Implementation
./generate_kat_avx512.sh
```

This script should be run on a machine that supports x86-64 AVX512F/AVX512VL.
To run only one instance:

```sh
./generate_kat_avx512.sh --bits 512
```

All KAT scripts support:

- `--cc CC`: specify the C compiler.
- `--bits 512|768|1024`: process only one algorithm instance.
- `--build-only`: build the KAT program without running it.
- `-o OUTPUT`: specify the output binary path in single-instance mode.
- `-- EXTRA_CFLAGS...`: append extra options to the compiler command line.

ASIC RTL validation and synthesis report reproduction are documented in each
`Additional_Implementation/Cuishen-*/ASIC/README.md`. The C KAT scripts above do
not build or run the ASIC Verilog implementations.

## 5. Output and Cleanup

When `-o` is not specified, the scripts create a `bin/` directory under the
current implementation-type directory and place the KAT generator binaries
there. After a KAT program runs, it creates an `output/` directory according to
its own logic.

Intermediate object files are managed through temporary directories or internal
script directories. The submitted source tree does not require manually saved
`.o` files.

## 6. Evaluation Suggestions

For evaluation, first run `Reference_Implementation/generate_kat.sh` to produce
the reference output. Then run the KAT scripts for the optimized implementation
and the additional implementations, and compare the generated KAT files for
consistency.

Recommended platforms:

- Reference implementation: any general-purpose platform with C99 support.
- Primary optimized implementation: x86-64 processor with AVX2/BMI2/ADX.
- ARMv8 additional implementation: aarch64, preferably an ARMv8.2-A processor
  with SHA3/XAR support; processors without the SHA3 extension remain
  supported.
- AVX512 additional implementation: x86-64 processor with AVX512F and AVX512VL.
- ASIC additional implementation: Verilog-2001 simulator such as Icarus Verilog
  for functional testbenches, and Synopsys Design Compiler with the documented
  TSMC 65nm library for reproducing the included synthesis reports.
