# Iphe x86 参考实现版提交材料说明

本目录对应 Iphe x86 参考实现版 提交材料，包含源代码、自评估工程和数据、自评估报告、依赖说明。

## 目录内容

- source/：存放本版本 Iphe-512、Iphe-768、Iphe-1024 源代码、CMake 构建配置和源码说明。
- self_eval/：存放本版本自评估材料，包括完整可运行 NGCC 自测试工程和本版本原始证据。
- report/：存放本版本自评估报告。
- dependency.md：说明本版本构建和自评估测试所需环境。算法实现本身不依赖第三方密码库，NGCC 仅作为自评估测试框架。

## 证据位置

本版本报告引用的正式原始证据位于 self_eval/evidence/。历史过程材料如存在于 self_eval/legacy/，不作为正式报告引用。

## 运行自评估工程

进入 self_eval/ngcc_bench_iphe_reference/，按该目录 README.md 构建并运行。该工程只注册本版本算法 ID：iphe-512、iphe-768、iphe-1024。