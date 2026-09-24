附加实现（Additional Implementations）— DKEM
================================================================
面向"主流 64 位 PC"以外平台的实现（§3.4 鼓励）。参考实现为可移植 ISO C，
优化实现为 x86-64 AVX2。以下附加实现按平台分子目录。

AArch64_NEON/  —— ARM 64 位（AArch64），ARMv8.2-A
----------------------------------------------------------------
最快 arm64 路径：ARMv8.2-A 汇编的 NTT / 逆 NTT / basemul / 约简（改编自 mlkem-native 项目，Apache-2.0 OR ISC OR MIT），配合 NEON 内联多项式代码。杂凑为 SM3 经 auxfunc，故不构建 Keccak/SHA3 扩展指令。
  DKEM-128/  DKEM-256/  DKEM-512/      各含：源码 + build.sh
在 arm64 机器上构建：
  bash build.sh                            （AArch64 Linux 原生 gcc，或 Apple Silicon clang）
从 x86-64 交叉构建：
  CC=aarch64-linux-gnu-gcc bash build.sh   然后用 qemu-aarch64 运行 kat_DKEM-*
可移植性：原生汇编为双 ABI——AArch64 Linux 用裸 ELF 符号，Apple Silicon 用带前导
下划线的 Mach-O 符号，由 __APPLE__ 选择，因此同一份源码在两种平台都能汇编与链接。
验证状态：
  * Apple Silicon（macOS, Mach-O）——已在真实 arm64 硬件上端到端验证：三个实例
    （DKEM-128/256/512）`bash build.sh` 构建并生成的 KAT 与 Test_Vectors 逐字节一致
    （Apple M 系列，macOS 15，Apple clang 17）。
  * AArch64 Linux（ELF）——已在真实 arm64 硬件端到端验证：DKEM-128/256/512 `bash build.sh`
    构建并生成的 KAT 与 Test_Vectors 逐字节一致（Ubuntu 24.04，gcc 13.3）。原生汇编双方言
    （编译器生成的 N=512 NTT 已从 Apple “dot” 语法转为 GNU-as 规范语法，clang 也接受）+
    双 ABI（符号修饰 / GOT 重定位按 __APPLE__），同一份源码在 Apple clang 与 GNU gcc 下都能构建。
合规：与参考/优化实现一致，全部杂凑/XOF 经官方 auxfunc（并行 SM3 噪声已删；
DKE_HASH=0 / SM3）。

Cortex-M4/     —— ARM 32 位嵌入式（STM32，Cortex-M4）
----------------------------------------------------------------
M4 路径：NTT/多项式核用 Plantard 算术 + matacc（矩阵生成与乘累加融合）Cortex-M4
汇编。其中 Plantard NTT 汇编为提案组成员 Junhao Huang（黄俊豪）所作（ePrint 2022/956，Apache-2.0）。杂凑/XOF 走官方 auxfunc（SM3），所以这里的 SM3 是 auxfunc 自带的可移植 C 实现
（用 SM3 汇编会更快，但为保 auxfunc.c 与模板逐字节一致，保留官方 C 版）。
  DKEM-128/  DKEM-256/  DKEM-512/      各含：DKE 源码（平铺在根目录）+ qemu/ + build.sh
合规：drng.c/.h、auxfunc.c/.h 与官方 API_PKC 模板**逐字节一致**（未改）。因这些模板文件
用 malloc/free/fprintf，裸机 harness 提供一个极小的自带堆（qemu/syscalls.c：静态数组上的
malloc/free），使它们在 -nostdlib 下原样运行；算法无任何绕过 auxfunc 的代码。
无需硬件即可构建并验证：
  bash build.sh    —— 用 arm-none-eabi-gcc 编出 ELF，并在 QEMU(-M netduinoplus2,
                      半主机)上运行 keygen/encaps/decaps 往返自测。
需 PATH 上有 arm-none-eabi-gcc 与 qemu-system-arm。真实硬件（STM32H750/F429）
则按板子的烧录/运行流程使用 ELF。
已在 QEMU Cortex-M4 上验证 PASS：DKEM-128/256/512 的 keygen/encaps/decaps 往返自测
通过（官方 auxfunc SM3）。实测性能在算法规范（§3.3.4 性能评估）中给出，本 README 不列。
