附加实现（Additional Implementations）— ADKEX
================================================================
面向"主流 64 位 PC"以外平台的实现（§3.4 鼓励）。参考实现为可移植 ISO C，
优化实现为 x86-64 AVX2。

AArch64_NEON/  —— ARM 64 位（AArch64），ARMv8.2-A
----------------------------------------------------------------
最快 arm64 路径：ARMv8.2-A 汇编的 NTT / 逆 NTT / basemul / 约简（改编自 mlkem-native 项目，Apache-2.0 OR ISC OR MIT），配合 NEON 多项式代码。杂凑为 SM3 经 auxfunc，故不构建 SHA3 扩展指令。
  ADKEX-128/  ADKEX-256/  ADKEX-512/      各含：DKE 核 + 协议层（全部平铺在实例根目录）+ build.sh
在 arm64 机器上构建：
  bash build.sh                            （AArch64 Linux 原生 gcc / Apple Silicon clang）
从 x86-64 交叉构建：
  CC=aarch64-linux-gnu-gcc bash build.sh   然后用 qemu-aarch64 运行 kat_ADKEX-*
可移植性：原生汇编为双 ABI（AArch64 Linux 裸 ELF 符号，Apple Silicon Mach-O 前导
下划线，由 __APPLE__ 选择），同一份源码在两种平台都能构建。
验证状态：
  * Apple Silicon（macOS, Mach-O）——已在真实 arm64 硬件端到端验证：ADKEX-128/256/512
    `bash build.sh` 生成的 KAT 与 Test_Vectors 逐字节一致（Apple M 系列，macOS 15，
    Apple clang 17）。
  * AArch64 Linux（ELF）——已在真实 arm64 硬件端到端验证：ADKEX-128/256/512 `bash build.sh`
    生成的 KAT 与 Test_Vectors 逐字节一致（Ubuntu 24.04，gcc 13.3）。原生汇编双方言（N=512
    NTT 已从 Apple “dot” 转为 GNU-as 规范语法）+ 双 ABI（按 __APPLE__），同一份源码在 Apple
    clang 与 GNU gcc 下都能构建。
合规：全部杂凑/XOF 经官方 auxfunc（并行 SM3 噪声已删；DKE_HASH=0 / SM3）。

Cortex-M4/     —— ARM 32 位嵌入式（STM32, Cortex-M4）
----------------------------------------------------------------
M4 路径：DKE 临时 KEM 核的 NTT/多项式用 Plantard 算术 + matacc（Cortex-M4 汇编，提案组成员 Junhao Huang（黄俊豪）所作，ePrint 2022/956，Apache-2.0）；
ADKEX 2-pass 认证握手走全去随机化 API（显式 coins，无 RNG）。杂凑/XOF 走官方 auxfunc
（SM3 为 auxfunc 自带 C 版）。
  ADKEX-128/  ADKEX-256/  ADKEX-512/   各含：M4 DKE 核（平铺在根目录）+ adkex_derand.c + qemu/ + build.sh
合规：drng.c/.h、auxfunc.c/.h 与官方 API_PKC 模板**逐字节一致**；因其用 malloc/free/fprintf，
harness 提供极小的静态数组堆（qemu/syscalls.c）使其在 -nostdlib 下原样运行；无任何绕过 auxfunc。
无需硬件即可构建并验证：
  bash build.sh    —— 用 arm-none-eabi-gcc 编 ELF，并在 QEMU(-M netduinoplus2, 半主机)上
                     跑 2-pass 握手往返自测，校验发起方/响应方共享密钥一致。
需 PATH 上有 arm-none-eabi-gcc 与 qemu-system-arm。真实硬件（STM32H750/F429）用 ELF 烧录运行。
已在 QEMU Cortex-M4 上验证 PASS：ADKEX-128/256/512 的 2-pass 握手自测通过（双方共享密钥一致，
官方 auxfunc SM3）。实测性能在算法规范（§3.3.4 性能评估）中给出，本 README 不列。
