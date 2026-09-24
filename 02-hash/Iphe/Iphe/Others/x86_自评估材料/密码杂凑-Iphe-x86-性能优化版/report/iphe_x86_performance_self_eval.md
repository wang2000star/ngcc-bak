# Iphe x86 性能优化版自评估报告

## 1. 算法基本信息

- 算法类别：密码杂凑算法。
- 算法名称：Iphe。
- 细分功能：生成杂凑值。
- 实现版本：性能优化版。
- 算法实例：Iphe-512（输出 512 bit / 64 Bytes）、Iphe-768（输出 768 bit / 96 Bytes）、Iphe-1024（输出 1024 bit / 128 Bytes）。
- 参数集/安全级别：以摘要输出长度区分三个参数集；具体安全级别仅作为目标安全强度，需以正式算法说明为准。
- 实现定位：吞吐率优先实现，保持算法输出格式与官方接口语义不变。

## 2. 评估环境信息

- 处理器型号：Intel(R) Core(TM) Ultra 7 251HX
- 处理器主频：2900 MHz
- 核心数：18
- 逻辑处理器数：18
- 内存：15.43 GB

- 操作系统：Windows 11 家庭版 中文版
- 系统版本：25H2
- OS 内部版本：26200.8655
- 系统架构：x86_64 / 64 位

- 测试环境：MSYS2 UCRT64
- MSYS2 运行环境：UCRT64
- MSYS2 uname 信息：MINGW64_NT-10.0-26200 Aya 3.6.9-aa532e7b.x86_64 2026-04-21 17:18 UTC x86_64 Msys
- MSYS2 runtime：msys2-runtime 3.6.9-1

- 编译器：gcc.exe (Rev5, Built by MSYS2 project) 16.1.0
- 构建工具：CMake 4.3.2

- NGCC：自评估测试框架，用于生成本报告中的功能、性能和资源测试证据。
- 编译参数：`-O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra`。
- S1-S8 证据时间范围：2026-06-25 10:47 至 2026-06-25 10:49。
- CPU 固定/绑核：固定至逻辑 CPU 0，亲和性 mask 0x1。
- cycles 计数方式：x86 `__rdtscp` 读取时间戳计数器；每个测试点重复 1000 次并报告平均 cycles。

## 3. 功能测试

官方 KAT 作为本节主要功能测试向量；S1-S8 仅用于性能测试，不作为官方 KAT。已有 KAT 文件覆盖三实例的 KAT_2_12、KAT_2_23、KAT_2_33 和 KAT_Loop，本轮未重新运行 KAT_CryptHash.exe。NGCC functional self-test 作为辅助正确性测试，结果为 PASS。

### Iphe-512

| 测试项 | 覆盖内容 | 结果 |
|---|---|---|
| KAT_2_12 | 0 至 2^12 bit 消息 | PASS（已有 KAT 文件） |
| KAT_2_23 | 2^23 bit 消息 | PASS（已有 KAT 文件） |
| KAT_2_33 | 2^33 bit 消息 | PASS（已有 KAT 文件） |
| KAT_Loop | 2^13 bit loop 测试 | PASS（已有 KAT 文件） |
| NGCC functional self-test | long input 与 short input | PASS |

### Iphe-768

| 测试项 | 覆盖内容 | 结果 |
|---|---|---|
| KAT_2_12 | 0 至 2^12 bit 消息 | PASS（已有 KAT 文件） |
| KAT_2_23 | 2^23 bit 消息 | PASS（已有 KAT 文件） |
| KAT_2_33 | 2^33 bit 消息 | PASS（已有 KAT 文件） |
| KAT_Loop | 2^13 bit loop 测试 | PASS（已有 KAT 文件） |
| NGCC functional self-test | long input 与 short input | PASS |

### Iphe-1024

| 测试项 | 覆盖内容 | 结果 |
|---|---|---|
| KAT_2_12 | 0 至 2^12 bit 消息 | PASS（已有 KAT 文件） |
| KAT_2_23 | 2^23 bit 消息 | PASS（已有 KAT 文件） |
| KAT_2_33 | 2^33 bit 消息 | PASS（已有 KAT 文件） |
| KAT_Loop | 2^13 bit loop 测试 | PASS（已有 KAT 文件） |
| NGCC functional self-test | long input 与 short input | PASS |

## 4. 性能测试

NGCC 原始吞吐量单位为 Mbit/s（Mbps）；本报告正式吞吐量使用 MB/s，并逐行按 `MB/s = Mbps / 8` 换算。每个测试点重复 1000 次。

### Iphe-512

| 输入长度 / Bytes | 平均周期数 / cycles | 吞吐量 / MB/s |
|---:|---:|---:|
| 32 | 3962.07 | 27.88 |
| 128 | 2428.17 | 179.35 |
| 512 | 5418.43 | 263.54 |
| 1024 | 11205.75 | 324.93 |
| 4096 | 37461.11 | 361.72 |
| 8192 | 70300.08 | 373.88 |
| 16384 | 106427.96 | 443.16 |
| 65536 | 305694.60 | 542.13 |

### Iphe-768

| 输入长度 / Bytes | 平均周期数 / cycles | 吞吐量 / MB/s |
|---:|---:|---:|
| 32 | 2370.99 | 44.66 |
| 128 | 1939.02 | 228.86 |
| 512 | 7714.28 | 214.86 |
| 1024 | 12074.24 | 292.81 |
| 4096 | 39321.22 | 314.62 |
| 8192 | 77269.92 | 317.98 |
| 16384 | 113428.23 | 345.70 |
| 65536 | 389442.20 | 492.34 |

### Iphe-1024

| 输入长度 / Bytes | 平均周期数 / cycles | 吞吐量 / MB/s |
|---:|---:|---:|
| 32 | 2747.26 | 39.48 |
| 128 | 4530.16 | 95.30 |
| 512 | 9084.15 | 179.78 |
| 1024 | 14971.29 | 229.91 |
| 4096 | 55629.43 | 242.38 |
| 8192 | 92682.46 | 248.05 |
| 16384 | 128970.85 | 301.56 |
| 65536 | 444685.65 | 415.85 |

## 5. 资源消耗测试

本报告中，静态 section 由静态库 section 解析得到，属于实测解析结果；栈峰值由 GCC -fstack-usage 输出结合最深调用链进行静态分析得到。因此，算法自身峰值内存上界按“静态 section 实测值 + 栈峰值静态分析值”计算。Working Set 和 Commit peak 为完整 NGCC 测试进程级实测值，仅作为旁注，不作为算法自身峰值内存。

### Iphe-512

- 静态 section 实测值：text 6944 B；data 704 B；bss 0 B；合计 7648 B。
- 栈峰值静态分析值：1024 B。Performance 无递归，栈峰值静态分析值主要来自 CryptHash、permutation 临时变量和编译器 spill/alignment。
- 算法自身峰值内存上界：8672 B。
- 进程级旁注：Working Set peak 4403200 B；Commit peak 733184 B。

### Iphe-768

- 静态 section 实测值：text 7040 B；data 704 B；bss 0 B；合计 7744 B。
- 栈峰值静态分析值：1008 B。Performance 无递归，栈峰值静态分析值主要来自 CryptHash、permutation 临时变量和编译器 spill/alignment。
- 算法自身峰值内存上界：8752 B。
- 进程级旁注：Working Set peak 2555904 B；Commit peak 454656 B。

### Iphe-1024

- 静态 section 实测值：text 8416 B；data 808 B；bss 0 B；合计 9224 B。
- 栈峰值静态分析值：1088 B。Performance 无递归，栈峰值静态分析值主要来自 CryptHash、permutation 临时变量和编译器 spill/alignment。
- 算法自身峰值内存上界：10312 B。
- 进程级旁注：Working Set peak 2555904 B；Commit peak 454656 B。

## 原始证据索引

### KAT 功能测试证据

- 指标：官方 KAT 向量覆盖情况。
- 输入数据：KAT_2_12、KAT_2_23、KAT_2_33、KAT_Loop。
- KAT 文件：`../self_eval/evidence/kat/`。
- KAT 状态说明：`../self_eval/evidence/checks/kat_status.md`。
- KAT 生成程序源码备份：`../self_eval/evidence/scripts/kat/`。

### NGCC functional self-test 证据

- 指标：adapter functional self-test。
- 测试命令：`ngcc_bench.exe -a <algorithm-id> -t 1000 -l <bytes>`；algorithm-id 为 iphe-512-perf、iphe-768-perf、iphe-1024-perf。
- 原始 JSON：`../self_eval/evidence/ngcc_json/`。
- 原始日志：`../self_eval/evidence/ngcc_log/`。

### S1-S8 性能测试证据

- 指标：平均周期数、吞吐量。
- 输入数据：S1-S8，32 Bytes、128 Bytes、512 Bytes、1024 Bytes、4096 Bytes、8192 Bytes、16384 Bytes、65536 Bytes。
- 绑核说明：固定至逻辑 CPU 0，亲和性 mask 0x1。
- 原始 JSON：`../self_eval/evidence/ngcc_json/`。
- 原始日志：`../self_eval/evidence/ngcc_log/`。
- 汇总文件：`../self_eval/evidence/csv/iphe_ngcc_s1_s8_performance.csv`、`../self_eval/evidence/csv/iphe_ngcc_s1_s8_performance.md`。
- 运行脚本：`../self_eval/evidence/scripts/run_affinity_s1s8.ps1`。
- 运行日志：`../self_eval/evidence/checks/affinity_run_log.txt`。

### 资源消耗测试证据

- 指标：text、data、bss、静态 section 合计、栈峰值静态分析值、算法自身峰值内存上界、进程级 Working Set 和 Commit peak。
- 原始 JSON：`../self_eval/evidence/ngcc_json/`。
- 静态库审计：`../self_eval/evidence/audit/`。
- 栈使用文件：`../self_eval/evidence/stack_usage/`。
- 汇总文件：`../self_eval/evidence/csv/iphe_ngcc_memory_stack_performance.csv`。

### 数据完整性与源码一致性证据

- 完整性检查：`../self_eval/evidence/checks/iphe_ngcc_data_completeness_check.md`。
- 源码一致性验证：`../self_eval/evidence/checks/source_copy_verification.csv`。
- 文件清单：`../self_eval/evidence/checks/manifest.csv`。
