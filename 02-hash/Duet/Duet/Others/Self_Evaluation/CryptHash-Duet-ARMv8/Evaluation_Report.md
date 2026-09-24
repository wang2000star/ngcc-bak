# Cryptographic Hash Algorithm - Duet ARMv8 Performance-Optimized Version Self-Evaluation Report

## 1. Test Object

This report records the performance self-evaluation results of the ARMv8 NEON
optimized implementation, covering the following algorithm instances:

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
- Counter note: `avg_cycles` is the architecture counter value read by the
  benchmark program. On the ARM platform, this column is `cntvct_el0_ticks`,
  recorded as same-platform test evidence and not used as normalized CPU cycles
  for direct cross-platform comparison.

KAT run commands:

```sh
cd Implementations/Reference_Implementation
./generate_kat.sh

cd ../Additional_Implementation
./generate_kat_armv8.sh
```

Performance test run command:

```sh
taskset -c 0 ./build_benchmark.sh
```

## 3. Test Platform

| Platform | Host | Processor / System | Compiler | Notes |
| --- | --- | --- | --- | --- |
| Huawei Cloud ARMv8 | `root@1.94.113.59` (`ngcc-arm`) | HiSilicon / virt-6.2 CPU @ 2.0GHz, 2 vCPU, aarch64 Linux 6.8.0-106-generic, supports ASIMD/SHA3/SVE | GCC 13.3.0 | `taskset -c 0` pinned to a single core |

## 4. KAT Verification Results

All KAT outputs have been compared file by file with the files of the same names
in `Test_Vectors/`; `diff -q` produced no output.

| Implementation | Duet-512 | Duet-768 | Duet-1024 | Result |
| --- | ---: | ---: | ---: | --- |
| Reference_Implementation | 235 s | 330 s | 442 s | KAT SUCCESS, diff clean |
| ARMv8 NEON Additional_Implementation | 66 s | 67 s | 88 s | KAT SUCCESS, diff clean |

## 5. S8 Throughput Summary

| Platform | Duet-512 ns/hash | Duet-512 MB/s | Duet-768 ns/hash | Duet-768 MB/s | Duet-1024 ns/hash | Duet-1024 MB/s |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Huawei Cloud ARMv8 | 697420.47 | 93.97 | 712068.78 | 92.04 | 996604.66 | 65.76 |

## 6. Huawei Cloud ARMv8 Test Results

### Duet-512

Implementation version: `ARMv8-NEON`. Counter source: `cntvct_el0_ticks`.

| Level | Input Bytes | Iterations | Avg ns/hash | Avg Count | MB/s | Peak RSS Bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| S1 | 32 | 3276800 | 524.38 | 52.44 | 61.02 | 1441792 |
| S2 | 128 | 819200 | 1543.15 | 154.31 | 82.95 | 1441792 |
| S3 | 512 | 204800 | 5624.00 | 562.40 | 91.04 | 1441792 |
| S4 | 1024 | 102400 | 11231.11 | 1123.11 | 91.18 | 1441792 |
| S5 | 4096 | 25600 | 43884.70 | 4388.47 | 93.34 | 1441792 |
| S6 | 8192 | 12800 | 87206.39 | 8720.64 | 93.94 | 1441792 |
| S7 | 16384 | 6400 | 174430.28 | 17443.03 | 93.93 | 1441792 |
| S8 | 65536 | 1600 | 697420.47 | 69742.05 | 93.97 | 1441792 |

`sink=64`

### Duet-768

Implementation version: `ARMv8-NEON`. Counter source: `cntvct_el0_ticks`.

| Level | Input Bytes | Iterations | Avg ns/hash | Avg Count | MB/s | Peak RSS Bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| S1 | 32 | 819200 | 1497.14 | 149.71 | 21.37 | 1441792 |
| S2 | 128 | 819200 | 1491.93 | 149.19 | 85.80 | 1441792 |
| S3 | 512 | 204800 | 5935.81 | 593.58 | 86.26 | 1441792 |
| S4 | 1024 | 102400 | 11829.20 | 1182.92 | 86.57 | 1441792 |
| S5 | 4096 | 25600 | 45742.54 | 4574.25 | 89.54 | 1441792 |
| S6 | 8192 | 12800 | 89974.94 | 8997.49 | 91.05 | 1441792 |
| S7 | 16384 | 6400 | 178446.90 | 17844.69 | 91.81 | 1441792 |
| S8 | 65536 | 1600 | 712068.78 | 71206.88 | 92.04 | 1441792 |

`sink=162`

### Duet-1024

Implementation version: `ARMv8-NEON`. Counter source: `cntvct_el0_ticks`.

| Level | Input Bytes | Iterations | Avg ns/hash | Avg Count | MB/s | Peak RSS Bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| S1 | 32 | 819200 | 1484.47 | 148.45 | 21.56 | 1441792 |
| S2 | 128 | 409600 | 2946.24 | 294.62 | 43.45 | 1441792 |
| S3 | 512 | 204800 | 8792.77 | 879.28 | 58.23 | 1441792 |
| S4 | 1024 | 102400 | 16078.16 | 1607.82 | 63.69 | 1441792 |
| S5 | 4096 | 25600 | 62792.87 | 6279.29 | 65.23 | 1441792 |
| S6 | 8192 | 12800 | 125484.76 | 12548.48 | 65.28 | 1441792 |
| S7 | 16384 | 6400 | 252611.01 | 25261.10 | 64.86 | 1441792 |
| S8 | 65536 | 1600 | 996604.66 | 99660.47 | 65.76 | 1441792 |

`sink=83`
