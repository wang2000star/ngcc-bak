ADKEX — 认证密钥交换 (KEX，单向认证 / KEMTLS 型)
================================================================
以 DKE KEM 为底层、KEMTLS 思想构造的单向认证密钥交换协议（握手无签名）。
算法实例 ADKEX-128 / ADKEX-256 / ADKEX-512。

API_PKC 合规性
----------------------------------------------------------------
drng.c/.h、auxfunc.c/.h 取自官方 API_PKC 模板，逐字节未作改动。
KAT_KEX.c 基于官方接口、依 Note 6 为多趟握手作了适配（模板允许修改）。
依 req 3.4(5)，全部杂凑/XOF 经 auxfunc：KEX 的 KDF 经 sm3hash/pseudoXOF，
DKE 核心矩阵生成/噪声采样经 pseudoXOF。原代码中基于手写/向量化 SM3 的
并行噪声采样（sm3x8/sm3x4）已从源文件物理删除；AVX2 仅用于 NTT/多项式运算。
算法经 KEX_AlgorithmInstance.h 接口实现；构建脚本使用 -fcommon。

目录结构
----------------------------------------------------------------
Implementations/{Reference,Optimized}_Implementation/ADKEX-{128,256,512}/
Implementations/Additional_Implementation/AArch64_NEON/ADKEX-{128,256,512}/  （ARM64；详见其 README）
Implementations/Additional_Implementation/Cortex-M4/ADKEX-{128,256,512}/     （Cortex-M4；详见其 README）
Implementations/README
Test_Vectors/KAT_KEX_ADKEX-{128,256,512}.txt   （参考与优化实现一致）

每个实例文件夹
----------------------------------------------------------------
build.sh                    自动化构建脚本，在 output/ 写出该实例 KAT。
KEX_AlgorithmInstance.c/.h  API_PKC 的 KEX 编程接口（多趟握手）。
adkex_derand.c/.h           去随机化协议状态机；其 KDF 经 auxfunc。
ADKEX_parameters.h          协议参数（标签、转录串、状态/密钥长度）。
KAT_KEX.c                   KAT 生成器（含 main；依 Note 6 适配多趟）。
ntt/poly/polyvec/dkecpa/dkecca/...  DKE KEM 密码学核心（平铺在根目录；同 DKE 实现）。
drng.* auxfunc.*  ★官方原文件（未作修改）。
avx2*/ avx2-dkek/ avx2-512p/ avx2-512/ avx2-linux/
                            （仅优化实现）DKE 核心 AVX2 NTT 内核。

构建：进入实例执行 `bash build.sh`。参考实现 -DDKE_FORCE_SCALAR；优化实现
-DDKE_AVX2_NTT256_ASM -DDKE_NTT512_PACKED。编译宏 DKE_MODE/ADKEX_MODE=128/256/512，
DKE_HASH=0，带 -fcommon。参考与优化实现 KAT 逐字节一致。

文件清单 —— 逐文件简述（提交要求 §3.4(6)）
----------------------------------------------------------------
本目录下每个文件的逐一简要说明，见英文 README 的 “File Manifest” 一节（内容一致，为符合“提交要求以英文为准”而置于英文 README）。

第三方代码 —— 出处与知识产权范围（优化 AVX2 / 附加 NEON 与 M4）
----------------------------------------------------------------
在与标准化 ML-KEM（FIPS 203）相同的环上，优化实现与附加实现复用/改编了若干取自公开第三方
代码的底层构件，均已在各文件头部内联标注出处：
  优化实现（x86-64 AVX2）：
    avx2/consts_avx2.c、avx2/ntt_avx2.c、
    avx2/poly_avx2.c、avx2/rejsample_avx2.c   AVX2 常量 / 正向 NTT / 多项式辅助 / 拒绝采样，
                                              取自 pq-crystals/mlkem。
    avx2-512p/consts.c、p512_consts.h、
    avx2-512p/reduce.h                        packed 域常量 + Montgomery 约简，
                                              取自 pq-crystals/mlkem 与 PQClean（mlkem-768）。
    random_sampling.c                         AVX2 中心二项（CBD）采样，取自 ML-KEM AVX2 参考实现。
    avx2-dkek/                                vendored ML-KEM / ntt256 AVX2 NTT 汇编的参数/胶水。
  附加实现（arm64 NEON）：
    Additional_Implementation/.../aarch64-native/   NTT / 逆 NTT / basemul / 约简 汇编，
                                              改编自 mlkem-native 项目（Arm Limited / Hanno
                                              Becker / Amin Abdulrahman / Matthias
                                              Kannwischer 等），Apache-2.0 OR ISC OR MIT。
  附加实现（Cortex-M4）：
    Additional_Implementation/.../cortex-m4/  Plantard NTT 汇编，提案组成员 Junhao Huang
                                              （黄俊豪，ePrint 2022/956）所作，Apache-2.0。
许可证：各构件许可证标识已在上文及各源文件头内联标注；完整文本见各上游项目（自评估包另见 依赖说明 / Dependency Statement）。
知识产权范围 —— B.3 权属声明：
  * 不在 B.3 范围内（外部第三方，上游作者保留著作权）：上述取自 pq-crystals / PQClean 的
    AVX2 构件，、取自 mlkem-native 的 arm64 NEON 汇编，以及 avx2-linux/ 的 *_dkek_*.S 与 ntt_tobytes_avx2.S（pq-crystals ML-KEM 移植）。均为标准化、公开发布的构件，非本
    提案原创，亦不作此主张。
  * 在 B.3 范围内（提案组原创）：DKE 算法设计、可移植参考实现、avx2-linux/ 下的手写 x86-64
    NTT 汇编（DKE 自然序 NTT/invNTT/basemul/poly_ops 为提案组成员 Liu Rui（刘锐）所作；其中 *_dkek_*.S 与 ntt_tobytes_avx2.S 为 pq-crystals ML-KEM 移植、不在 B.3）、Cortex-M4 Plantard NTT 汇编（提案组成员 Junhao
    Huang 所作，ePrint 2022/956）、以及协议 / KEX 胶水代码。
可移植参考实现不含任何外部第三方代码（纯 ISO C99）。将这些内核替换为其它符合要求的实现，
不改变算法。
