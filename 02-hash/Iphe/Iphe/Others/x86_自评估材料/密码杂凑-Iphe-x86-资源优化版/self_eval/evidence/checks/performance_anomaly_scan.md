# S1-S8 性能数据静态异常扫描

本扫描基于三版本正式报告对应 CSV，不修改正式报告原始性能表。cycles/block 使用近似块数 `ceil((input_bytes + 1) / rate)` 计算，用于定位趋势异常，不作为算法精确分块证明。

- 扫描点数：72
- 标记异常点数：41
- 标记阈值：相邻吞吐量变化超过 20%，或吞吐量局部下降，或 cycles 随输入长度增长下降。

## 标记点

| 版本 | 实例 | 输入 Bytes | 原 cycles | 原 MB/s | cycles/block | 标记 | 初步判断 |
|---|---|---:|---:|---:|---:|---|---|
| Reference | Iphe-512 | 128 | 20325.98 | 20.81 | 20325.98 | cycles_nonmonotonic;adjacent_change_335.6% | needs_retest |
| Reference | Iphe-512 | 512 | 58151.27 | 27.20 | 19383.76 | adjacent_change_30.7% | needs_retest |
| Reference | Iphe-512 | 1024 | 66257.57 | 45.56 | 11042.93 | adjacent_change_67.5% | needs_retest |
| Reference | Iphe-512 | 4096 | 261375.95 | 43.40 | 11364.17 | throughput_drop_4.7% | needs_retest |
| Reference | Iphe-768 | 128 | 20806.92 | 20.59 | 20806.92 | adjacent_change_272.0% | needs_retest |
| Reference | Iphe-768 | 512 | 83206.00 | 20.45 | 20801.50 | throughput_drop_0.7% | needs_retest |
| Reference | Iphe-768 | 4096 | 289071.29 | 36.66 | 10706.34 | adjacent_change_74.5% | needs_retest |
| Reference | Iphe-768 | 8192 | 630631.72 | 36.28 | 11678.37 | throughput_drop_1.0% | needs_retest |
| Reference | Iphe-768 | 16384 | 1231739.95 | 44.66 | 11405.00 | adjacent_change_23.1% | needs_retest |
| Reference | Iphe-768 | 65536 | 4928911.95 | 43.88 | 11409.52 | throughput_drop_1.7% | needs_retest |
| Reference | Iphe-1024 | 128 | 41396.33 | 10.16 | 20698.16 | adjacent_change_91.8% | needs_retest |
| Reference | Iphe-1024 | 512 | 75636.95 | 17.45 | 15127.39 | adjacent_change_71.7% | needs_retest |
| Reference | Iphe-1024 | 1024 | 111213.40 | 27.89 | 12357.04 | adjacent_change_59.9% | needs_retest |
| Reference | Iphe-1024 | 4096 | 372563.84 | 27.30 | 10644.68 | throughput_drop_2.1% | needs_retest |
| Performance | Iphe-512 | 128 | 2428.17 | 179.35 | 2428.17 | cycles_nonmonotonic;adjacent_change_543.3% | needs_retest |
| Performance | Iphe-512 | 512 | 5418.43 | 263.54 | 1806.14 | adjacent_change_46.9% | needs_retest |
| Performance | Iphe-512 | 1024 | 11205.75 | 324.93 | 1867.62 | adjacent_change_23.3% | needs_retest |
| Performance | Iphe-512 | 65536 | 305694.60 | 542.13 | 856.29 | adjacent_change_22.3% | needs_retest |
| Performance | Iphe-768 | 128 | 1939.02 | 228.86 | 1939.02 | cycles_nonmonotonic;adjacent_change_412.4% | needs_retest |
| Performance | Iphe-768 | 512 | 7714.28 | 214.86 | 1928.57 | throughput_drop_6.1% | needs_retest |
| Performance | Iphe-768 | 1024 | 12074.24 | 292.81 | 1724.89 | adjacent_change_36.3% | needs_retest |
| Performance | Iphe-768 | 65536 | 389442.20 | 492.34 | 901.49 | adjacent_change_42.4% | needs_retest |
| Performance | Iphe-1024 | 128 | 4530.16 | 95.30 | 2265.08 | adjacent_change_141.4% | needs_retest |
| Performance | Iphe-1024 | 512 | 9084.15 | 179.78 | 1816.83 | adjacent_change_88.7% | needs_retest |
| Performance | Iphe-1024 | 1024 | 14971.29 | 229.91 | 1663.48 | adjacent_change_27.9% | needs_retest |
| Performance | Iphe-1024 | 16384 | 128970.85 | 301.56 | 941.39 | adjacent_change_21.6% | needs_retest |
| Performance | Iphe-1024 | 65536 | 444685.65 | 415.85 | 812.95 | adjacent_change_37.9% | needs_retest |
| Resource | Iphe-512 | 128 | 15983.97 | 17.37 | 15983.97 | cycles_nonmonotonic;adjacent_change_390.6% | needs_retest |
| Resource | Iphe-512 | 512 | 60604.08 | 24.80 | 20201.36 | adjacent_change_42.8% | needs_retest |
| Resource | Iphe-512 | 1024 | 117523.58 | 21.30 | 19587.26 | throughput_drop_14.1% | needs_retest |
| Resource | Iphe-512 | 8192 | 684141.64 | 36.40 | 15203.15 | adjacent_change_51.1% | needs_retest |
| Resource | Iphe-768 | 128 | 27614.03 | 15.00 | 27614.03 | cycles_nonmonotonic;adjacent_change_450.2% | needs_retest |
| Resource | Iphe-768 | 512 | 97763.56 | 14.89 | 24440.89 | throughput_drop_0.7% | needs_retest |
| Resource | Iphe-768 | 4096 | 416841.95 | 29.09 | 15438.59 | adjacent_change_74.7% | needs_retest |
| Resource | Iphe-768 | 8192 | 834268.06 | 28.54 | 15449.41 | throughput_drop_1.9% | needs_retest |
| Resource | Iphe-768 | 65536 | 11598094.41 | 31.41 | 26847.44 | throughput_drop_5.2% | needs_retest |
| Resource | Iphe-1024 | 128 | 53347.75 | 7.65 | 26673.87 | adjacent_change_111.0% | needs_retest |
| Resource | Iphe-1024 | 512 | 107852.93 | 12.50 | 21570.58 | adjacent_change_63.4% | needs_retest |
| Resource | Iphe-1024 | 1024 | 154631.71 | 15.56 | 17181.30 | adjacent_change_24.5% | needs_retest |
| Resource | Iphe-1024 | 4096 | 545376.15 | 23.76 | 15582.18 | adjacent_change_52.7% | needs_retest |
| Resource | Iphe-1024 | 65536 | 16585060.63 | 25.51 | 30320.04 | throughput_drop_2.1% | needs_retest |

## 完整数据

完整逐点扫描结果见 `performance_anomaly_scan.csv`。
