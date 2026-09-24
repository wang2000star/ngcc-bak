# Iphe x86 资源优化版自评估报告

## 1. 算法基本信息

- 算法类别：密码杂凑算法。
- 算法名称：Iphe。
- 细分功能：生成杂凑值。
- 实现版本：资源优化版。
- 算法实例：Iphe-512（输出 512 bit / 64 Bytes）、Iphe-768（输出 768 bit / 96 Bytes）、Iphe-1024（输出 1024 bit / 128 Bytes）。
- 参数集/安全级别：以摘要输出长度区分三个参数集；具体安全级别仅作为目标安全强度，需以正式算法说明为准。
- 实现定位：资源占用优先实现，通过统一小轮和循环结构降低源码存储与静态代码体积。

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
- 编译参数：`-Os -march=x86-64 -mavx2 -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra`。
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
| 32 | 29282.26 | 3.54 |
| 128 | 15983.97 | 17.37 |
| 512 | 60604.08 | 24.80 |
| 1024 | 117523.58 | 21.30 |
| 4096 | 344589.67 | 24.08 |
| 8192 | 684141.64 | 36.40 |
| 16384 | 1365396.80 | 37.76 |
| 65536 | 6933173.62 | 38.96 |

### Iphe-768

| 输入长度 / Bytes | 平均周期数 / cycles | 吞吐量 / MB/s |
|---:|---:|---:|
| 32 | 28677.92 | 2.73 |
| 128 | 27614.03 | 15.00 |
| 512 | 97763.56 | 14.89 |
| 1024 | 134933.57 | 16.65 |
| 4096 | 416841.95 | 29.09 |
| 8192 | 834268.06 | 28.54 |
| 16384 | 1785009.21 | 33.15 |
| 65536 | 11598094.41 | 31.41 |

### Iphe-1024

| 输入长度 / Bytes | 平均周期数 / cycles | 吞吐量 / MB/s |
|---:|---:|---:|
| 32 | 29344.46 | 3.63 |
| 128 | 53347.75 | 7.65 |
| 512 | 107852.93 | 12.50 |
| 1024 | 154631.71 | 15.56 |
| 4096 | 545376.15 | 23.76 |
| 8192 | 1051152.16 | 25.21 |
| 16384 | 2104623.56 | 26.05 |
| 65536 | 16585060.63 | 25.51 |

## 5. 资源消耗测试

本报告中，静态 section 由静态库 section 解析得到，属于实测解析结果；栈峰值由 GCC -fstack-usage 输出结合最深调用链进行静态分析得到。因此，算法自身峰值内存上界按“静态 section 实测值 + 栈峰值静态分析值”计算。Working Set 和 Commit peak 为完整 NGCC 测试进程级实测值，仅作为旁注，不作为算法自身峰值内存。

### Iphe-512

- 静态 section 实测值：text 912 B；data 336 B；bss 0 B；合计 1248 B。
- 栈峰值静态分析值：1120 B。Resource 的栈峰值静态分析值已计入最深 6 层递归 S。
- 算法自身峰值内存上界：2368 B。
- 进程级旁注：Working Set peak 2551808 B；Commit peak 454656 B。

### Iphe-768

- 静态 section 实测值：text 912 B；data 336 B；bss 0 B；合计 1248 B。
- 栈峰值静态分析值：1120 B。Resource 的栈峰值静态分析值已计入最深 6 层递归 S。
- 算法自身峰值内存上界：2368 B。
- 进程级旁注：Working Set peak 2551808 B；Commit peak 458752 B。

### Iphe-1024

- 静态 section 实测值：text 928 B；data 336 B；bss 0 B；合计 1264 B。
- 栈峰值静态分析值：1120 B。Resource 的栈峰值静态分析值已计入最深 6 层递归 S。
- 算法自身峰值内存上界：2384 B。
- 进程级旁注：Working Set peak 2555904 B；Commit peak 458752 B。

## 原始证据索引

### KAT 功能测试证据

- 指标：官方 KAT 向量覆盖情况。
- 输入数据：KAT_2_12、KAT_2_23、KAT_2_33、KAT_Loop。
- KAT 文件：`../self_eval/evidence/kat/`。
- KAT 状态说明：`../self_eval/evidence/checks/kat_status.md`。
- KAT 生成程序源码备份：`../self_eval/evidence/scripts/kat/`。

### NGCC functional self-test 证据

- 指标：adapter functional self-test。
- 测试命令：`ngcc_bench.exe -a <algorithm-id> -t 1000 -l <bytes>`；algorithm-id 为 iphe-512-res、iphe-768-res、iphe-1024-res。
- 原始 JSON：`../self_eval/evidence/ngcc_json/`。
- 原始日志：`../self_eval/evidence/ngcc_log/`。

### S1-S8 性能测试证据

- 指标：平均周期数、吞吐量。
- 输入数据：S1-S8，32 Bytes、128 Bytes、512 Bytes、1024 Bytes、4096 Bytes、8192 Bytes、16384 Bytes、65536 Bytes。
- 绑核说明：固定至逻辑 CPU 0，亲和性 mask 0x1。
- 原始 JSON：`../self_eval/evidence/ngcc_json/`。
- 原始日志：`../self_eval/evidence/ngcc_log/`。
- 汇总文件：`../self_eval/evidence/csv/iphe_ngcc_s1_s8_resource.csv`、`../self_eval/evidence/csv/iphe_ngcc_s1_s8_resource.md`。
- 运行脚本：`../self_eval/evidence/scripts/run_affinity_s1s8.ps1`。
- 运行日志：`../self_eval/evidence/checks/affinity_run_log.txt`。

### 资源消耗测试证据

- 指标：text、data、bss、静态 section 合计、栈峰值静态分析值、算法自身峰值内存上界、进程级 Working Set 和 Commit peak。
- 原始 JSON：`../self_eval/evidence/ngcc_json/`。
- 静态库审计：`../self_eval/evidence/audit/`。
- 栈使用文件：`../self_eval/evidence/stack_usage/`。
- 汇总文件：`../self_eval/evidence/csv/iphe_ngcc_memory_stack_resource.csv`。

### 数据完整性与源码一致性证据

- 完整性检查：`../self_eval/evidence/checks/iphe_ngcc_data_completeness_check.md`。
- 源码一致性验证：`../self_eval/evidence/checks/source_copy_verification.csv`。
- 文件清单：`../self_eval/evidence/checks/manifest.csv`。
