# S1-S8 性能波动与异常分析

本文件为补充分析，不修改三份正式自评估报告中的原始 S1-S8 性能表。复测数据仅用于解释局部吞吐量或 cycles 非单调现象。

## 5.1 总体现象

- 静态扫描覆盖 72 个点，标记 41 个需要关注的局部波动点。
- 全量轻量复测覆盖 72 个版本/实例/长度组合；重点复测点数为 27。
- S1-S8 吞吐量整体随输入长度增加呈上升并在中长消息区间趋于稳定，但局部点存在非单调。
- 所有复测输出均显示 functional self-test PASS；当前分析未发现功能正确性异常。
- 高 CV 点数：24；这类点更倾向于测量波动或系统调度影响。
- 初步稳定复现点数：18；方向不稳定或偏差较大的点数：23。

## 5.2 可能原因分类

### 分块与 padding 边界

Iphe 按 rate 分块处理，Iphe-512、Iphe-768、Iphe-1024 的 rate 分别为 184、152、120 Bytes。输入长度增长时，实际处理块数呈阶梯变化，padding 尾块也会引入固定成本。cycles/block 在块数变化附近会出现局部波动，因此吞吐量不要求严格单调。

### 测量窗口与计时口径

cycles 使用 `__rdtscp` 计数，MB/s 来自 NGCC 的 elapsed time 口径，两者测量窗口并不完全等价。短测试窗口下，系统计时粒度、上下文切换和缓存状态会让 cycles 与 MB/s 在局部点上不完全同步。

### Windows 调度与频率波动

复测脚本使用逻辑 CPU 0 亲和性运行，但 Windows 中断、后台任务、睿频和功耗策略仍会影响短时吞吐。混合核平台上固定亲和性不能完全消除频率与调度噪声。

### 短消息固定开销

32、128、512 Bytes 等短消息更容易受函数调用、adapter、benchmark 框架和计时开销影响。短消息点的 MB/s 不应过度解读，cycles 更适合作为补充观察。

### 缓存、代码布局与分支预测

Performance 版本使用更激进的优化结构，可能受 I-cache、展开代码布局和分支预测影响；Resource 版本采用 `-Os` 和更紧凑结构，局部长度下固定开销摊销方式不同。这些因素会造成中长消息吞吐量的局部波动。

### NGCC 框架开销

adapter 调用、输入缓冲、JSON/log 生成之前后的进程环境以及统计代码对短输入影响更明显。若复测 CV 较高，该点更应归类为测量稳定性问题。

## 5.3 结论分级

### 稳定结构性现象

- Performance iphe-1024-perf 1024 Bytes：复测 median 与原始值偏差较小，局部波动可结合分块/固定开销解释。
- Performance iphe-768-perf 1024 Bytes：复测 median 与原始值偏差较小，局部波动可结合分块/固定开销解释。
- Reference iphe-1024 128 Bytes：复测 median 与原始值偏差较小，局部波动可结合分块/固定开销解释。
- Reference iphe-1024 512 Bytes：复测 median 与原始值偏差较小，局部波动可结合分块/固定开销解释。
- Reference iphe-1024 4096 Bytes：复测 median 与原始值偏差较小，局部波动可结合分块/固定开销解释。
- Reference iphe-512 512 Bytes：复测 median 与原始值偏差较小，局部波动可结合分块/固定开销解释。
- Reference iphe-768 512 Bytes：复测 median 与原始值偏差较小，局部波动可结合分块/固定开销解释。
- Reference iphe-768 16384 Bytes：复测 median 与原始值偏差较小，局部波动可结合分块/固定开销解释。
- Reference iphe-768 65536 Bytes：复测 median 与原始值偏差较小，局部波动可结合分块/固定开销解释。
- Resource iphe-1024-res 512 Bytes：复测 median 与原始值偏差较小，局部波动可结合分块/固定开销解释。
- Resource iphe-1024-res 1024 Bytes：复测 median 与原始值偏差较小，局部波动可结合分块/固定开销解释。
- Resource iphe-1024-res 65536 Bytes：复测 median 与原始值偏差较小，局部波动可结合分块/固定开销解释。
- Resource iphe-512-res 1024 Bytes：复测 median 与原始值偏差较小，局部波动可结合分块/固定开销解释。
- Resource iphe-512-res 8192 Bytes：复测 median 与原始值偏差较小，局部波动可结合分块/固定开销解释。
- Resource iphe-768-res 128 Bytes：复测 median 与原始值偏差较小，局部波动可结合分块/固定开销解释。
- Resource iphe-768-res 512 Bytes：复测 median 与原始值偏差较小，局部波动可结合分块/固定开销解释。
- Resource iphe-768-res 8192 Bytes：复测 median 与原始值偏差较小，局部波动可结合分块/固定开销解释。
- Resource iphe-768-res 65536 Bytes：复测 median 与原始值偏差较小，局部波动可结合分块/固定开销解释。

### 测量波动

- Performance iphe-1024-perf 128 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Performance iphe-1024-perf 512 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Performance iphe-1024-perf 16384 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Performance iphe-1024-perf 65536 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Performance iphe-512-perf 128 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Performance iphe-512-perf 512 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Performance iphe-512-perf 1024 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Performance iphe-512-perf 65536 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Performance iphe-768-perf 128 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Performance iphe-768-perf 512 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Performance iphe-768-perf 65536 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Reference iphe-1024 1024 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Reference iphe-512 128 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Reference iphe-512 1024 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Reference iphe-512 4096 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Reference iphe-768 128 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Reference iphe-768 4096 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Reference iphe-768 8192 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Resource iphe-1024-res 128 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Resource iphe-1024-res 4096 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Resource iphe-512-res 128 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Resource iphe-512-res 512 Bytes：复测偏差或 CV 较高，归类为测量波动。
- Resource iphe-768-res 4096 Bytes：复测偏差或 CV 较高，归类为测量波动。

### 需进一步排查

本轮未发现明确指向代码错误的异常。若后续需要进一步降低波动，可增加每点运行时长、提高重复次数、关闭后台负载，并记录 CPU 频率和核心类型。

## 5.4 是否建议修改正式报告

本轮不建议改动正式报告中的原始性能表数据。建议在正式报告性能测试章节补充说明：

> 由于哈希计算按 rate 分块并包含固定开销、padding 尾块处理和测试框架开销，S1–S8 吞吐量随输入长度整体上升并趋于稳定，但局部长度点可能存在非单调波动。复测分析显示该现象主要来自分块边界、固定开销摊销和 Windows 计时/调度噪声，不影响功能正确性。原始复测数据和异常分析见 `self_eval/evidence/checks/performance_anomaly_analysis.md`。

## 证据文件

- 静态扫描：`performance_anomaly_scan.csv`、`performance_anomaly_scan.md`。
- 复测汇总：`performance_retest_summary.csv`、`performance_retest_summary.md`。
- 重点复测点：`performance_retest_focus_points.csv`。
- 各版本复测原始 JSON/log：各版本 `self_eval/evidence/retest/`。
