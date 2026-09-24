## ZEN Benchmark ARMv8

This file records the build method, test platform, and measured performance for the GNU/Linux AArch64 optimized ZEN_128/256/512 implementation.

## Test Platform

| Item         | Value                                                        |
| ------------ | ------------------------------------------------------------ |
| Cloud host   | Huawei Cloud ARM instance                                    |
| Architecture | aarch64                                                      |
| CPU vendor   | HiSilicon                                                    |
| CPU model    | HiSilicon Kunpeng 920 CPU @ 2.0GHz                           |
| OS           | Ubuntu 24.04.4 LTS                                           |
| Kernel       | Linux 6.8.0-106-generic                                      |
| Compiler     | GCC 13.3.0                                                   |
| Online CPUs  | 2                                                            |
| Memory       | 4GiB                                                         |
| CPU features | fp asimd aes pmull sha1 sha2 crc32 sha3 sm3 sm4 sha512 sve asimddp i8mm bf16 and related ARM features |

The benchmark process was pinned to CPU 0 through `ZEN_BENCH_PIN_CPU=0`.

Hardware PMU cycle counters were not available on this cloud instance:
`perf stat -e cycles,instructions` reported the events as unsupported, and
`/sys/devices/system/cpu/cpu0/cpufreq/*` frequency files were unavailable.
Therefore the cycles below are estimated as elapsed time multiplied by the
reported virtual CPU frequency, 2.0 GHz.

## Build

Default benchmark build:

```sh
make clean
make benchmark
```

Default KAT build:

```sh
make KAT_KEM
./KAT_KEM
```

Default compiler configuration from `Makefile`:

```text
CC ?= gcc
CFLAGS ?= -O3 -march=armv8.2-a+crypto+sha3+dotprod+sve -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra
```

Benchmark command used for the result below:

```sh
ZEN_BENCH_PIN_CPU=0 ZEN_BENCH_CPU_HZ=2000000000 ./benchmark
```

The benchmark runs 1000 measured iterations per operation by default, after 10
warm-up iterations. It writes `benchmark_ZEN_{param}_raw.csv` and
`benchmark_ZEN_{param}_summary.json`.

## Correctness

| Check                       | Result |
| --------------------------- | ------ |
| `make KAT_KEM && ./KAT_KEM` | PASS   |
| Interface length getters    | PASS   |
| Fixed-seed KEM round trip   | PASS   |
| DRNG-seeded KEM round trip  | PASS   |

## ZEN_128 Performance

Results are averages over 1000 measured iterations. Time is wall-clock time from
`clock_gettime(CLOCK_MONOTONIC)`. Cycles are estimated from the 2.0 GHz reported
virtual CPU frequency.

| Operation           | Average us | Median us | Estimated cycles |    ops/s | Failures |
| ------------------- | ---------: | --------: | ---------------: | -------: | -------: |
| `kem_keygen`        |     37.972 |    31.582 |         75944.63 | 26334.98 |        0 |
| `kem_keygen_derand` |     50.392 |    50.093 |        100784.91 | 19844.24 |        0 |
| `kem_enc`           |     40.908 |    40.662 |         81815.52 | 24445.24 |        0 |
| `kem_dec`           |     40.139 |    39.903 |         80278.23 | 24913.36 |        0 |

## ZEN_128 Sizes And Memory

| Item                 |   Bytes |
| -------------------- | ------: |
| Public key           |     615 |
| Secret key           |    1303 |
| Ciphertext           |     512 |
| Shared secret        |      16 |
| Static text/rodata   |   45768 |
| Static writable      |   85504 |
| Static total         |  131272 |
| Peak RSS after tests | 1871872 |
| Benchmark context    |    2590 |

## ZEN_256 Performance

Results are averages over 1000 measured iterations. Time is wall-clock time from
`clock_gettime(CLOCK_MONOTONIC)`. Cycles are estimated from the 2.0 GHz reported
virtual CPU frequency.

| Operation           | Average us | Median us | Estimated cycles |    ops/s | Failures |
| ------------------- | ---------: | --------: | ---------------: | -------: | -------: |
| `kem_keygen`        |     76.060 |    82.505 |        152119.98 | 13147.52 |        0 |
| `kem_keygen_derand` |     81.470 |    80.055 |        162939.32 | 12274.51 |        0 |
| `kem_enc`           |     41.766 |    41.402 |         83531.34 | 23943.11 |        0 |
| `kem_dec`           |     41.836 |    41.623 |         83672.36 | 23902.76 |        0 |

## ZEN_256 Sizes And Memory

| Item                 |   Bytes |
| -------------------- | ------: |
| Public key           |    1229 |
| Secret key           |    2605 |
| Ciphertext           |    1024 |
| Shared secret        |      32 |
| Static text/rodata   |   57032 |
| Static writable      |  139776 |
| Static total         |  196808 |
| Peak RSS after tests | 1875968 |
| Benchmark context    |    5050 |

## ZEN_512 Performance

Results are averages over 1000 measured iterations. Time is wall-clock time from
`clock_gettime(CLOCK_MONOTONIC)`. Cycles are estimated from the 2.0 GHz reported
virtual CPU frequency.

| Operation           | Average us | Median us | Estimated cycles |   ops/s | Failures |
| ------------------- | ---------: | --------: | ---------------: | ------: | -------: |
| `kem_keygen`        |    219.428 |   159.381 |        438856.68 | 4557.30 |        0 |
| `kem_keygen_derand` |    152.660 |   151.850 |        305320.25 | 6550.50 |        0 |
| `kem_enc`           |    122.324 |   121.658 |        244647.35 | 8175.03 |        0 |
| `kem_dec`           |    123.427 |   122.758 |        246853.41 | 8101.97 |        0 |

## ZEN_512 Sizes And Memory

| Item                 |   Bytes |
| -------------------- | ------: |
| Public key           |    2458 |
| Secret key           |    5210 |
| Ciphertext           |    2048 |
| Shared secret        |      64 |
| Static text/rodata   |  114536 |
| Static writable      |   82272 |
| Static total         |  196808 |
| Peak RSS after tests | 1875968 |
| Benchmark context    |    9972 |

