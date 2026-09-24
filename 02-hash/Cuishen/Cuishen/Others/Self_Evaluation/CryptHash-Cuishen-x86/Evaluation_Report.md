# Self-Evaluation Report for Cryptographic Hash Algorithm Cuishen x86 Performance-Optimized Version

## 1. Test Object

This report records the performance self-evaluation results of the main-submission x86-64 AVX2/BMI2 assembly optimized implementation, covering the following
algorithm instances:

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
- Counter note: `avg_cycles` is `rdtsc_ticks` read by the benchmark program. It is recorded as same-platform
  test evidence and is not used as normalized CPU cycles for direct cross-platform comparison.

Run command:

```sh
taskset -c 0 ./build_benchmark.sh
```

## 3. Test Platforms

| Platform | Host | Processor / System | Compiler | Notes |
| --- | --- | --- | --- | --- |
| AMD EPYC Server | `gpu1` | AMD EPYC 9654, 384 CPU, 2 sockets, Linux 6.8.0-106-generic, AVX2/BMI2/ADX support | GCC 11.4.0 | `taskset -c 0` pins one core |
| Intel Xeon Server | Intel Server | Intel Xeon Platinum 8383C @ 2.70GHz, 160 CPU, 2 sockets, Linux 5.15.0-160-generic, AVX2/BMI2/ADX support | GCC 11.4.0 | `taskset -c 0` pins one core |

## 4. S8 Throughput Summary

| Platform | Cuishen-512 ns/hash | Cuishen-512 MB/s | Cuishen-768 ns/hash | Cuishen-768 MB/s | Cuishen-1024 ns/hash | Cuishen-1024 MB/s |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| AMD EPYC Server | 79536.83 | 823.97 | 124785.15 | 525.19 | 124469.68 | 526.52 |
| Intel Xeon Server | 102129.33 | 641.70 | 171372.60 | 382.42 | 170722.30 | 383.87 |

## 5. AMD EPYC Server Test Results

### Cuishen-512

Implementation version: `x86-AVX2-asm`. Counter source: `rdtsc_ticks`.

| Level | Input Bytes | Iterations | Average ns/hash | Average Count | MB/s | Peak RSS Bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| S1 | 32 | 6553600 | 191.07 | 457.87 | 167.48 | 1802240 |
| S2 | 128 | 3276800 | 348.89 | 836.08 | 366.88 | 1867776 |
| S3 | 512 | 1638400 | 813.40 | 1949.24 | 629.45 | 1867776 |
| S4 | 1024 | 819200 | 1433.74 | 3435.81 | 714.22 | 1867776 |
| S5 | 4096 | 204800 | 5151.21 | 12344.35 | 795.15 | 1867776 |
| S6 | 8192 | 102400 | 10121.31 | 24254.68 | 809.38 | 1867776 |
| S7 | 16384 | 51200 | 20051.85 | 48052.22 | 817.08 | 1867776 |
| S8 | 65536 | 12800 | 79536.83 | 190601.91 | 823.97 | 1867776 |

`sink=222`

### Cuishen-768

Implementation version: `x86-AVX2-asm`. Counter source: `rdtsc_ticks`.

| Level | Input Bytes | Iterations | Average ns/hash | Average Count | MB/s | Peak RSS Bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| S1 | 32 | 6553600 | 245.58 | 588.52 | 130.30 | 1720320 |
| S2 | 128 | 3276800 | 495.20 | 1186.70 | 258.48 | 1785856 |
| S3 | 512 | 819200 | 1224.97 | 2935.53 | 417.97 | 1785856 |
| S4 | 1024 | 819200 | 2197.14 | 5265.22 | 466.06 | 1785856 |
| S5 | 4096 | 204800 | 8037.62 | 19261.34 | 509.60 | 1785856 |
| S6 | 8192 | 102400 | 15834.98 | 37946.92 | 517.34 | 1785856 |
| S7 | 16384 | 51200 | 31401.28 | 75249.97 | 521.76 | 1785856 |
| S8 | 65536 | 12800 | 124785.15 | 299034.89 | 525.19 | 1785856 |

`sink=139`

### Cuishen-1024

Implementation version: `x86-AVX2-asm`. Counter source: `rdtsc_ticks`.

| Level | Input Bytes | Iterations | Average ns/hash | Average Count | MB/s | Peak RSS Bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| S1 | 32 | 6553600 | 248.34 | 595.11 | 128.86 | 1908736 |
| S2 | 128 | 3276800 | 491.82 | 1178.59 | 260.26 | 1908736 |
| S3 | 512 | 819200 | 1259.76 | 3018.89 | 406.43 | 1908736 |
| S4 | 1024 | 819200 | 2229.89 | 5343.71 | 459.21 | 1908736 |
| S5 | 4096 | 204800 | 8062.75 | 19321.55 | 508.02 | 1908736 |
| S6 | 8192 | 102400 | 15767.85 | 37786.04 | 519.54 | 1908736 |
| S7 | 16384 | 51200 | 31298.63 | 75003.97 | 523.47 | 1908736 |
| S8 | 65536 | 12800 | 124469.68 | 298278.90 | 526.52 | 1908736 |

`sink=178`

## 6. Intel Xeon Server Test Results

### Cuishen-512

Implementation version: `x86-AVX2-asm`. Counter source: `rdtsc_ticks`.

| Level | Input Bytes | Iterations | Average ns/hash | Average Count | MB/s | Peak RSS Bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| S1    |          32 |    6553600 |          246.57 |        664.23 | 129.78 |        1261568 |
| S2    |         128 |    3276800 |          446.66 |       1203.25 | 286.57 |        1261568 |
| S3    |         512 |    1638400 |         1042.62 |       2808.71 | 491.07 |        1261568 |
| S4    |        1024 |     819200 |         1838.08 |       4951.59 | 557.10 |        1261568 |
| S5    |        4096 |     204800 |         6619.70 |      17832.78 | 618.76 |        1261568 |
| S6    |        8192 |     102400 |        12989.03 |      34991.08 | 630.69 |        1261568 |
| S7    |       16384 |      51200 |        25716.64 |      69277.92 | 637.10 |        1261568 |
| S8    |       65536 |      12800 |       102169.26 |     275233.24 | 641.45 |        1261568 |

sink=222`

### Cuishen-768

Implementation version: `x86-AVX2-asm`. Counter source: `rdtsc_ticks`.

| Level | Input Bytes | Iterations | Average ns/hash | Average Count | MB/s | Peak RSS Bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| S1    |          32 |    3276800 |          344.30 |        927.50 |  92.94 |        1265664 |
| S2    |         128 |    1638400 |          677.18 |       1824.24 | 189.02 |        1265664 |
| S3    |         512 |     819200 |         1680.21 |       4526.32 | 304.72 |        1265664 |
| S4    |        1024 |     409600 |         3017.47 |       8128.76 | 339.36 |        1265664 |
| S5    |        4096 |     102400 |        11066.42 |      29811.77 | 370.13 |        1265664 |
| S6    |        8192 |      51200 |        21751.52 |      58596.30 | 376.62 |        1265664 |
| S7    |       16384 |      25600 |        43145.93 |     116230.61 | 379.73 |        1265664 |
| S8    |       65536 |       6400 |       171507.38 |     462022.84 | 382.12 |        1265664 |

`sink=251`

### Cuishen-1024

Implementation version: `x86-AVX2-asm`. Counter source: `rdtsc_ticks`.

| Level | Input Bytes | Iterations | Average ns/hash | Average Count | MB/s | Peak RSS Bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| S1 | 32 | 3276800 |          343.84 |        926.28 |  93.07 |        1269760 |
| S2    |         128 |    1638400 |          693.63 |       1868.56 | 184.54 |        1269760 |
| S3    |         512 |     819200 |         1694.75 |       4565.49 | 302.11 |        1269760 |
| S4    |        1024 |     409600 |         3025.27 |       8149.77 | 338.48 |        1269760 |
| S5    |        4096 |     102400 |        11021.10 |      29689.67 | 371.65 |        1269760 |
| S6    |        8192 |      51200 |        21665.06 |      58363.40 | 378.12 |        1269760 |
| S7    |       16384 |      25600 |        42954.05 |     115713.70 | 381.43 |        1269760 |
| S8    |       65536 |       6400 |       170652.41 |     459719.67 | 384.03 | 1269760 |

`sink=178`
