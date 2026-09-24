# Duet Implementation Submission Notes

## 1. Scope

This directory provides the implementation source code for the Duet cryptographic
hash algorithm. The directory is organized by submission material type into the
reference implementation, the primary optimized implementation, and additional
software and hardware implementations. It covers three algorithm instances:

- `Duet-512`
- `Duet-768`
- `Duet-1024`

All instances use the same public interface:

```c
int CryptHash(int digest_len_bits, const unsigned char *msg,
              unsigned long long msg_len_bits, unsigned char *digest);
```

The value of `digest_len_bits` must match the digest length of the selected
instance.

## 2. Directory Layout

```text
Implementations/
  README.md
  Reference_Implementation/
    generate_kat.sh
    Duet-512/
    Duet-768/
    Duet-1024/
  Optimized_Implementation/
    README.md
    generate_kat.sh
    Duet-512/
    Duet-768/
    Duet-1024/
  Additional_Implementation/
    generate_kat_armv8.sh
    generate_kat_avx512.sh
    Duet-512/
      ARMv8/
      ASIC/
      AVX512/
    Duet-768/
      ARMv8/
      ASIC/
      AVX512/
    Duet-1024/
      ARMv8/
      ASIC/
      AVX512/
```

`Reference_Implementation/` contains the portable ISO C reference
implementation, which describes the algorithm logic and generates the standard
KAT output.

`Optimized_Implementation/` contains the primary optimized implementation in the
submission, using the retained x86 AVX2 C optimized implementation of Duet.

`Additional_Implementation/` contains additional platform implementations,
including the ARMv8 NEON implementation, the x86-64 AVX512 implementation, and
the round-based ASIC RTL implementation. Additional implementations are organized
as `Duet-*/platform/`.

## 3. Files in Each Algorithm Instance Directory

The reference implementation directories `Reference_Implementation/Duet-*/`
contain:

- `CryptHash_Duet-*.c`: the reference C implementation for the instance.
- `CryptHash_Duet-*.h`: algorithm instance parameters, digest length, and the
  `CryptHash` interface declaration.
- `KAT_CryptHash.c`: entry point for the KAT generator.
- `drng.c`, `drng.h`: deterministic random number generator used by the KAT
  program.
- `README`: brief notes for the instance directory.

The primary optimized implementation directories `Optimized_Implementation/Duet-*/`
contain:

- `CryptHash_Duet-*-c-avx2.c`: x86-64 AVX2 optimized C implementation.
- `CryptHash_Duet-*.h`: algorithm instance parameters, digest length, and the
  `CryptHash` interface declaration.
- `KAT_CryptHash.c`: entry point for the KAT generator.
- `drng.c`, `drng.h`: deterministic random number generator used by the KAT
  program.
- `README`: brief notes for the instance directory.

The ARMv8 additional implementation directories
`Additional_Implementation/Duet-*/ARMv8/` contain:

- `CryptHash_Duet-*-c-neon.c`: ARMv8 NEON optimized implementation.
- `CryptHash_Duet-*.h`: algorithm instance parameters, digest length, and the
  `CryptHash` interface declaration.
- `KAT_CryptHash.c`, `drng.c`, `drng.h`, `README`: KAT and directory note files.

The AVX512 additional implementation directories
`Additional_Implementation/Duet-*/AVX512/` contain:

- `CryptHash_Duet-*-c-avx512.c`: x86-64 AVX512 optimized C implementation.
- `CryptHash_Duet-*.h`: algorithm instance parameters, digest length, and the
  `CryptHash` interface declaration.
- `KAT_CryptHash.c`, `drng.c`, `drng.h`, `README`: KAT and directory note files.

The ASIC additional implementation directories
`Additional_Implementation/Duet-*/ASIC/` contain round-based Verilog RTL,
simulation testbenches when available, and post-synthesis reports:

- `duet_*.v`: 32-bit memory-mapped top-level wrapper for the instance.
- `duet_core_*.v`: Duet core state, absorb/finalization control, and f1/f2
  sequencing.
- `duet_perm_unit_*.v`: permutation datapath, one round per clock cycle.
- `duet_pi_constants_*.v`: round-constant table used by the permutation.
- `tb_duet_*.v`: self-checking testbench.
- `README.md`: instance-specific synthesis environment, simulation or report reproduction notes.

## 4. Script Usage

Reference implementation KAT:

```sh
cd Reference_Implementation
./generate_kat.sh
```

Primary optimized implementation KAT:

```sh
cd Optimized_Implementation
./generate_kat.sh
```

ARMv8 additional implementation KAT:

```sh
cd Additional_Implementation
./generate_kat_armv8.sh
```

AVX512 additional implementation KAT:

```sh
cd Additional_Implementation
./generate_kat_avx512.sh
```

All KAT scripts support:

- `--cc CC`: specify the C compiler.
- `--bits 512|768|1024`: process only one algorithm instance.
- `--build-only`: build the KAT program only, without running it.
- `-o OUTPUT`: specify the output binary path in single-instance mode.
- `-- EXTRA_CFLAGS...`: append extra options to the compiler.

ASIC RTL validation and synthesis report reproduction are documented in each
`Additional_Implementation/Duet-*/ASIC/README.md`. The C KAT scripts above do
not build or run the ASIC Verilog implementations.

## 5. Output and Cleanup

When `-o` is not specified, the scripts place the KAT generator under `/tmp`.
After the KAT program is run, it generates `output/` in the corresponding
instance directory according to its own logic.

The official submission vectors have been flattened into the top-level
`Test_Vectors/` directory.
