# Cuishen Self-Evaluation Package Notes

## 1. Scope

This directory contains the self-evaluation materials for the optimized
implementations of the Cuishen cryptographic hash algorithm. The directory is
organized by implementation platform. Each implementation directory can be built
and benchmarked independently, covering three algorithm instances:

- `Cuishen-512`
- `Cuishen-768`
- `Cuishen-1024`

The performance tests use the same public interface:

```c
int CryptHash(int digest_len_bits, const unsigned char *msg,
              unsigned long long msg_len_bits, unsigned char *digest);
```

The `digest_len_bits` argument must match the digest length of the selected
instance.

## 2. Directory Layout

```text
Self_Evaluation/
  README.md
  CryptHash-Cuishen-ARMv8/
    Evaluation_Report.md
    build_benchmark.sh
    ngcc_hash_benchmark.c
    Cuishen-512/
    Cuishen-768/
    Cuishen-1024/
  CryptHash-Cuishen-x86/
    Evaluation_Report.md
    build_benchmark.sh
    ngcc_hash_benchmark.c
    Cuishen-512/
    Cuishen-768/
    Cuishen-1024/
  CryptHash-Cuishen-x86_AVX512/
    Evaluation_Report.md
    build_benchmark.sh
    ngcc_hash_benchmark.c
    Cuishen-512/
    Cuishen-768/
    Cuishen-1024/
```

`CryptHash-Cuishen-ARMv8/` is the self-evaluation directory for
the ARMv8 SHA3/XAR additional optimized implementation.

`CryptHash-Cuishen-x86/` is the self-evaluation directory for the
primary optimized implementation. It targets mainstream 64-bit PC processors and
uses x86-64 AVX2/BMI2 assembly.

`CryptHash-Cuishen-x86_AVX512/` is the self-evaluation directory for
the x86-64 AVX512 additional optimized implementation.

## 3. Files in Each Algorithm Instance Directory

Each self-evaluation implementation directory contains:

- `build_benchmark.sh`: script that builds and runs the performance benchmark.
- `ngcc_hash_benchmark.c`: benchmark program covering the S1-S8 input sizes.
- `Evaluation_Report.md`: test environment, run commands, and performance
  results for the implementation platform.
- `README.md`: brief notes for the implementation directory.
- `Cuishen-512/`, `Cuishen-768/`, `Cuishen-1024/`: source directories for the
  three algorithm instances.

ARMv8 self-evaluation instance directories `Cuishen-*/` contain:

- `CryptHash_Cuishen-*_ARM_dispatch.c`: ARMv8 runtime dispatch entry point,
  selecting either the SHA3/XAR backend or the backend without SHA3/XAR.
- `CryptHash_Cuishen-*_ARM_sha3.c`: ARMv8 SHA3/XAR optimized implementation.
- `CryptHash_Cuishen-*_ARM_nosha3.c`: ARMv8 fallback implementation for
  processors without SHA3/XAR instructions.
- `CryptHash_Cuishen-*.h`: instance parameters, digest length, and declaration
  of the `CryptHash` interface.
- `KAT_CryptHash.c`, `drng.c`, `drng.h`, `README`: KAT program and directory
  notes.

x86 primary optimized self-evaluation instance directories `Cuishen-*/` contain:

- `CryptHash_Cuishen-*_x86.S`: optimized x86-64 AVX2/BMI2 assembly
  implementation.
- `CryptHash_Cuishen-*.h`: instance parameters, digest length, and declaration
  of the `CryptHash` interface.
- `KAT_CryptHash.c`, `drng.c`, `drng.h`, `README`: KAT program and directory
  notes.

AVX512 self-evaluation instance directories `Cuishen-*/` contain:

- `CryptHash_Cuishen-*_avx512_select.c`: AVX512 selection entry point, choosing
  the AMD- or Intel-tuned version according to compile-time macros or the target
  CPU.
- `CryptHash_Cuishen-*_avx512_amd.c`: AVX512 implementation tuned for AMD Zen
  platforms.
- `CryptHash_Cuishen-*_avx512_intel.c`: AVX512 implementation tuned for Intel
  platforms.
- `CryptHash_Cuishen-*.h`: instance parameters, digest length, and declaration
  of the `CryptHash` interface.
- `KAT_CryptHash.c`, `drng.c`, `drng.h`, `README`: KAT program and directory
  notes.

## 4. Script Usage

ARMv8 performance test:

```sh
cd CryptHash-Cuishen-ARMv8
./build_benchmark.sh
```

x86 AVX2/BMI2 performance test:

```sh
cd CryptHash-Cuishen-x86
./build_benchmark.sh
```

x86 AVX512 performance test:

```sh
cd CryptHash-Cuishen-x86_AVX512
./build_benchmark.sh
```

By default, all three scripts build and run `Cuishen-512`, `Cuishen-768`, and
`Cuishen-1024` in sequence, and print the S1-S8 performance table directly to
the terminal. To run only one instance:

```sh
./build_benchmark.sh --bits 512
```

All performance benchmark scripts support:

- `--cc CC`: specify the C compiler.
- `--bits 512|768|1024`: process only one algorithm instance.
- `--min-iterations N`: set the minimum number of iterations for each case;
  default is `100`.
- `--min-seconds SEC`: set the minimum run time for each case; default is `1.0`.
- `--cpu-hz HZ`: convert counter values using the specified CPU frequency.
- `--build-only`: build the benchmark without running it.
- `-o OUTPUT`: specify the output binary path in single-instance mode.
- `-- EXTRA_CFLAGS...`: append extra options to the compiler command line.

## 5. Output and Cleanup

By default, the scripts create only a `bin/` directory under the current
self-evaluation implementation directory, where the benchmark executables are
stored. Performance results are printed directly to the terminal, and the formal
data records are kept in each directory's `Evaluation_Report.md`.

The ARMv8 script uses a system temporary directory for intermediate `.o` files
and cleans them up automatically when the script exits. The x86 and AVX512
scripts directly generate the final benchmark binaries and do not keep `.o`
files.

## 6. Evaluation Suggestions

For evaluation, enter the corresponding implementation directory and run
`./build_benchmark.sh` directly. To reduce scheduling noise on Linux, the process
can be pinned to a single core with `taskset -c 0`, for example:

```sh
taskset -c 0 ./build_benchmark.sh
```

Recommended platforms:

- ARMv8 self-evaluation: aarch64, preferably an ARMv8.2-A processor with
  SHA3/XAR support. Processors without the SHA3 extension remain supported.
- x86 primary optimized self-evaluation: x86-64 processor with AVX2/BMI2/ADX.
- AVX512 self-evaluation: x86-64 processor with AVX512F and AVX512VL.

The `Evaluation_Report.md` file in each implementation directory records the
test environment, compiler, run commands, and S1-S8 performance data rerun for
this submission.
