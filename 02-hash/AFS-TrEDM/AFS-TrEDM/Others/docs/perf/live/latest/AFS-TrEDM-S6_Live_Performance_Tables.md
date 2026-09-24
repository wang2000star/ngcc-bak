# AFS-TrEDM-S6 Live Performance Tables

- run_id: `20260629T082144Z_pid46757_0de6f7dc`
- timestamp: `2026-06-29T08:22:59Z`
- hostname: `Matrix-5860`
- compiler: `cc (Ubuntu 11.4.0-1ubuntu1~22.04.3) 11.4.0`
- OpenSSL: `OpenSSL 3.0.2 15 Mar 2022 (Library: OpenSSL 3.0.2 15 Mar 2022)`
- CPU: `Intel(R) Xeon(R) w7-2495X`
- governor: `powersave`

## Cycles per Byte Comparison (cpb)

| Implementation | 64B | 192B | 1KB | 1536B | 64KB | 1MB |
| --- | --- | --- | --- | --- | --- | --- |
| AFS-TrEDM-S6 Reference 512 | 192.69 | 126.19 | 106.04 | 104.23 | 96.16 | 97.86 |
| AFS-TrEDM-S6 Reference 768 | 338.18 | 337.90 | 231.67 | 240.21 | 226.03 | 224.35 |
| AFS-TrEDM-S6 Reference 1024 | 773.61 | 500.78 | 403.44 | 394.59 | 378.80 | 379.95 |
| AFS-TrEDM-S6 Optimized opt64 512 | 23.74 | 15.78 | 12.95 | 12.58 | 11.66 | 11.90 |
| AFS-TrEDM-S6 Optimized opt64 768 | 39.20 | 38.75 | 26.22 | 27.03 | 25.78 | 25.40 |
| AFS-TrEDM-S6 Optimized opt64 1024 | 93.51 | 61.72 | 48.84 | 48.06 | 46.02 | 46.01 |
| AFS-TrEDM-S6 Optimized AVX2 hybrid 512 | 18.13 | 12.16 | 9.94 | 9.51 | 8.68 | 8.89 |
| AFS-TrEDM-S6 Optimized AVX2 hybrid 768 | 30.03 | 29.45 | 20.32 | 20.86 | 19.64 | 19.68 |
| AFS-TrEDM-S6 Optimized AVX2 hybrid 1024 | 68.50 | 45.41 | 37.08 | 35.47 | 33.95 | 33.91 |
| AFS-TrEDM-S6 Batch16 AVX512 norm 512 | 6.81 | 4.48 | 3.70 | 3.50 | 3.29 | 3.21 |
| AFS-TrEDM-S6 Batch16 AVX512 norm 768 | 11.00 | 10.50 | 7.32 | 7.30 | 6.88 | 6.94 |
| AFS-TrEDM-S6 Batch16 AVX512 norm 1024 | 25.81 | 16.99 | 13.20 | 12.72 | 12.35 | 12.41 |
| SHA3-512 Reference C (XKCP readable) | 170.39 | 174.48 | 162.73 | 157.06 | 151.49 | 151.59 |
| SHA3-512 XKCP CompactFIPS202 (XKCP more-compact) | 191.17 | 191.41 | 178.67 | 175.06 | 170.49 | 170.23 |
| SHA3-512 OpenSSL EVP | 17.90 | 11.00 | 7.91 | 7.56 | 6.92 | 6.92 |

## Cycles per Hash Comparison

| Implementation | 64B | 192B | 1KB | 1536B | 64KB | 1MB |
| --- | --- | --- | --- | --- | --- | --- |
| AFS-TrEDM-S6 Reference 512 | 12332.17 | 24228.15 | 108582.70 | 160096.67 | 6301893.58 | 102616852.50 |
| AFS-TrEDM-S6 Reference 768 | 21643.72 | 64877.11 | 237232.52 | 368962.52 | 14812945.68 | 235247102.00 |
| AFS-TrEDM-S6 Reference 1024 | 49511.35 | 96148.89 | 413122.00 | 606090.19 | 24824760.52 | 398404558.83 |
| AFS-TrEDM-S6 Optimized opt64 512 | 1519.57 | 3029.49 | 13263.54 | 19329.69 | 764142.48 | 12481266.46 |
| AFS-TrEDM-S6 Optimized opt64 768 | 2508.85 | 7439.38 | 26849.39 | 41523.24 | 1689469.74 | 26634539.33 |
| AFS-TrEDM-S6 Optimized opt64 1024 | 5984.63 | 11849.59 | 50011.67 | 73827.64 | 3015761.44 | 48244335.17 |
| AFS-TrEDM-S6 Optimized AVX2 hybrid 512 | 1160.10 | 2334.47 | 10176.09 | 14602.04 | 568991.45 | 9320702.81 |
| AFS-TrEDM-S6 Optimized AVX2 hybrid 768 | 1922.17 | 5653.55 | 20805.77 | 32044.05 | 1287363.37 | 20631880.08 |
| AFS-TrEDM-S6 Optimized AVX2 hybrid 1024 | 4383.93 | 8719.58 | 37974.32 | 54487.92 | 2225263.31 | 35561777.42 |
| AFS-TrEDM-S6 Batch16 AVX512 norm 512 | 436.11 | 859.89 | 3784.37 | 5370.76 | 215806.97 | 3367059.18 |
| AFS-TrEDM-S6 Batch16 AVX512 norm 768 | 703.93 | 2015.68 | 7495.69 | 11213.40 | 450732.58 | 7277285.68 |
| AFS-TrEDM-S6 Batch16 AVX512 norm 1024 | 1651.87 | 3263.01 | 13514.61 | 19542.76 | 809323.81 | 13014967.98 |
| SHA3-512 Reference C (XKCP readable) | 10905.21 | 33500.34 | 166630.69 | 241244.40 | 9927929.37 | 158949551.50 |
| SHA3-512 XKCP CompactFIPS202 (XKCP more-compact) | 12234.82 | 36750.07 | 182957.49 | 268889.73 | 11172935.01 | 178502343.68 |
| SHA3-512 OpenSSL EVP | 1145.29 | 2112.80 | 8102.30 | 11609.19 | 453778.69 | 7260473.45 |

## Throughput Comparison (MB/s)

| Implementation | 64B | 192B | 1KB | 1536B | 64KB | 1MB |
| --- | --- | --- | --- | --- | --- | --- |
| AFS-TrEDM-S6 Reference 512 | 12.954 | 19.780 | 23.539 | 23.947 | 25.957 | 25.506 |
| AFS-TrEDM-S6 Reference 768 | 7.381 | 7.387 | 10.774 | 10.391 | 11.044 | 11.125 |
| AFS-TrEDM-S6 Reference 1024 | 3.226 | 4.985 | 6.187 | 6.326 | 6.589 | 6.569 |
| AFS-TrEDM-S6 Optimized opt64 512 | 105.128 | 158.193 | 192.707 | 198.347 | 214.074 | 209.701 |
| AFS-TrEDM-S6 Optimized opt64 768 | 63.674 | 64.420 | 95.197 | 92.332 | 96.824 | 98.268 |
| AFS-TrEDM-S6 Optimized opt64 1024 | 26.694 | 40.445 | 51.108 | 51.932 | 54.243 | 54.251 |
| AFS-TrEDM-S6 Optimized AVX2 hybrid 512 | 137.703 | 205.291 | 251.175 | 262.564 | 287.496 | 280.808 |
| AFS-TrEDM-S6 Optimized AVX2 hybrid 768 | 83.109 | 84.769 | 122.849 | 119.647 | 127.067 | 126.858 |
| AFS-TrEDM-S6 Optimized AVX2 hybrid 1024 | 36.439 | 54.962 | 67.308 | 70.364 | 73.511 | 73.600 |
| AFS-TrEDM-S6 Batch16 AVX512 norm 512 | 366.303 | 557.340 | 675.406 | 713.861 | 758.005 | 777.332 |
| AFS-TrEDM-S6 Batch16 AVX512 norm 768 | 226.938 | 237.759 | 340.994 | 341.910 | 362.926 | 359.657 |
| AFS-TrEDM-S6 Batch16 AVX512 norm 1024 | 96.708 | 146.872 | 189.127 | 196.184 | 202.122 | 201.101 |
| SHA3-512 Reference C (XKCP readable) | 14.649 | 14.306 | 15.339 | 15.892 | 16.477 | 16.466 |
| SHA3-512 XKCP CompactFIPS202 (XKCP more-compact) | 13.057 | 13.041 | 13.970 | 14.259 | 14.641 | 14.663 |
| SHA3-512 OpenSSL EVP | 139.483 | 226.830 | 315.464 | 330.253 | 360.491 | 360.490 |

## Latency Comparison (milliseconds)

| Implementation | 64B | 192B | 1KB | 1536B | 64KB | 1MB |
| --- | --- | --- | --- | --- | --- | --- |
| AFS-TrEDM-S6 Reference 512 | 0.004940620 | 0.009706500 | 0.043501500 | 0.064139370 | 2.524724600 | 41.111330190 |
| AFS-TrEDM-S6 Reference 768 | 0.008671120 | 0.025991580 | 0.095042390 | 0.147816840 | 5.934488770 | 94.246824580 |
| AFS-TrEDM-S6 Reference 1024 | 0.019835670 | 0.038519980 | 0.165508670 | 0.242817550 | 9.945511820 | 159.612417220 |
| AFS-TrEDM-S6 Optimized opt64 512 | 0.000608780 | 0.001213700 | 0.005313750 | 0.007744040 | 0.306137460 | 5.000352860 |
| AFS-TrEDM-S6 Optimized opt64 768 | 0.001005120 | 0.002980430 | 0.010756670 | 0.016635470 | 0.676850230 | 10.670582450 |
| AFS-TrEDM-S6 Optimized opt64 1024 | 0.002397620 | 0.004747290 | 0.020036080 | 0.029577500 | 1.208199560 | 19.328077630 |
| AFS-TrEDM-S6 Optimized AVX2 hybrid 512 | 0.000464770 | 0.000935260 | 0.004076830 | 0.005850000 | 0.227953870 | 3.734144070 |
| AFS-TrEDM-S6 Optimized AVX2 hybrid 768 | 0.000770080 | 0.002264980 | 0.008335400 | 0.012837770 | 0.515756380 | 8.265728750 |
| AFS-TrEDM-S6 Optimized AVX2 hybrid 1024 | 0.001756330 | 0.003493310 | 0.015213630 | 0.021829460 | 0.891505930 | 14.247079690 |
| AFS-TrEDM-S6 Batch16 AVX512 norm 512 | 0.000174719 | 0.000344494 | 0.001516125 | 0.002151680 | 0.086458437 | 1.348941406 |
| AFS-TrEDM-S6 Batch16 AVX512 norm 768 | 0.000282016 | 0.000807541 | 0.003002988 | 0.004492406 | 0.180576875 | 2.915488281 |
| AFS-TrEDM-S6 Batch16 AVX512 norm 1024 | 0.000661788 | 0.001307259 | 0.005414337 | 0.007829375 | 0.324238750 | 5.214171875 |
| SHA3-512 Reference C (XKCP readable) | 0.004368940 | 0.013421170 | 0.066756960 | 0.096649380 | 3.977414970 | 63.679775600 |
| SHA3-512 XKCP CompactFIPS202 (XKCP more-compact) | 0.004901630 | 0.014723120 | 0.073298060 | 0.107724960 | 4.476200040 | 71.513187890 |
| SHA3-512 OpenSSL EVP | 0.000458840 | 0.000846450 | 0.003246010 | 0.004650970 | 0.181796250 | 2.908748390 |

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

## SHA3-512 Baseline Throughput Comparison (MB/s)

| Message Size | SHA3-512 Reference C (XKCP readable) | SHA3-512 XKCP CompactFIPS202 (XKCP more-compact) | SHA3-512 OpenSSL EVP |
| --- | --- | --- | --- |
| 64B | 14.649 | 13.057 | 139.483 |
| 192B | 14.306 | 13.041 | 226.830 |
| 1KB | 15.339 | 13.970 | 315.464 |
| 1536B | 15.892 | 14.259 | 330.253 |
| 64KB | 16.477 | 14.641 | 360.491 |
| 1MB | 16.466 | 14.663 | 360.490 |

## SHA3-512 Baseline Latency Comparison (ms per message)

| Message Size | SHA3-512 Reference C (XKCP readable) | SHA3-512 XKCP CompactFIPS202 (XKCP more-compact) | SHA3-512 OpenSSL EVP |
| --- | --- | --- | --- |
| 64B | 0.004368940 | 0.004901630 | 0.000458840 |
| 192B | 0.013421170 | 0.014723120 | 0.000846450 |
| 1KB | 0.066756960 | 0.073298060 | 0.003246010 |
| 1536B | 0.096649380 | 0.107724960 | 0.004650970 |
| 64KB | 3.977414970 | 4.476200040 | 0.181796250 |
| 1MB | 63.679775600 | 71.513187890 | 2.908748390 |

## SHA3-512 Baseline Cycles per Hash Comparison

| Message Size | SHA3-512 Reference C (XKCP readable) | SHA3-512 XKCP CompactFIPS202 (XKCP more-compact) | SHA3-512 OpenSSL EVP |
| --- | --- | --- | --- |
| 64B | 10905.21 | 12234.82 | 1145.29 |
| 192B | 33500.34 | 36750.07 | 2112.80 |
| 1KB | 166630.69 | 182957.49 | 8102.30 |
| 1536B | 241244.40 | 268889.73 | 11609.19 |
| 64KB | 9927929.37 | 11172935.01 | 453778.69 |
| 1MB | 158949551.50 | 178502343.68 | 7260473.45 |

## SHA3-512 Baseline Cycles per Byte Comparison

| Message Size | SHA3-512 Reference C (XKCP readable) | SHA3-512 XKCP CompactFIPS202 (XKCP more-compact) | SHA3-512 OpenSSL EVP |
| --- | --- | --- | --- |
| 64B | 170.39 | 191.17 | 17.90 |
| 192B | 174.48 | 191.41 | 11.00 |
| 1KB | 162.73 | 178.67 | 7.91 |
| 1536B | 157.06 | 175.06 | 7.56 |
| 64KB | 151.49 | 170.49 | 6.92 |
| 1MB | 151.59 | 170.23 | 6.92 |

## Combined 512 Cycles per Byte Summary

| Backend | 1MiB cycles/byte | Metric class |
| --- | --- | --- |
| AFS-TrEDM-S6 Reference 512 | 97.86 | single-message latency/throughput |
| AFS-TrEDM-S6 Optimized opt64 512 | 11.90 | single-message latency/throughput |
| AFS-TrEDM-S6 Optimized AVX2 hybrid 512 | 8.89 | single-message latency/throughput |
| AFS-TrEDM-S6 Batch16 AVX512 norm 512 | 3.21 | multi-buffer normalized throughput |
| SHA3-512 Reference C (XKCP readable) | 151.59 | single-message latency/throughput |
| SHA3-512 XKCP CompactFIPS202 (XKCP more-compact) | 170.23 | single-message latency/throughput |
| SHA3-512 OpenSSL EVP | 6.92 | single-message latency/throughput |

AFS-TrEDM-S6 Batch16 AVX512 norm is a multi-buffer normalized throughput backend. Its latency, cycles/hash, and cpb are normalized per message across a 16-message batch and must not be interpreted as single-message latency.

AFS-TrEDM-S6 Optimized AVX2 hybrid is a single-message backend using an AVX2 AFS-64 nonlinear layer plus generated opt64 S6 linear layer.
It is not a full AVX2 implementation of the S6 linear layer unless explicitly stated.

## SHA3-512 baseline taxonomy

- SHA3-512 Reference C (XKCP readable): official XKCP Standalone/CompactFIPS202/C/Keccak-readable-and-compact.c, reference-style baseline.
- SHA3-512 XKCP CompactFIPS202 (XKCP more-compact): distinct official XKCP Standalone/CompactFIPS202/C/Keccak-more-compact.c compact baseline.
- SHA3-512 OpenSSL EVP: single-message deployment baseline measured through OpenSSL EVP_sha3_512().
- SHA3-512 Reference C and XKCP CompactFIPS202 are external baselines, not AFS-TrEDM implementations.
- None of these SHA3 baselines is part of AFS-TrEDM's Reference_Implementation or Optimized_Implementation.
- All SHA3-512 baselines are fresh single-message baselines in this package.
- There is no true SHA3-512 Batch16 backend in this Stage16 package.
Display labels 1KB, 64KB, and 1MB correspond to 1024, 65536, and 1048576 bytes in CSV metadata.

