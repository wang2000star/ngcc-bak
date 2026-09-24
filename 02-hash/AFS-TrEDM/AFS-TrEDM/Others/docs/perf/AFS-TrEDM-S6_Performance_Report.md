# AFS-TrEDM-S6 Performance Report

This report is generated from the latest Stage16 live benchmark evidence.

## Live Run

- run_id: `20260614T112832Z_pid5_453af5c8`
- timestamp: `2026-06-14T11:28:51Z`
- mode: `quick`
- compiler: `cc (Ubuntu 11.4.0-1ubuntu1~22.04.3) 11.4.0`
- OpenSSL: `OpenSSL 3.0.2 15 Mar 2022 (Library: OpenSSL 3.0.2 15 Mar 2022)`
- CPU: `Intel(R) Xeon(R) w7-2495X`
- governor: `powersave`
- raw CSV: `docs/perf/live/latest/live_perf_raw.csv`
- summary CSV: `docs/perf/live/latest/live_perf_summary.csv`
- terminal output: `docs/perf/live/latest/terminal_output.txt`

## Measurement Scope

- AFS-TrEDM-S6 Batch16 AVX512 norm is a multi-buffer normalized throughput backend. Its latency, cycles/hash, and cpb are normalized per message across a 16-message batch and must not be interpreted as single-message latency.
- AFS-TrEDM-S6 Optimized AVX2 hybrid is a single-message backend using an AVX2 AFS-64 nonlinear layer plus generated opt64 S6 linear layer.

## SHA3-512 baseline taxonomy

- SHA3-512 Reference C (XKCP readable): official XKCP readable-and-compact C implementation, reference-style baseline.
- SHA3-512 XKCP CompactFIPS202 (XKCP more-compact): official XKCP more-compact CompactFIPS202 implementation, compact baseline.
- SHA3-512 OpenSSL EVP is a single-message deployment baseline.
- SHA3-512 Reference C and XKCP CompactFIPS202 are external baselines, not AFS-TrEDM implementations.
- None of these SHA3 baselines is part of AFS-TrEDM's Reference_Implementation or Optimized_Implementation.
- Close SHA3 baseline performance is acceptable only because source provenance and anti-alias checks are recorded.
- No true SHA3-512 batch baseline is claimed in this package unless a separate SHA3 batch backend is implemented and labeled.

## Main Comparison

| Backend | Instance | Backend identity | Metric class | 64B cpb | 64B MiB/s | 64B cycles/hash | 1MiB cpb | 1MiB MiB/s | 1MiB cycles/hash | Source log |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| AFS-TrEDM-S6-512 Reference | 512 | `reference-o3` | single-message latency/throughput | 224.180000 | 10.641000 | 14347.780000 | 104.490000 | 22.830000 | 109567129.000000 | `docs/perf/live/latest/live_perf_raw.csv` |
| AFS-TrEDM-S6-512 Optimized opt64 | 512 | `opt64-s6` | single-message latency/throughput | 29.490000 | 80.892000 | 1887.080000 | 12.620000 | 189.026000 | 13231257.000000 | `docs/perf/live/latest/live_perf_raw.csv` |
| AFS-TrEDM-S6-512 Optimized AVX2 hybrid | 512 | `avx2-sbox + opt64-s6-linear` | single-message latency/throughput | 20.610000 | 115.731000 | 1318.830000 | 9.770000 | 244.185000 | 10240937.000000 | `docs/perf/live/latest/live_perf_raw.csv` |
| AFS-TrEDM-S6-512 Batch16 AVX512 norm | 512 | `avx512_batch16_true` | multi-buffer normalized throughput | 8.560000 | 278.441000 | 548.020000 | 3.810000 | 625.193000 | 3998617.250000 | `docs/perf/live/latest/live_perf_raw.csv` |
| AFS-TrEDM-S6-768 Reference | 768 | `reference-o3` | single-message latency/throughput | 424.800000 | 5.616000 | 27187.390000 | 251.020000 | 9.503000 | 263211820.000000 | `docs/perf/live/latest/live_perf_raw.csv` |
| AFS-TrEDM-S6-768 Optimized opt64 | 768 | `opt64-s6` | single-message latency/throughput | 43.150000 | 55.274000 | 2761.530000 | 26.390000 | 90.387000 | 27669072.000000 | `docs/perf/live/latest/live_perf_raw.csv` |
| AFS-TrEDM-S6-768 Optimized AVX2 hybrid | 768 | `avx2-sbox + opt64-s6-linear` | single-message latency/throughput | 40.400000 | 59.023000 | 2585.690000 | 24.840000 | 96.009000 | 26043574.000000 | `docs/perf/live/latest/live_perf_raw.csv` |
| AFS-TrEDM-S6-768 Batch16 AVX512 norm | 768 | `avx512_batch16_true` | multi-buffer normalized throughput | 12.980000 | 183.615000 | 830.920000 | 8.120000 | 293.740000 | 8509958.810000 | `docs/perf/live/latest/live_perf_raw.csv` |
| AFS-TrEDM-S6-1024 Reference | 1024 | `reference-o3` | single-message latency/throughput | 849.880000 | 2.807000 | 54392.050000 | 420.480000 | 5.673000 | 440901576.000000 | `docs/perf/live/latest/live_perf_raw.csv` |
| AFS-TrEDM-S6-1024 Optimized opt64 | 1024 | `opt64-s6` | single-message latency/throughput | 116.040000 | 20.552000 | 7426.470000 | 50.470000 | 47.256000 | 52920861.000000 | `docs/perf/live/latest/live_perf_raw.csv` |
| AFS-TrEDM-S6-1024 Optimized AVX2 hybrid | 1024 | `avx2-sbox + opt64-s6-linear` | single-message latency/throughput | 87.310000 | 27.308000 | 5588.070000 | 44.640000 | 53.415000 | 46806353.000000 | `docs/perf/live/latest/live_perf_raw.csv` |
| AFS-TrEDM-S6-1024 Batch16 AVX512 norm | 1024 | `avx512_batch16_true` | multi-buffer normalized throughput | 33.450000 | 71.261000 | 2140.850000 | 14.570000 | 163.599000 | 15278310.310000 | `docs/perf/live/latest/live_perf_raw.csv` |
| SHA3-512 Reference C (XKCP readable) | SHA3-512 | `sha3-512-reference-c-xkcp-readable` | single-message latency/throughput | 212.860000 | 11.199000 | 13623.230000 | 189.040000 | 12.609000 | 198221068.750000 | `docs/perf/live/latest/live_perf_raw.csv` |
| SHA3-512 XKCP CompactFIPS202 (XKCP more-compact) | SHA3-512 | `xkcp-compactfips202-sha3-512-more-compact` | single-message latency/throughput | 230.940000 | 10.322000 | 14780.030000 | 215.440000 | 11.064000 | 225901146.000000 | `docs/perf/live/latest/live_perf_raw.csv` |
| SHA3-512 OpenSSL EVP | SHA3-512 | `openssl-evp-sha3-512` | single-message latency/throughput | 24.410000 | 97.661000 | 1561.940000 | 8.800000 | 270.764000 | 9230380.250000 | `docs/perf/live/latest/live_perf_raw.csv` |

## Required Conclusions

- AFS-TrEDM-S6-512 Batch16 AVX512 norm is faster than SHA3-512 OpenSSL EVP for 1MiB normalized throughput: 3.81 cpb vs 8.80 cpb.
- AFS-TrEDM-S6-512 Optimized AVX2 hybrid single-message remains slower than SHA3-512 OpenSSL EVP at 1MiB: 9.77 cpb vs 8.80 cpb.
- AFS-TrEDM-S6-512 Optimized AVX2 hybrid is faster than SHA3-512 XKCP CompactFIPS202 (XKCP more-compact) at 1MiB in this run: 9.77 cpb vs 215.44 cpb.
- Batch16 AVX512 norm values are normalized over a 16-message batch and must not be described as single-message latency.
- SHA3-512 Reference C (XKCP readable) was freshly executed in this run: 189.04 cpb at 1MiB.
- SHA3-512 Reference C (XKCP readable), SHA3-512 XKCP CompactFIPS202 (XKCP more-compact), and SHA3-512 OpenSSL EVP rows were freshly executed in the current live run.

## Detailed Tables

The full detailed Throughput, Latency, Cycles per Hash, and Cycles per Byte tables for each requested instance are in:

- `docs/perf/live/latest/AFS-TrEDM-S6_Live_Performance_Tables.md`
- `docs/perf/live/latest/AFS-TrEDM-S6_Internal_Performance_Tables.md`
- `docs/perf/live/latest/live_perf_summary.csv`
- `docs/perf/live/latest/live_perf_raw.csv`

The terminal output intentionally uses the four Stage16 main table titles and avoids legacy numbered table labels.
