# Chinith Implementations

本目录存放 Chinith 系列签名算法的两套实现，以及用于比较实现输出和提交测试向量的 KAT 一致性检查脚本。

- `Optimized_Implementation/`：优化实现。
- `Reference_Implementation/`：参考实现。
- `check_kat_hash.sh`：统一 KAT 检查入口，比较 Optimized、Reference 和 `../Test_Vectors/` 中的输出。

本 README 只描述当前目录结构。脚本固定假设自己位于 `Chinith/Implementations/check_kat_hash.sh`，测试向量位于 `Chinith/Test_Vectors/`。

## 目录结构

```text
Chinith/
├── Test_Vectors/
│   ├── KAT_SIG_sm4th_d3_128f_loose.txt
│   ├── KAT_SIG_sm4th_d3_128f_tight.txt
│   ├── KAT_SIG_sm4th_d3_128s_loose.txt
│   ├── KAT_SIG_sm4th_d3_128s_tight.txt
│   ├── KAT_SIG_sm4th_em_d2_128f_loose.txt
│   ├── KAT_SIG_sm4th_em_d2_128f_tight.txt
│   ├── KAT_SIG_sm4th_em_d2_128s_loose.txt
│   ├── KAT_SIG_sm4th_em_d2_128s_tight.txt
│   ├── KAT_SIG_ublockith_d3_256f.txt
│   ├── KAT_SIG_ublockith_d3_256s.txt
│   ├── KAT_SIG_ublockith_em_d3_256f.txt
│   ├── KAT_SIG_ublockith_em_d3_256s.txt
│   ├── KAT_SIG_vistrutith_d3_512f.txt
│   └── KAT_SIG_vistrutith_d3_512s.txt
└── Implementations/
    ├── README.md
    ├── check_kat_hash.sh
    ├── Optimized_Implementation/
    │   ├── sm4th_d3_128f_loose/
    │   ├── sm4th_d3_128f_tight/
    │   ├── sm4th_d3_128s_loose/
    │   ├── sm4th_d3_128s_tight/
    │   ├── sm4th_em_d2_128f_loose/
    │   ├── sm4th_em_d2_128f_tight/
    │   ├── sm4th_em_d2_128s_loose/
    │   ├── sm4th_em_d2_128s_tight/
    │   ├── ublockith_d3_256f/
    │   ├── ublockith_d3_256s/
    │   ├── ublockith_em_d3_256f/
    │   ├── ublockith_em_d3_256s/
    │   ├── vistrutith_d3_512f/
    │   └── vistrutith_d3_512s/
    └── Reference_Implementation/
        ├── sm4th_d3_128f_loose/
        ├── sm4th_d3_128f_tight/
        ├── sm4th_d3_128s_loose/
        ├── sm4th_d3_128s_tight/
        ├── sm4th_em_d2_128f_loose/
        ├── sm4th_em_d2_128f_tight/
        ├── sm4th_em_d2_128s_loose/
        ├── sm4th_em_d2_128s_tight/
        ├── ublockith_d3_256f/
        ├── ublockith_d3_256s/
        ├── ublockith_em_d3_256f/
        ├── ublockith_em_d3_256s/
        ├── vistrutith_d3_512f/
        └── vistrutith_d3_512s/
```

## 参数目录命名

- `sm4th_*`：以 SM4 相关 OWF/约束为核心的 128-bit 经典安全签名族。
- `ublockith_*`：以 uBlock 相关 OWF/约束为核心的 256-bit 经典安全签名族。
- `vistrutith_*`：以 Vistrutah 相关 OWF/约束为核心的 512-bit 经典安全签名族。
- `*_em_*`：以 Even-Mansour 构造为 OWF 的变体参数集。
- `*_loose` / `*_tight`：SM4th 的 loose/tight 参数化版本。
- 末尾 `s` / `f`：同一族内的 small/fast 性能取舍。

当前覆盖 14 个实例：

- SM4th loose/tight：`sm4th_d3_128{s,f}_{loose,tight}`、`sm4th_em_d2_128{s,f}_{loose,tight}`。
- uBlockith：`ublockith_d3_256{s,f}`、`ublockith_em_d3_256{s,f}`。
- Vistrutith：`vistrutith_d3_512{s,f}`。

## KAT 测试向量

`../Test_Vectors/` 保存当前提交版本认可的 KAT 基准文件。每个文件对应一个活动实例，文件名格式为：

```text
KAT_SIG_<scheme>.txt
```

其中 `<scheme>` 与以下两个实现目录名保持一致：

```text
Optimized_Implementation/<scheme>/
Reference_Implementation/<scheme>/
```

单个实例的 KAT 输出由该实例目录下的 `run_kat_sig.sh` 生成到本地 `output/` 目录：

```text
<Implementation>/<scheme>/output/KAT_SIG_<scheme>.txt
```

当协议参数、实现逻辑或 KAT 格式发生预期变化时，应重新生成 Optimized 与 Reference 的 KAT 输出，同步更新 `../Test_Vectors/KAT_SIG_<scheme>.txt`，再运行 `check_kat_hash.sh` 确认三者一致。

## KAT 检查脚本

`check_kat_hash.sh` 默认执行以下流程：

1. 对选中的实例分别运行 Optimized 与 Reference 目录中的 `run_kat_sig.sh`。
2. 读取两套实现生成的 `output/KAT_SIG_<scheme>.txt`。
3. 读取 `../Test_Vectors/KAT_SIG_<scheme>.txt`。
4. 输出三者的 SHA256，并检查 Optimized、Reference、`Test_Vectors` 是否完全一致。

从 `Chinith/Implementations/` 目录运行：

```bash
./check_kat_hash.sh
```

或从仓库根目录运行：

```bash
bash Chinith/Implementations/check_kat_hash.sh
```

常用参数：

- `--variant <scheme>` 或直接追加 `<scheme>`：只检查指定实例，可重复传入。
- `--hash-only` / `--no-run-kats`：跳过 KAT 生成，只比较已有 `output/` 与 `../Test_Vectors/` 文件。
- `--run-kats`：显式启用 KAT 生成。
- `CHECK_KAT_HASH_RUN_KATS=0`：通过环境变量默认进入 hash-only 模式。
- `-h` / `--help`：显示脚本帮助。

示例：

```bash
./check_kat_hash.sh --variant sm4th_d3_128s_loose
./check_kat_hash.sh --hash-only ublockith_d3_256f vistrutith_d3_512s
CHECK_KAT_HASH_RUN_KATS=0 ./check_kat_hash.sh
```

全部通过时会输出：

```text
[PASS] All requested KAT hash checks passed.
```

## 单个实例目录

下面的说明适用于任意一个实例目录，例如 `Optimized_Implementation/sm4th_d3_128f_loose/`。

### 构建与入口文件

- `Makefile`：该实例的构建规则。
- `README.md`：该实例的局部说明。
- `run_kat_sig.sh`：KAT 生成脚本。
- `KAT_SIG.c`：KAT 程序入口。
- `<scheme>_bench.c`：固定消息 benchmark 入口。
- `<scheme>_AlgorithmInstance.c/.h`：ICCS API 适配与实例入口。

### 协议核心文件

- `sig_impl.c/.h`：签名与验证主流程。
- `sig_impl_internal.h`：内部上下文、结构和辅助声明。
- `params.c/.h`：实例参数和派生长度。
- `prg.c/.h`：PRG 接口与实现。
- `random_oracle.c/.h`：用于 Random Oracle 的哈希函数。
- `bavc.c/.h`：BAVC commit/open/reconstruct 逻辑。
- `universal_hashing.c/.h`：universal 哈希模块。
- `vole.c/.h`：VOLE 相关逻辑。
- `fields.c/.h`：有限域运算。
- `auxfunc.c/.h`：SM3/hash/XOF 辅助接口，由 ICCS 提供。
- `drng.c/.h`：确定性随机数工具。
- `compat.c/.h`：跨平台/编译器兼容层。
- `utils.c/.h`：通用工具函数。
- `macros.h`：公共宏定义。
- `endian_compat.h`：大小端与字节序辅助。
- `fallbacks.h`：特性缺失时的回退定义。
- `owf.c/.h` 或 `owf.h`：OWF 封装。

其中，`random_oracle`、`bavc`、`universal_hashing`、`vole`、`fields`、`compat`、`utils`、`macros`、`endian_compat` 等文件中的部分函数和逻辑参考了签名 FAEST 的开源代码：

```text
https://github.com/faest-sign/faest-ref
```

该开源代码的版权说明如下。

Copyright (c) 2023 Sebastian Ramacher, AIT Austrian Institute of Technology

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

## 优化实现

`Optimized_Implementation/` 中的常见文件包括：

- `x86_caps.h`：x86 CPU 特性探测。
- `utils_sm4/sm4_asm.S`：SM4 汇编实现。
- `utils_sm4/sm4ni/*`：SM4NI 参考/适配代码。
- `utils_sm4/hygon_cis_sm4.*`：Hygon CIS SM4 用户态封装，仅在支持该路径的 SM4th loose 目录中使用。
- `utils_ballet/*`：Ballet PRG 相关实现。
- `utils_ublock/*`：uBlock OWF/约束相关实现。
- `utils_vistrutah/*`：Vistrutah OWF/约束相关实现。

常用构建开关：

- `NDEBUG=1`：release 构建，默认启用。
- `PRG_ACCE=1`：启用对应实例已有的 PRG/块密码优化路径。
- `FIELD_PCLMUL=1`：在支持的平台上启用有限域乘法辅助。
- `SM4_OWF_ACCE=1`：在 SM4th tight 目录中启用 SM4 OWF 加速。
- `HYGON_SM4_ACCE=1`：在支持该路径的 SM4th loose 目录中启用 Hygon CIS SM4 backend。
- `USE_SBOX_TABLE=1`：启用便携的 SM4 S-box 查表。

在 Hygon 平台上测试 SM4-only 加速时，需要显式关闭旧 SM4NI 路径：

```bash
make PRG_ACCE=0 HYGON_SM4_ACCE=1 KAT_SIG <scheme>_bench
```

## 单实例 KAT

在单个实例目录中生成 KAT：

```bash
bash run_kat_sig.sh
```

脚本会生成：

```text
output/KAT_SIG_<scheme>.txt
```

生成后可回到 `Chinith/Implementations/` 目录，用 `check_kat_hash.sh --hash-only <scheme>` 快速比较已有输出与 `../Test_Vectors/`。

## Benchmark

每个实例目录提供 `<scheme>_bench`：

```bash
make <scheme>_bench
./<scheme>_bench
./<scheme>_bench 100 0
```

benchmark 默认使用固定 56-byte 消息，并输出 keygen/sign/verify 的 wall-clock 与 Mcycles 统计。实际 cycle source 会在运行时打印，例如 `perf_event cpu-cycles (user)` 或 `rdtscp elapsed TSC`。

## 构建产物

目录中可能出现以下构建产物：

- `*.o`：目标文件。
- `KAT_SIG`、`*_bench`：可执行文件。
- `output/`：KAT 输出目录。

单个实例目录可执行：

```bash
make clean
```

这会删除该实例目录中的可执行文件、目标文件与 `output/` 等构建产物。
