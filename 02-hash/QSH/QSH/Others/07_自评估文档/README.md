# 07_自测文档 —— QSH 实现自评估材料

本目录汇集 QuantaSylva Hash（QSH）算法在 **x86 架构**与 **ARM 架构**下的实现自评估材料，
依据《新一代商用密码算法 x86 架构实现自评估指引》和《新一代商用密码算法 ARM 架构实现自评估指引》组织，
作为提交材料中"可复核的技术证据"，用于说明实现环境、测试过程与测试结果。

自评估覆盖每个架构下的 3 个实现版本——**参考实现版、性能优化版、资源优化版**，
以及 3 个算法实例 **QSH-512 / QSH-768 / QSH-1024**。

---

## 目录结构

```
07_自测文档/
├── README.md                ← 本文件
├── Report_ARM_QSH_自评估.md     根据NGCC指引1-1写的QSH 软件实现自评估报告（AArch64/ARM 平台）
├── Report_x86_QSH_自评估.md     根据NGCC指引1-2写的QSH 软件实现自评估报告（AArch64/ARM 平台）
├── x86架构/
│   ├── 结果记录_x86.md      自评估测试结果记录（环境、功能、性能、资源消耗汇总）
│   ├── results/            原始结果数据（环境、功能、性能、资源、日志）
│   ├── 自评估代码/           自评估测试代码与运行脚本
│   └── 并行性能演示/          parallel_scan.csv（并行扩展性扫描结果）
└── ARM架构/
    └── （结构同上）
```

---

## 各部分说明

### 1. 自评估报告
- `x86架构/自评估报告_x86.md`、`ARM架构/自评估报告_arm.md`
- 包含算法基本信息、评估环境、功能测试结果、性能测试（平均周期数 cycles、吞吐量 MB/s）、
  资源消耗（静态内存、峰值内存）及原始证据索引。

### 2. 测试结果（`测试结果/`）
原始可复核数据：
- `environment*.txt` —— 评估环境（CPU、主频、OS/内核、GCC/CMake 版本、依赖、RNG 方法、指令集）。
- `functional*.txt` —— KAT 功能测试逐项结果（全部 PASS；参考/优化/资源版均与参考实现逐比特一致）。
- `perf_ref.csv` / `perf_opt.csv` / `perf_res.csv` —— 三个版本按数据量分档的性能（含 avg_cycles、cyc_per_byte、throughput_MBps）。
- `static_*.txt` —— 静态内存占用（text/data/bss）。
- `peak_*_small.txt` / `peak_*_big.txt` —— 小/大输入下的峰值内存。
- `warn_*.txt` —— 编译告警（均为空，表示无告警）。
- `selfassess*.log` —— 自评估完整运行日志。

### 3. 自评估代码（`自评估代码/`）
- `kat_check.c` —— 功能正确性（KAT）校验程序。
- `self_assess.c` —— 资源消耗/驱动测试程序。
- `perf_cycles_x86.c` / `perf_cycles_arm.c` —— 时钟周期与吞吐量测量程序。
- `selfassess_x86.sh` / `selfassess_arm.sh`、`run_perf_x86.sh` —— 一键自评估/性能运行脚本。
- `Report_x86_template.md` —— 报告模板。

### 4. 分版本提交材料（`分版本提交材料/`）
按指引"算法类别-算法名-架构-实现版本"命名，每个版本为自包含包，例如
`密码杂凑-QSH-512-x86-资源优化版/`，内含：算法源码（`CryptHash_AlgorithmInstance.c/.h`）、
官方 ICCS 辅助文件（`drng.c/.h`、`KAT_CryptHash.c`）、构建文件（`build.sh`、`CMakeLists.txt`）、
`DEPENDENCIES.txt`（第三方依赖说明）、`ENVIRONMENT.txt`（环境）、`SELF_ASSESSMENT_REPORT.md`（本版报告）。

---

## 备注

- 性能与资源测试均多次执行取统计值（性能档位包含 ≥100 次迭代），输入可复现。
- 第三方依赖：无；仅使用官方 ICCS 的 `drng.c / drng.h / KAT_CryptHash.c`（未修改）。
