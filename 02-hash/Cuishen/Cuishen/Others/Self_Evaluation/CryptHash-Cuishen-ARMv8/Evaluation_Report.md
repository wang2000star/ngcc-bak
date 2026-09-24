# Self-Evaluation Report for Cryptographic Hash Algorithm Cuishen ARMv8 Performance-Optimized Version

## 1. Test Object

This report records the performance self-evaluation results of the ARMv8 SHA3/XAR optimized implementation, covering the following algorithm instances:

- `Cuishen-512`
- `Cuishen-768`
- `Cuishen-1024`

The test entry point is `build_benchmark.sh` in this directory, and the performance benchmark program is
`ngcc_hash_benchmark.c`. By default, the script builds and runs the three instances in sequence and prints
the S1-S8 performance tables to the terminal.

## 2. Test Method

Test date: 2026-06-30

General parameters:

- Test cases: S1-S8, with input lengths of 32, 128, 512, 1024, 4096, 8192,
  16384, and 65536 bytes, respectively.
- Runtime parameters: `--min-seconds 1.0`, `--min-iterations 100`.
- Counter note: `avg_cycles` is the architecture counter value read by the benchmark program. On ARM platforms,
  this column is `cntvct_el0_ticks`; it is recorded as same-platform test evidence and is not used as normalized
  CPU cycles for direct cross-platform comparison.

Run command:

```sh
./build_benchmark.sh
```

Run command on the remote Huawei Cloud host:

```sh
taskset -c 0 ./build_benchmark.sh
```

## 3. Test Platforms

| Platform          | Host                       | Processor / System                                                                                  | Compiler           | Notes                         |
| ----------------- | -------------------------- | --------------------------------------------------------------------------------------------------- | ------------------ | ----------------------------- |
| Local ARMv8       | `lizdeMacBook-Pro.local`   | macOS 15.7.7, Darwin 24.6.0, Apple Silicon M1Pro                                                    | Apple clang 17.0.0 | Run directly on the local host |
| Huawei Cloud ARMv8 | `root@1.94.113.59`        | HiSilicon Kunpeng920 / virt-6.2 CPU @ 2.0GHz, 2 vCPU, aarch64 Linux 6.8.0-106-generic, SHA3/SVE support | GCC 13.3.0         | `taskset -c 0` pins one core   |

## 4. S8 Throughput Summary

| Platform          | Cuishen-512 ns/hash | Cuishen-512 MB/s | Cuishen-768 ns/hash | Cuishen-768 MB/s | Cuishen-1024 ns/hash | Cuishen-1024 MB/s |
| ----------------- | ------------------: | ---------------: | ------------------: | ---------------: | -------------------: | ----------------: |
| Local ARMv8       |            67889.60 |           965.33 |            89886.64 |           729.10 |             90193.32 |            726.62 |
| Huawei Cloud ARMv8 |           100149.66 |           654.38 |           172332.46 |           380.29 |            171920.23 |            381.20 |

## 5. Local ARMv8 Test Results

### Cuishen-512

Implementation version: `ARM-SHA3`. Counter source: `cntvct_el0_ticks`.

| Level | Input Bytes | Iterations | Average ns/hash | Average Count |   MB/s | Peak RSS Bytes |
| ----- | ----------: | ---------: | --------------: | ------------: | -----: | -------------: |
| S1    |          32 |   13107200 |          119.01 |          2.86 | 268.88 |        1245184 |
| S2    |         128 |    6553600 |          245.80 |          5.90 | 520.76 |        1245184 |
| S3    |         512 |    1638400 |          638.43 |         15.32 | 801.97 |        1245184 |
| S4    |        1024 |    1638400 |         1160.59 |         27.85 | 882.31 |        1245184 |
| S5    |        4096 |     409600 |         4292.68 |        103.02 | 954.18 |        1245184 |
| S6    |        8192 |     204800 |         8464.42 |        203.15 | 967.82 |        1245184 |
| S7    |       16384 |     102400 |        16812.58 |        403.50 | 974.51 |        1245184 |
| S8    |       65536 |      25600 |        67889.60 |       1629.35 | 965.33 |        1245184 |

`sink=222`

### Cuishen-768

Implementation version: `ARM-SHA3`. Counter source: `cntvct_el0_ticks`.

| Level | Input Bytes | Iterations | Average ns/hash | Average Count |   MB/s | Peak RSS Bytes |
| ----- | ----------: | ---------: | --------------: | ------------: | -----: | -------------: |
| S1    |          32 |    6553600 |          169.52 |          4.07 | 188.77 |        1261568 |
| S2    |         128 |    3276800 |          337.44 |          8.10 | 379.33 |        1261568 |
| S3    |         512 |    1638400 |          905.05 |         21.72 | 565.71 |        1261568 |
| S4    |        1024 |     819200 |         1568.37 |         37.64 | 652.91 |        1261568 |
| S5    |        4096 |     204800 |         5767.24 |        138.41 | 710.22 |        1261568 |
| S6    |        8192 |     102400 |        11389.75 |        273.35 | 719.24 |        1261568 |
| S7    |       16384 |      51200 |        22608.94 |        542.61 | 724.67 |        1261568 |
| S8    |       65536 |      12800 |        89886.64 |       2157.28 | 729.10 |        1261568 |

`sink=2`

### Cuishen-1024

Implementation version: `ARM-SHA3`. Counter source: `cntvct_el0_ticks`.

| Level | Input Bytes | Iterations | Average ns/hash | Average Count |   MB/s | Peak RSS Bytes |
| ----- | ----------: | ---------: | --------------: | ------------: | -----: | -------------: |
| S1    |          32 |    6553600 |          173.13 |          4.16 | 184.83 |        1327104 |
| S2    |         128 |    3276800 |          339.72 |          8.15 | 376.78 |        1327104 |
| S3    |         512 |    1638400 |          862.83 |         20.71 | 593.39 |        1327104 |
| S4    |        1024 |     819200 |         1566.22 |         37.59 | 653.80 |        1327104 |
| S5    |        4096 |     204800 |         5776.00 |        138.62 | 709.14 |        1327104 |
| S6    |        8192 |     102400 |        11408.64 |        273.81 | 718.05 |        1327104 |
| S7    |       16384 |      51200 |        22647.88 |        543.55 | 723.42 |        1327104 |
| S8    |       65536 |      12800 |        90193.32 |       2164.64 | 726.62 |        1327104 |

`sink=178`

## 6. Huawei Cloud ARMv8 Test Results

### Cuishen-512

Implementation version: `ARM-SHA3`. Counter source: `cntvct_el0_ticks`.

| Level | Input Bytes | Iterations | Average ns/hash | Average Count |   MB/s | Peak RSS Bytes |
| ----- | ----------: | ---------: | --------------: | ------------: | -----: | -------------: |
| S1    |          32 |    6553600 |          200.07 |         20.01 | 159.94 |        1441792 |
| S2    |         128 |    3276800 |          389.54 |         38.95 | 328.59 |        1441792 |
| S3    |         512 |    1638400 |          974.94 |         97.49 | 525.16 |        1441792 |
| S4    |        1024 |     819200 |         1755.57 |        175.56 | 583.29 |        1441792 |
| S5    |        4096 |     204800 |         6523.86 |        652.39 | 627.85 |        1441792 |
| S6    |        8192 |     102400 |        12769.47 |       1276.95 | 641.53 |        1441792 |
| S7    |       16384 |      51200 |        25326.33 |       2532.63 | 646.92 |        1441792 |
| S8    |       65536 |      12800 |       100149.66 |      10014.97 | 654.38 |        1441792 |

`sink=222`

### Cuishen-768

Implementation version: `ARM-SHA3`. Counter source: `cntvct_el0_ticks`.

| Level | Input Bytes | Iterations | Average ns/hash | Average Count |   MB/s | Peak RSS Bytes |
| ----- | ----------: | ---------: | --------------: | ------------: | -----: | -------------: |
| S1    |          32 |    3276800 |          347.96 |         34.80 |  91.97 |        1572864 |
| S2    |         128 |    1638400 |          669.19 |         66.92 | 191.28 |        1572864 |
| S3    |         512 |     819200 |         1676.70 |        167.67 | 305.36 |        1572864 |
| S4    |        1024 |     409600 |         3022.19 |        302.22 | 338.83 |        1572864 |
| S5    |        4096 |     102400 |        11083.04 |       1108.30 | 369.57 |        1572864 |
| S6    |        8192 |      51200 |        21830.75 |       2183.08 | 375.25 |        1572864 |
| S7    |       16384 |      25600 |        43367.88 |       4336.79 | 377.79 |        1572864 |
| S8    |       65536 |       6400 |       172332.46 |      17233.25 | 380.29 |        1572864 |

`sink=251`

### Cuishen-1024

Implementation version: `ARM-SHA3`. Counter source: `cntvct_el0_ticks`.

| Level | Input Bytes | Iterations | Average ns/hash | Average Count |   MB/s | Peak RSS Bytes |
| ----- | ----------: | ---------: | --------------: | ------------: | -----: | -------------: |
| S1    |          32 |    3276800 |          345.46 |         34.55 |  92.63 |        1572864 |
| S2    |         128 |    1638400 |          671.65 |         67.16 | 190.58 |        1572864 |
| S3    |         512 |     819200 |         1677.13 |        167.71 | 305.28 |        1572864 |
| S4    |        1024 |     409600 |         3019.23 |        301.92 | 339.16 |        1572864 |
| S5    |        4096 |     102400 |        11075.00 |       1107.50 | 369.84 |        1572864 |
| S6    |        8192 |      51200 |        21779.95 |       2178.00 | 376.13 |        1572864 |
| S7    |       16384 |      25600 |        43293.52 |       4329.35 | 378.44 |        1572864 |
| S8    |       65536 |       6400 |       171920.23 |      17192.02 | 381.20 |        1572864 |

`sink=178`
