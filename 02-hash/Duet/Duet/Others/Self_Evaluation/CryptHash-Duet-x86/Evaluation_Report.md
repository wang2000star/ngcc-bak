# Cryptographic Hash Algorithm - Duet x86 Performance-Optimized Version Self-Evaluation Report

## 1. Test Object

This report records the performance self-evaluation results of the primary
submitted x86-64 AVX2 C optimized implementation, covering the following
algorithm instances:

- `Duet-512`
- `Duet-768`
- `Duet-1024`

The test entry point is `build_benchmark.sh` in this directory, and the
performance test program is `ngcc_hash_benchmark.c`. By default, the script
builds and runs the three instances in order, then prints the S1-S8 performance
tables in the terminal.

## 2. Test Method

Test date: 2026-06-30

Common parameters:

- Test cases: S1-S8, with input lengths of 32, 128, 512, 1024, 4096, 8192,
  16384, and 65536 bytes, respectively.
- Run parameters: `--min-seconds 1.0`, `--min-iterations 100`.
- Run method: the Linux host uses `taskset -c 0` to pin execution to a single
  core.
- Build note: the script uses `-mavx2 -mbmi -mbmi2 -madx -mtune=native`.
- Counter note: `avg_cycles` is the `rdtsc_ticks` value read by the benchmark
  program, recorded as same-platform test evidence and not used as normalized
  CPU cycles for direct cross-platform comparison.

KAT run command:

```sh
cd Implementations/Optimized_Implementation
./generate_kat.sh
```

Performance test run command:

```sh
taskset -c 0 ./build_benchmark.sh
```

## 3. Test Platform

| Platform | Host | Processor / System | Compiler | Notes |
| --- | --- | --- | --- | --- |
| AMD EPYC Server | `gpu1` | AMD EPYC 9654, 384 CPUs, 2 sockets, Linux 6.8.0-106-generic, supports AVX2/BMI2/ADX | GCC 11.4.0 | `taskset -c 0` pinned to a single core |

## 4. KAT Verification Results

All KAT outputs have been compared file by file with the files of the same names
in `Test_Vectors/`; `diff -q` produced no output.

| Implementation | Duet-512 | Duet-768 | Duet-1024 | Result |
| --- | ---: | ---: | ---: | --- |
| x86 AVX2 Optimized_Implementation | 45 s | 58 s | 76 s | KAT SUCCESS, diff clean |

## 5. S8 Throughput Summary

| Platform | Duet-512 ns/hash | Duet-512 MB/s | Duet-768 ns/hash | Duet-768 MB/s | Duet-1024 ns/hash | Duet-1024 MB/s |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| AMD EPYC Server | 457625.88 | 143.21 | 674990.20 | 97.09 | 953151.98 | 68.76 |

## 6. AMD EPYC Server Test Results

### Duet-512

Implementation version: `x86-AVX2-C`. Counter source: `rdtsc_ticks`.

| Level | Input Bytes | Iterations | Avg ns/hash | Avg Count | MB/s | Peak RSS Bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| S1 | 32 | 3276800 | 345.95 | 829.02 | 92.50 | 1912832 |
| S2 | 128 | 1638400 | 1017.80 | 2439.06 | 125.76 | 1912832 |
| S3 | 512 | 409600 | 3707.53 | 8884.71 | 138.10 | 1912832 |
| S4 | 1024 | 204800 | 7398.25 | 17729.15 | 138.41 | 1912832 |
| S5 | 4096 | 51200 | 28841.73 | 69116.26 | 142.02 | 1912832 |
| S6 | 8192 | 25600 | 57332.77 | 137392.13 | 142.89 | 1912832 |
| S7 | 16384 | 12800 | 114607.73 | 274645.75 | 142.96 | 1912832 |
| S8 | 65536 | 3200 | 457625.88 | 1096653.95 | 143.21 | 1912832 |

`sink=64`

### Duet-768

Implementation version: `x86-AVX2-C`. Counter source: `rdtsc_ticks`.

| Level | Input Bytes | Iterations | Avg ns/hash | Avg Count | MB/s | Peak RSS Bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| S1 | 32 | 819200 | 1421.68 | 3406.91 | 22.51 | 1724416 |
| S2 | 128 | 819200 | 1418.73 | 3399.85 | 90.22 | 1789952 |
| S3 | 512 | 204800 | 5632.38 | 13497.43 | 90.90 | 1789952 |
| S4 | 1024 | 102400 | 11221.08 | 26890.17 | 91.26 | 1789952 |
| S5 | 4096 | 25600 | 43417.34 | 104045.24 | 94.34 | 1789952 |
| S6 | 8192 | 12800 | 85486.11 | 204858.80 | 95.83 | 1789952 |
| S7 | 16384 | 6400 | 169455.41 | 406082.63 | 96.69 | 1789952 |
| S8 | 65536 | 1600 | 674990.20 | 1617545.24 | 97.09 | 1789952 |

`sink=162`

### Duet-1024

Implementation version: `x86-AVX2-C`. Counter source: `rdtsc_ticks`.

| Level | Input Bytes | Iterations | Avg ns/hash | Avg Count | MB/s | Peak RSS Bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| S1 | 32 | 819200 | 1414.53 | 3389.77 | 22.62 | 1916928 |
| S2 | 128 | 409600 | 2809.74 | 6733.26 | 45.56 | 1916928 |
| S3 | 512 | 204800 | 8395.01 | 20117.79 | 60.99 | 1916928 |
| S4 | 1024 | 102400 | 15362.62 | 36814.95 | 66.66 | 1916928 |
| S5 | 4096 | 25600 | 60049.04 | 143901.41 | 68.21 | 1916928 |
| S6 | 8192 | 12800 | 120132.39 | 287885.08 | 68.19 | 1916928 |
| S7 | 16384 | 6400 | 238703.98 | 572029.76 | 68.64 | 1916928 |
| S8 | 65536 | 1600 | 953151.98 | 2284131.58 | 68.76 | 1916928 |

`sink=83`
