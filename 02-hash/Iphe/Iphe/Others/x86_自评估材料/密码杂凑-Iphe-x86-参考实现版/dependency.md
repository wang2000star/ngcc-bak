# 参考实现版依赖说明

## 环境

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

## 构建与自评估工具

- NGCC：自评估测试框架，用于生成测试过程和测试结果证据，不是 Iphe 算法运行依赖。
- GNU binutils：用于静态库成员、符号和 section 审计。
- GCC `-fstack-usage`：用于生成栈使用静态分析文件。
- 算法实现本身不依赖第三方密码库。

## 编译参数

`-std=c99 -Wpedantic -Wall -Wextra -O2`

## 说明

源码目录仅包含本版本 Iphe-512、Iphe-768、Iphe-1024 的算法源文件和最小构建说明。自评估材料位于 `evidence/` 与本版本 `self_eval/` 目录；正式评估结果以评测方复核为准。
