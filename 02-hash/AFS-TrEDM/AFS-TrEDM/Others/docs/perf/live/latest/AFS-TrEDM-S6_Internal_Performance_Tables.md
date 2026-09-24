# AFS-TrEDM-S6 Internal Performance Tables

- run_id: `20260629T082144Z_pid46757_0de6f7dc`
- timestamp: `2026-06-29T08:22:59Z`

## AFS-TrEDM-S6 Internal Throughput Comparison (MB/s)

| Message Size | AFS-TrEDM-S6 Reference 512 | AFS-TrEDM-S6 Reference 768 | AFS-TrEDM-S6 Reference 1024 | AFS-TrEDM-S6 Optimized opt64 512 | AFS-TrEDM-S6 Optimized opt64 768 | AFS-TrEDM-S6 Optimized opt64 1024 | AFS-TrEDM-S6 Optimized AVX2 hybrid 512 | AFS-TrEDM-S6 Optimized AVX2 hybrid 768 | AFS-TrEDM-S6 Optimized AVX2 hybrid 1024 | AFS-TrEDM-S6 Batch16 AVX512 norm 512 | AFS-TrEDM-S6 Batch16 AVX512 norm 768 | AFS-TrEDM-S6 Batch16 AVX512 norm 1024 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 64B | 12.954 | 7.381 | 3.226 | 105.128 | 63.674 | 26.694 | 137.703 | 83.109 | 36.439 | 366.303 | 226.938 | 96.708 |
| 192B | 19.780 | 7.387 | 4.985 | 158.193 | 64.420 | 40.445 | 205.291 | 84.769 | 54.962 | 557.340 | 237.759 | 146.872 |
| 1KB | 23.539 | 10.774 | 6.187 | 192.707 | 95.197 | 51.108 | 251.175 | 122.849 | 67.308 | 675.406 | 340.994 | 189.127 |
| 1536B | 23.947 | 10.391 | 6.326 | 198.347 | 92.332 | 51.932 | 262.564 | 119.647 | 70.364 | 713.861 | 341.910 | 196.184 |
| 64KB | 25.957 | 11.044 | 6.589 | 214.074 | 96.824 | 54.243 | 287.496 | 127.067 | 73.511 | 758.005 | 362.926 | 202.122 |
| 1MB | 25.506 | 11.125 | 6.569 | 209.701 | 98.268 | 54.251 | 280.808 | 126.858 | 73.600 | 777.332 | 359.657 | 201.101 |

## AFS-TrEDM-S6 Internal Latency Comparison (ms per message)

| Message Size | AFS-TrEDM-S6 Reference 512 | AFS-TrEDM-S6 Reference 768 | AFS-TrEDM-S6 Reference 1024 | AFS-TrEDM-S6 Optimized opt64 512 | AFS-TrEDM-S6 Optimized opt64 768 | AFS-TrEDM-S6 Optimized opt64 1024 | AFS-TrEDM-S6 Optimized AVX2 hybrid 512 | AFS-TrEDM-S6 Optimized AVX2 hybrid 768 | AFS-TrEDM-S6 Optimized AVX2 hybrid 1024 | AFS-TrEDM-S6 Batch16 AVX512 norm 512 | AFS-TrEDM-S6 Batch16 AVX512 norm 768 | AFS-TrEDM-S6 Batch16 AVX512 norm 1024 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 64B | 0.004940620 | 0.008671120 | 0.019835670 | 0.000608780 | 0.001005120 | 0.002397620 | 0.000464770 | 0.000770080 | 0.001756330 | 0.000174719 | 0.000282016 | 0.000661788 |
| 192B | 0.009706500 | 0.025991580 | 0.038519980 | 0.001213700 | 0.002980430 | 0.004747290 | 0.000935260 | 0.002264980 | 0.003493310 | 0.000344494 | 0.000807541 | 0.001307259 |
| 1KB | 0.043501500 | 0.095042390 | 0.165508670 | 0.005313750 | 0.010756670 | 0.020036080 | 0.004076830 | 0.008335400 | 0.015213630 | 0.001516125 | 0.003002988 | 0.005414337 |
| 1536B | 0.064139370 | 0.147816840 | 0.242817550 | 0.007744040 | 0.016635470 | 0.029577500 | 0.005850000 | 0.012837770 | 0.021829460 | 0.002151680 | 0.004492406 | 0.007829375 |
| 64KB | 2.524724600 | 5.934488770 | 9.945511820 | 0.306137460 | 0.676850230 | 1.208199560 | 0.227953870 | 0.515756380 | 0.891505930 | 0.086458437 | 0.180576875 | 0.324238750 |
| 1MB | 41.111330190 | 94.246824580 | 159.612417220 | 5.000352860 | 10.670582450 | 19.328077630 | 3.734144070 | 8.265728750 | 14.247079690 | 1.348941406 | 2.915488281 | 5.214171875 |

## AFS-TrEDM-S6 Internal Cycles per Hash Comparison

| Message Size | AFS-TrEDM-S6 Reference 512 | AFS-TrEDM-S6 Reference 768 | AFS-TrEDM-S6 Reference 1024 | AFS-TrEDM-S6 Optimized opt64 512 | AFS-TrEDM-S6 Optimized opt64 768 | AFS-TrEDM-S6 Optimized opt64 1024 | AFS-TrEDM-S6 Optimized AVX2 hybrid 512 | AFS-TrEDM-S6 Optimized AVX2 hybrid 768 | AFS-TrEDM-S6 Optimized AVX2 hybrid 1024 | AFS-TrEDM-S6 Batch16 AVX512 norm 512 | AFS-TrEDM-S6 Batch16 AVX512 norm 768 | AFS-TrEDM-S6 Batch16 AVX512 norm 1024 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 64B | 12332.17 | 21643.72 | 49511.35 | 1519.57 | 2508.85 | 5984.63 | 1160.10 | 1922.17 | 4383.93 | 436.11 | 703.93 | 1651.87 |
| 192B | 24228.15 | 64877.11 | 96148.89 | 3029.49 | 7439.38 | 11849.59 | 2334.47 | 5653.55 | 8719.58 | 859.89 | 2015.68 | 3263.01 |
| 1KB | 108582.70 | 237232.52 | 413122.00 | 13263.54 | 26849.39 | 50011.67 | 10176.09 | 20805.77 | 37974.32 | 3784.37 | 7495.69 | 13514.61 |
| 1536B | 160096.67 | 368962.52 | 606090.19 | 19329.69 | 41523.24 | 73827.64 | 14602.04 | 32044.05 | 54487.92 | 5370.76 | 11213.40 | 19542.76 |
| 64KB | 6301893.58 | 14812945.68 | 24824760.52 | 764142.48 | 1689469.74 | 3015761.44 | 568991.45 | 1287363.37 | 2225263.31 | 215806.97 | 450732.58 | 809323.81 |
| 1MB | 102616852.50 | 235247102.00 | 398404558.83 | 12481266.46 | 26634539.33 | 48244335.17 | 9320702.81 | 20631880.08 | 35561777.42 | 3367059.18 | 7277285.68 | 13014967.98 |

## AFS-TrEDM-S6 Internal Cycles per Byte Comparison

| Message Size | AFS-TrEDM-S6 Reference 512 | AFS-TrEDM-S6 Reference 768 | AFS-TrEDM-S6 Reference 1024 | AFS-TrEDM-S6 Optimized opt64 512 | AFS-TrEDM-S6 Optimized opt64 768 | AFS-TrEDM-S6 Optimized opt64 1024 | AFS-TrEDM-S6 Optimized AVX2 hybrid 512 | AFS-TrEDM-S6 Optimized AVX2 hybrid 768 | AFS-TrEDM-S6 Optimized AVX2 hybrid 1024 | AFS-TrEDM-S6 Batch16 AVX512 norm 512 | AFS-TrEDM-S6 Batch16 AVX512 norm 768 | AFS-TrEDM-S6 Batch16 AVX512 norm 1024 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 64B | 192.69 | 338.18 | 773.61 | 23.74 | 39.20 | 93.51 | 18.13 | 30.03 | 68.50 | 6.81 | 11.00 | 25.81 |
| 192B | 126.19 | 337.90 | 500.78 | 15.78 | 38.75 | 61.72 | 12.16 | 29.45 | 45.41 | 4.48 | 10.50 | 16.99 |
| 1KB | 106.04 | 231.67 | 403.44 | 12.95 | 26.22 | 48.84 | 9.94 | 20.32 | 37.08 | 3.70 | 7.32 | 13.20 |
| 1536B | 104.23 | 240.21 | 394.59 | 12.58 | 27.03 | 48.06 | 9.51 | 20.86 | 35.47 | 3.50 | 7.30 | 12.72 |
| 64KB | 96.16 | 226.03 | 378.80 | 11.66 | 25.78 | 46.02 | 8.68 | 19.64 | 33.95 | 3.29 | 6.88 | 12.35 |
| 1MB | 97.86 | 224.35 | 379.95 | 11.90 | 25.40 | 46.01 | 8.89 | 19.68 | 33.91 | 3.21 | 6.94 | 12.41 |

AFS-TrEDM-S6 Batch16 AVX512 norm is a multi-buffer normalized throughput backend. Its latency, cycles/hash, and cpb are normalized per message across a 16-message batch and must not be interpreted as single-message latency.
Optimized AVX2 hybrid is a single-message backend using an AVX2 AFS-64 nonlinear layer plus generated opt64 S6 linear layer.
SHA3-512 Reference C (XKCP readable) uses official XKCP Standalone/CompactFIPS202/C/Keccak-readable-and-compact.c unless otherwise noted.
SHA3-512 XKCP CompactFIPS202 (XKCP more-compact) is a separate compact XKCP baseline using official Keccak-more-compact.c.
SHA3-512 OpenSSL EVP is a single-message deployment baseline.
SHA3-512 Reference C and XKCP CompactFIPS202 are external baselines, not AFS-TrEDM implementations.
None of these SHA3 baselines is part of AFS-TrEDM's Reference_Implementation or Optimized_Implementation.
No true SHA3-512 batch baseline is claimed in this package unless a separate SHA3 batch backend is implemented and labeled.
