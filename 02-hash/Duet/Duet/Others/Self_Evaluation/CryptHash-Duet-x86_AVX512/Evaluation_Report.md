# Cryptographic Hash Algorithm - Duet x86_AVX512 Performance-Optimized Version Self-Evaluation Report

## 1. Test Object

This report records the performance self-evaluation results of the x86-64
AVX512 additional optimized implementation, covering the following algorithm
instances:

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
- Build note: the script uses `-mavx2 -mavx512f -mavx512vl -mavx512bw
  -mavx512dq -mtune=native`.
- Counter note: `avg_cycles` is the `rdtsc_ticks` value read by the benchmark
  program, recorded as same-platform test evidence and not used as normalized
  CPU cycles for direct cross-platform comparison.

KAT run command:

```sh
cd Implementations/Additional_Implementation
./generate_kat_avx512.sh
```

Performance test run command:

```sh
taskset -c 0 ./build_benchmark.sh
```

## 3. Test Platform

| Platform | Host | Processor / System | Compiler | Notes |
| --- | --- | --- | --- | --- |
| AMD EPYC Server | `gpu1` | AMD EPYC 9654, 384 CPUs, 2 sockets, Linux 6.8.0-106-generic, supports AVX512F/AVX512VL/AVX512BW/AVX512DQ | GCC 11.4.0 | `taskset -c 0` pinned to a single core |

## 4. KAT Verification Results

All KAT outputs have been compared file by file with the files of the same names
in `Test_Vectors/`; `diff -q` produced no output.

| Implementation | Duet-512 | Duet-768 | Duet-1024 | Result |
| --- | ---: | ---: | ---: | --- |
| x86 AVX512 Additional_Implementation | 41 s | 46 s | 59 s | KAT SUCCESS, diff clean |

## 5. S8 Throughput Summary

| Platform | Duet-512 ns/hash | Duet-512 MB/s | Duet-768 ns/hash | Duet-768 MB/s | Duet-1024 ns/hash | Duet-1024 MB/s |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| AMD EPYC Server | 419394.31 | 156.26 | 490286.29 | 133.67 | 689194.95 | 95.09 |

## 6. AMD EPYC Server Test Results

### Duet-512

Implementation version: `x86-AVX512`. Counter source: `rdtsc_ticks`.

| Level | Input Bytes | Iterations | Avg ns/hash | Avg Count | MB/s | Peak RSS Bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| S1 | 32 | 3276800 | 316.72 | 759.00 | 101.03 | 1855488 |
| S2 | 128 | 1638400 | 934.11 | 2238.49 | 137.03 | 1921024 |
| S3 | 512 | 409600 | 3396.92 | 8140.38 | 150.72 | 1921024 |
| S4 | 1024 | 204800 | 6777.19 | 16240.84 | 151.10 | 1921024 |
| S5 | 4096 | 51200 | 26433.45 | 63345.07 | 154.96 | 1921024 |
| S6 | 8192 | 25600 | 52519.69 | 125858.07 | 155.98 | 1921024 |
| S7 | 16384 | 12800 | 104992.15 | 251602.99 | 156.05 | 1921024 |
| S8 | 65536 | 3200 | 419394.31 | 1005035.89 | 156.26 | 1921024 |

`sink=64`

### Duet-768

Implementation version: `x86-AVX512`. Counter source: `rdtsc_ticks`.

| Level | Input Bytes | Iterations | Avg ns/hash | Avg Count | MB/s | Peak RSS Bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| S1 | 32 | 1638400 | 1051.79 | 2520.52 | 30.42 | 1720320 |
| S2 | 128 | 1638400 | 1047.90 | 2511.18 | 122.15 | 1785856 |
| S3 | 512 | 409600 | 4104.30 | 9835.54 | 124.75 | 1785856 |
| S4 | 1024 | 204800 | 8184.39 | 19613.05 | 125.12 | 1785856 |
| S5 | 4096 | 51200 | 31555.03 | 75618.40 | 129.80 | 1785856 |
| S6 | 8192 | 25600 | 62068.66 | 148741.23 | 131.98 | 1785856 |
| S7 | 16384 | 12800 | 123078.29 | 294944.57 | 133.12 | 1785856 |
| S8 | 65536 | 3200 | 490286.29 | 1174921.11 | 133.67 | 1785856 |

`sink=83`

### Duet-1024

Implementation version: `x86-AVX512`. Counter source: `rdtsc_ticks`.

| Level | Input Bytes | Iterations | Avg ns/hash | Avg Count | MB/s | Peak RSS Bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| S1 | 32 | 1638400 | 1037.93 | 2487.30 | 30.83 | 1904640 |
| S2 | 128 | 819200 | 2043.11 | 4896.12 | 62.65 | 1904640 |
| S3 | 512 | 204800 | 6065.14 | 14534.50 | 84.42 | 1904640 |
| S4 | 1024 | 102400 | 11094.85 | 26587.68 | 92.30 | 1904640 |
| S5 | 4096 | 25600 | 43265.47 | 103681.32 | 94.67 | 1904640 |
| S6 | 8192 | 12800 | 86622.99 | 207583.17 | 94.57 | 1904640 |
| S7 | 16384 | 6400 | 172306.94 | 412916.03 | 95.09 | 1904640 |
| S8 | 65536 | 1600 | 689194.95 | 1651585.47 | 95.09 | 1904640 |

`sink=83`
