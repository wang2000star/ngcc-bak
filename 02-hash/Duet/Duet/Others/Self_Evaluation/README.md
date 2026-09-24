# Duet Submission Materials Notes

## 1. Scope

This directory provides the self-evaluation materials for the optimized
implementations of the Duet cryptographic hash algorithm. The directory is
organized by implementation platform. Each implementation directory can be built
independently and used to run performance tests. The materials cover three
algorithm instances:

- `Duet-512`
- `Duet-768`
- `Duet-1024`

The performance tests use the same public interface:

```c
int CryptHash(int digest_len_bits, const unsigned char *msg,
              unsigned long long msg_len_bits, unsigned char *digest);
```

The value of `digest_len_bits` must match the digest length of the selected
instance.

## 2. Directory Layout

```text
Self_Evaluation/
  README.md
  CryptHash-Duet-ARMv8/
    README.md
    Evaluation_Report.md
    build_benchmark.sh
    ngcc_hash_benchmark.c
    Duet-512/
    Duet-768/
    Duet-1024/
  CryptHash-Duet-x86/
    README.md
    Evaluation_Report.md
    build_benchmark.sh
    ngcc_hash_benchmark.c
    Duet-512/
    Duet-768/
    Duet-1024/
  CryptHash-Duet-x86_AVX512/
    README.md
    Evaluation_Report.md
    build_benchmark.sh
    ngcc_hash_benchmark.c
    Duet-512/
    Duet-768/
    Duet-1024/
```

`CryptHash-Duet-ARMv8/` is the self-evaluation directory for the ARMv8 NEON
additional optimized implementation.

`CryptHash-Duet-x86/` is the self-evaluation directory for the primary optimized
implementation in the submission, using the x86-64 AVX2 C implementation.

`CryptHash-Duet-x86_AVX512/` is the self-evaluation directory for the x86-64
AVX512 additional optimized implementation.

## 3. Script Usage

ARMv8 performance test:

```sh
cd CryptHash-Duet-ARMv8
./build_benchmark.sh
```

x86 AVX2 performance test:

```sh
cd CryptHash-Duet-x86
./build_benchmark.sh
```

x86 AVX512 performance test:

```sh
cd CryptHash-Duet-x86_AVX512
./build_benchmark.sh
```

By default, all three scripts build and run `Duet-512`, `Duet-768`, and
`Duet-1024` in order, then print the S1-S8 performance tables in the terminal.
To run only one instance:

```sh
./build_benchmark.sh --bits 512
```

All performance test scripts support:

- `--cc CC`: specify the C compiler.
- `--bits 512|768|1024`: process only one algorithm instance.
- `--min-iterations N`: set the minimum number of iterations for each test case;
  the default is `100`.
- `--min-seconds SEC`: set the minimum runtime for each test case; the default
  is `1.0`.
- `--cpu-hz HZ`: convert counter values using the specified CPU frequency.
- `--build-only`: build the benchmark only, without running it.
- `-o OUTPUT`: specify the output binary path in single-instance mode.
- `-- EXTRA_CFLAGS...`: append extra options to the compiler.

## 4. Evaluation Recommendations

For evaluation, enter the corresponding implementation directory and run
`./build_benchmark.sh` directly. To reduce scheduling noise, a single CPU core
can be pinned on Linux with `taskset -c 0`, for example:

```sh
taskset -c 0 ./build_benchmark.sh
```

The `Evaluation_Report.md` file in each implementation directory records the
test environment, compiler, run commands, and performance data sources that were
available when these materials were organized.
