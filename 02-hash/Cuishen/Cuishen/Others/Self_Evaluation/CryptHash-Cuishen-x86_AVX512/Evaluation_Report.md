# Self-Evaluation Report for Cryptographic Hash Algorithm Cuishen x86_AVX512 Performance-Optimized Version

## 1. Test Object

This report records the performance self-evaluation results of the x86-64 AVX512 additional optimized implementation, covering the following algorithm instances:

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
- Execution method: the Linux hosts run on a fixed single core using `taskset -c 0`.
- Build note: the script uses `-mavx2 -mavx512f -mavx512vl -mtune=native` and automatically selects the AMD or Intel tuned implementation according to
  the CPU vendor.
- Counter note: `avg_cycles` is `rdtsc_ticks` read by the benchmark program. It is recorded as same-platform
  test evidence and is not used as normalized CPU cycles for direct cross-platform comparison.

Run command:

```sh
taskset -c 0 ./build_benchmark.sh
```

## 3. Test Platforms

| Platform | Host | Processor / System | Compiler | Notes |
| --- | --- | --- | --- | --- |
| AMD EPYC Server | `gpu1` | AMD EPYC 9654, 384 CPU, 2 sockets, Linux 6.8.0-106-generic, AVX512F/AVX512VL support | GCC 11.4.0 | `taskset -c 0` pins one core |
| Intel Xeon Server | Intel Server | Intel Xeon Platinum 8383C @ 2.70GHz, 160 CPU, 2 sockets, Linux 5.15.0-160-generic, AVX512F/AVX512VL support | GCC 11.4.0 | `taskset -c 0` pins one core |

## 4. S8 Throughput Summary

| Platform | Cuishen-512 ns/hash | Cuishen-512 MB/s | Cuishen-768 ns/hash | Cuishen-768 MB/s | Cuishen-1024 ns/hash | Cuishen-1024 MB/s |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| AMD EPYC Server | 83287.78 | 786.86 | 108662.35 | 603.12 | 108593.13 | 603.50 |
| Intel Xeon Server | 88607.97 | 739.62 | 119365.47 | 549.04 | 119088.24 | 550.31 |

## 5. AMD EPYC Server Test Results

### Cuishen-512

Implementation version: `x86-AVX512`. Counter source: `rdtsc_ticks`.

| Level | Input Bytes | Iterations | Average ns/hash | Average Count | MB/s | Peak RSS Bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| S1 | 32 | 6553600 | 160.90 | 385.59 | 198.88 | 1908736 |
| S2 | 128 | 3276800 | 322.10 | 771.87 | 397.40 | 1908736 |
| S3 | 512 | 1638400 | 810.64 | 1942.62 | 631.60 | 1908736 |
| S4 | 1024 | 819200 | 1460.47 | 3499.86 | 701.15 | 1908736 |
| S5 | 4096 | 204800 | 5361.67 | 12848.69 | 763.94 | 1908736 |
| S6 | 8192 | 102400 | 10554.07 | 25291.75 | 776.19 | 1908736 |
| S7 | 16384 | 51200 | 20945.92 | 50194.76 | 782.20 | 1908736 |
| S8 | 65536 | 12800 | 83287.78 | 199590.67 | 786.86 | 1908736 |

`sink=222`

### Cuishen-768

Implementation version: `x86-AVX512`. Counter source: `rdtsc_ticks`.

| Level | Input Bytes | Iterations | Average ns/hash | Average Count | MB/s | Peak RSS Bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| S1 | 32 | 6553600 | 216.08 | 517.81 | 148.09 | 1855488 |
| S2 | 128 | 3276800 | 425.09 | 1018.68 | 301.11 | 1921024 |
| S3 | 512 | 1638400 | 1060.41 | 2541.18 | 482.83 | 1921024 |
| S4 | 1024 | 819200 | 1907.81 | 4571.86 | 536.74 | 1921024 |
| S5 | 4096 | 204800 | 6989.11 | 16748.70 | 586.05 | 1921024 |
| S6 | 8192 | 102400 | 13765.32 | 32987.19 | 595.12 | 1921024 |
| S7 | 16384 | 51200 | 27326.79 | 65485.86 | 599.56 | 1921024 |
| S8 | 65536 | 12800 | 108662.35 | 260398.26 | 603.12 | 1921024 |

`sink=2`

### Cuishen-1024

Implementation version: `x86-AVX512`. Counter source: `rdtsc_ticks`.

| Level | Input Bytes | Iterations | Average ns/hash | Average Count | MB/s | Peak RSS Bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| S1 | 32 | 6553600 | 214.72 | 514.55 | 149.03 | 1716224 |
| S2 | 128 | 3276800 | 424.79 | 1017.96 | 301.33 | 1781760 |
| S3 | 512 | 1638400 | 1060.12 | 2540.47 | 482.96 | 1781760 |
| S4 | 1024 | 819200 | 1906.66 | 4569.12 | 537.06 | 1781760 |
| S5 | 4096 | 204800 | 6988.43 | 16747.06 | 586.11 | 1781760 |
| S6 | 8192 | 102400 | 13770.39 | 32999.34 | 594.90 | 1781760 |
| S7 | 16384 | 51200 | 27321.39 | 65472.92 | 599.68 | 1781760 |
| S8 | 65536 | 12800 | 108593.13 | 260232.37 | 603.50 | 1781760 |

`sink=178`

## 6. Intel Xeon Server Test Results

### Cuishen-512

Implementation version: `x86-AVX512`. Counter source: `rdtsc_ticks`.

| Level | Input Bytes | Iterations | Average ns/hash | Average Count | MB/s | Peak RSS Bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| S1 | 32 | 6553600 | 173.37 | 467.04 | 184.58 | 1011712 |
| S2 | 128 | 3276800 | 341.28 | 919.37 | 375.06 | 1011712 |
| S3 | 512 | 1638400 | 865.66 | 2331.99 | 591.46 | 1011712 |
| S4 | 1024 | 819200 | 1556.61 | 4193.35 | 657.84 | 1011712 |
| S5 | 4096 | 204800 | 5703.42 | 15364.41 | 718.17 | 1011712 |
| S6 | 8192 | 102400 | 11225.08 | 30239.20 | 729.79 | 1011712 |
| S7 | 16384 | 51200 | 22275.74 | 60008.49 | 735.51 | 1011712 |
| S8 | 65536 | 12800 | 88607.97 | 238700.58 | 739.62 | 1011712 |

`sink=222`

### Cuishen-768

Implementation version: `x86-AVX512`. Counter source: `rdtsc_ticks`.

| Level | Input Bytes | Iterations | Average ns/hash | Average Count | MB/s | Peak RSS Bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| S1 | 32 | 6553600 | 237.04 | 638.57 | 135.00 | 1015808 |
| S2 | 128 | 3276800 | 469.26 | 1264.13 | 272.77 | 1015808 |
| S3 | 512 | 1638400 | 1167.12 | 3144.10 | 438.69 | 1015808 |
| S4 | 1024 | 819200 | 2097.07 | 5649.29 | 488.30 | 1015808 |
| S5 | 4096 | 204800 | 7684.23 | 20700.51 | 533.04 | 1015808 |
| S6 | 8192 | 102400 | 15133.09 | 40766.95 | 541.33 | 1015808 |
| S7 | 16384 | 51200 | 30022.36 | 80877.09 | 545.73 | 1015808 |
| S8 | 65536 | 12800 | 119365.47 | 321558.03 | 549.04 | 1015808 |

`sink=2`

### Cuishen-1024

Implementation version: `x86-AVX512`. Counter source: `rdtsc_ticks`.

| Level | Input Bytes | Iterations | Average ns/hash | Average Count | MB/s | Peak RSS Bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| S1 | 32 | 6553600 | 234.56 | 631.89 | 136.42 | 1015808 |
| S2 | 128 | 3276800 | 468.90 | 1263.16 | 272.98 | 1015808 |
| S3 | 512 | 1638400 | 1165.12 | 3138.70 | 439.44 | 1015808 |
| S4 | 1024 | 819200 | 2093.22 | 5638.91 | 489.20 | 1015808 |
| S5 | 4096 | 204800 | 7669.75 | 20661.51 | 534.05 | 1015808 |
| S6 | 8192 | 102400 | 15094.62 | 40663.32 | 542.71 | 1015808 |
| S7 | 16384 | 51200 | 29952.34 | 80688.46 | 547.00 | 1015808 |
| S8 | 65536 | 12800 | 119088.24 | 320811.19 | 550.31 | 1015808 |

`sink=178`
