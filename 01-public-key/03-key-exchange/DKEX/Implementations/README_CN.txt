DKEX — 认证密钥交换 (KEX + SIG，双向认证)
================================================================
以 DKE KEM 作密钥交换、以 ML-DSA（Dilithium）数字签名作双向身份认证的 AKE。
算法实例 DKEX-128 / DKEX-256 / DKEX-512，签名分别采用 ML-DSA 级别 2 / 5 / 5。

API_PKC 合规性
----------------------------------------------------------------
drng.c/.h、auxfunc.c/.h 取自官方 API_PKC 模板，逐字节未作改动。
KAT_KEX.c 基于官方接口、依 Note 6 为多趟握手作了适配（模板允许修改）。
依 req 3.4(5)，DKE 核心与 KEX 层的全部杂凑/XOF 经 auxfunc：KEX 的 KDF 经
sm3hash/pseudoXOF，DKE 核心矩阵生成/噪声采样经 pseudoXOF。原代码中基于
手写/向量化 SM3 的并行噪声采样（sm3x8/sm3x4）已从源文件物理删除。
算法经 KEX_AlgorithmInstance.h 接口实现；构建脚本使用 -fcommon。
ML-DSA 部件（dilithium/）为 NIST 官方参考实现，未作任何修改；其内部 SHAKE
为 ML-DSA 标准原语固有。

ML-DSA（Dilithium）签名构件 —— 角色与知识产权范围
----------------------------------------------------------------
DKEX 是通用的认证密钥交换构造：它需要一个后量子数字签名方案作为可插拔构件，且仅通过
adkex_sig.h 抽象签名接口调用。可替换为任意符合要求的后量子签名——DKEX 构造本身不依赖
具体选择。本包中该接口以 ML-DSA（FIPS 204）经 adkex_sig_mldsa.c 实例化，作为一个具体
样例；dilithium/ 目录是未经修改的上游 ML-DSA（Dilithium）参考实现。收录它仅为使实现
自包含、使 KAT 可由提交源码复现（req 3.4(2)）；依 req 3.4(6) 故在上面文件清单中一并列出。
dilithium/ 属标准化第三方代码，非本提案的原创贡献，亦不作此主张：其著作权归上游作者，
按其自身宽松许可分发。因此它不在本提案知识产权声明的范围内，包括 B.3 参考/优化实现
所有者声明——后者仅覆盖 DKEX 自有源码（DKE KEM 核、KEX/握手层、adkex_sig* 胶水）。
将 dilithium/ 替换为其它符合要求的 PQ 签名不影响 DKEX。

目录结构
----------------------------------------------------------------
Implementations/{Reference,Optimized}_Implementation/DKEX-{128,256,512}/
Implementations/Additional_Implementation/AArch64_NEON/DKEX-{128,256,512}/  （ARM64；详见其 README）
Implementations/Additional_Implementation/Cortex-M4/DKEX-{128,256,512}/     （Cortex-M4；详见其 README）
Implementations/README
Test_Vectors/KAT_KEX_DKEX-{128,256,512}.txt   （参考与优化实现一致）

每个实例文件夹
----------------------------------------------------------------
build.sh                    构建脚本。DKE 核（平铺在实例根目录）与 dilithium/ 头文件同名，按组
                            分别编译（各自 -I）后链接，在 output/ 写出 KAT。
KEX_AlgorithmInstance.c/.h  API_PKC 的 KEX 编程接口（多趟握手 + 签名认证）。
adkex_derand.c/.h           去随机化协议状态机；其 KDF 经 auxfunc。
adkex_sig_mldsa.c adkex_sig.h   签名后端抽象 + ML-DSA 绑定。
ADKEX_parameters.h          协议参数。
KAT_KEX.c                   KAT 生成器（含 main；依 Note 6 适配多趟）。
ntt/poly/polyvec/dkecpa/dkecca/...  DKE KEM 密码学核心（IND-CPA 部分；平铺在根目录；同 DKE 实现）。
drng.* auxfunc.*  ★官方原文件（未作修改）。
avx2*/ avx2-dkek/   （仅优化实现）DKE 核心 AVX2 NTT 内核。
dilithium/                  ML-DSA（Dilithium）NIST 官方参考实现，未作修改
                            （sign、poly、ntt、reduce、rounding、packing、
                            fips202、symmetric-shake）。

构建：进入实例执行 `bash build.sh`。参考实现 -DDKE_FORCE_SCALAR；优化实现
DKE 核心 -DDKE_AVX2_NTT256_ASM -DDKE_NTT512_PACKED，ML-DSA 为参考实现。
编译宏 DKE_MODE/ADKEX_MODE=128/256/512，DILITHIUM_MODE=2/5/5，DKE_HASH=0，
带 -fcommon。参考与优化实现 KAT 逐字节一致。

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
