# NICCS x86 自评估测试报告（KEX）

生成时间：2026-06-29T13:23:51

## 1. 评估环境

| 项目 | 配置 |
| --- | --- |
| 处理器 | INTEL(R) XEON(R) PLATINUM 8582C |
| 主频 (MHz) | 2600.000 |
| 内存 | 129582932 kB |
| 操作系统 | veLinux GNU/Linux 2 (lyra) |
| 内核版本 | 5.15.120.bsk.3-amd64 |
| 编译器 | gcc (Debian 12.2.0-14+deb12u1) 12.2.0 |
| 核心数 | 单核 (single-thread benchmark) |
| 指令集 | x86-64 + AVX2 |

编译选项（与官方指引 3.2 一致）：

- 参考版：`-std=c99 -Wpedantic -Wall -Wextra -O2`
- 性能优化版：`-O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra`
- 资源优化版：`-Os -march=x86-64 -mavx2 -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra`

## 2. 功能测试（正确性）

| 实例 | 版本 | KAT 一致性 |
| --- | --- | --- |
| AFS_KEX_C128 | reference | PASS |
| AFS_KEX_C128 | performance-optimized | PASS |
| AFS_KEX_C128 | resource-optimized | PASS |
| AFS_KEX_C256 | reference | PASS |
| AFS_KEX_C256 | performance-optimized | PASS |
| AFS_KEX_C256 | resource-optimized | PASS |
| AFS_KEX_C512 | reference | PASS |
| AFS_KEX_C512 | performance-optimized | PASS |
| AFS_KEX_C512 | resource-optimized | PASS |

## 3. 性能测试（中位 cycles 与吞吐量 ops/s）

| 实例 | 版本 | 轮数 | 完整密钥交换 cyc | 密钥交换 ops/s |
| --- | --- | ---: | ---: | ---: |
| AFS_KEX_C128 | reference | 4 | 1643408 | 1579.23 |
| AFS_KEX_C128 | performance-optimized | 4 | 381674 | 6778.09 |
| AFS_KEX_C128 | resource-optimized | 4 | 701708 | 3669.79 |
| AFS_KEX_C256 | reference | 4 | 3673292 | 708.26 |
| AFS_KEX_C256 | performance-optimized | 4 | 724698 | 3571.40 |
| AFS_KEX_C256 | resource-optimized | 4 | 1904504 | 1357.16 |
| AFS_KEX_C512 | reference | 4 | 12485876 | 208.32 |
| AFS_KEX_C512 | performance-optimized | 4 | 1976372 | 1316.86 |
| AFS_KEX_C512 | resource-optimized | 4 | 6489194 | 396.13 |

## 4. 资源消耗（静态内存 / 峰值内存）

| 实例 | 版本 | 静态内存 text+data+bss (Bytes) | 峰值内存 RSS (Bytes) |
| --- | --- | ---: | ---: |
| AFS_KEX_C128 | reference | 41544 | 2695168 |
| AFS_KEX_C128 | performance-optimized | 75623 | 2805760 |
| AFS_KEX_C128 | resource-optimized | 38071 | 2764800 |
| AFS_KEX_C256 | reference | 49027 | 2711552 |
| AFS_KEX_C256 | performance-optimized | 81592 | 2732032 |
| AFS_KEX_C256 | resource-optimized | 42546 | 2793472 |
| AFS_KEX_C512 | reference | 49907 | 2715648 |
| AFS_KEX_C512 | performance-optimized | 99784 | 2801664 |
| AFS_KEX_C512 | resource-optimized | 70513 | 2723840 |

## 5. 传输与存储开销（数据尺寸 / 轮数）

| 实例 | 版本 | 轮数 | pk | sk | msg1 | msg2 | msg3 | msg4 | 消息总计 | ss |
| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| AFS_KEX_C128 | reference | 4 | 1568 | 3170 | 768 | 784 | 16 | 0 | 1568 | 16 |
| AFS_KEX_C128 | performance-optimized | 4 | 1568 | 3170 | 768 | 784 | 16 | 0 | 1568 | 16 |
| AFS_KEX_C128 | resource-optimized | 4 | 1568 | 3170 | 768 | 784 | 16 | 0 | 1568 | 16 |
| AFS_KEX_C256 | reference | 4 | 3136 | 6338 | 1440 | 1472 | 32 | 0 | 2944 | 32 |
| AFS_KEX_C256 | performance-optimized | 4 | 3136 | 6338 | 1440 | 1472 | 32 | 0 | 2944 | 32 |
| AFS_KEX_C256 | resource-optimized | 4 | 3136 | 6338 | 1440 | 1472 | 32 | 0 | 2944 | 32 |
| AFS_KEX_C512 | reference | 4 | 6272 | 12674 | 2944 | 3008 | 64 | 0 | 6016 | 64 |
| AFS_KEX_C512 | performance-optimized | 4 | 6272 | 12674 | 2944 | 3008 | 64 | 0 | 6016 | 64 |
| AFS_KEX_C512 | resource-optimized | 4 | 6272 | 12674 | 2944 | 3008 | 64 | 0 | 6016 | 64 |

## 6. 原始证据索引

- 每次执行迭代次数：1000（≥100，满足指引要求）
- 原始日志：`/home/zzh.111/BW_KEM/NGCC-AFS-KEX/benchmark_output/<instance>.<version>.selfeval.log`
- 静态内存原始数据：`/home/zzh.111/BW_KEM/NGCC-AFS-KEX/benchmark_output/<instance>.<version>.size.txt`（`size` 工具输出）
- 汇总 CSV：`selfeval.csv`
- 复现命令：在仓库根目录执行 `./Implementations/benchmark.sh`

