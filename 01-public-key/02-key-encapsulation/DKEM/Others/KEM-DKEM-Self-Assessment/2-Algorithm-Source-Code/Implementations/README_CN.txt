DKEM — Ding 密钥封装机制 (Ding Key Encapsulation, KEM)
================================================================
基于格上困难问题的后量子密钥封装机制。算法实例 DKEM-128 / DKEM-256 / DKEM-512，
对应 128 / 256 / 512 比特经典安全强度。
（注：源码内部的编译宏与参数集沿用历史前缀 DKE_*/“DKE-512”，指同一算法族；
提交算法实例名为 DKEM-128/256/512。）

API_PKC 合规性
----------------------------------------------------------------
下列“不可修改”文件取自官方 API_PKC 模板，逐字节未作改动：
    drng.c / drng.h        确定性随机数发生器
    auxfunc.c / auxfunc.h  辅助函数（SM3 杂凑 / pseudoXOF / pseudohash）
    KAT_KEM.c              已知答案测试向量生成器
依 req 3.4(5)，参考与优化实现的全部杂凑/XOF 均经 auxfunc 调用——矩阵生成、
KDF、H(pk) 及噪声采样都走 auxfunc 的 pseudoXOF/sm3hash/pseudohash。原代码中
基于手写/向量化 SM3 的并行噪声采样（sm3x8/sm3x4）已从源文件中物理删除，
源码不含任何替代杂凑实现；AVX2 仅用于 NTT/多项式运算。算法经
KEM_AlgorithmInstance.h 接口实现；构建脚本使用 -fcommon（容许模板的
drng_algorithm 暂定定义与算法侧共存，仅编译开关）。

目录结构
----------------------------------------------------------------
Implementations/
  Reference_Implementation/   参考实现（可移植 ISO C，不依赖指令集）
    DKEM-128/  DKEM-256/  DKEM-512/
  Optimized_Implementation/   优化实现（x86-64 AVX2 NTT；杂凑经 auxfunc）
    DKEM-128/  DKEM-256/  DKEM-512/
  Additional_Implementation/  其它平台的附加实现（§3.4 鼓励）；详见其自带 README。
    AArch64_NEON/   ARM64（ARMv8.2-A：NTT 汇编改编自 mlkem-native + NEON）DKEM-128/256/512
    Cortex-M4/      STM32 Cortex-M4（Plantard 算术 + matacc）DKEM-128/256/512
  README
Test_Vectors/
  KAT_KEM_DKEM-128.txt  -256  -512   （参考与优化实现逐字节一致）

每个实例文件夹
----------------------------------------------------------------
build.sh                    自动化构建脚本，在 output/ 写出该实例 KAT。
KEM_AlgorithmInstance.c/.h  API_PKC 编程接口：kem_keygen/enc/dec 及长度查询。
KAT_KEM.c   ★官方原文件     KAT 生成器（含 main），未作修改。
auxfunc.c/.h ★官方原文件    SM3 杂凑 / pseudoXOF / pseudohash，未作修改。
drng.c/.h   ★官方原文件     确定性随机数发生器，未作修改。
randombytes*.c/.h         随机源接口（DKE_RANDOM=0 时取自 drng_algorithm）。
dkecpa.c/.h dkecca.c/.h    IND-CPA 加密 / IND-CCA KEM（FO 变换，隐式拒绝）。
poly/polyvec/ntt/reduce/packing/random_sampling/verify/dke_utils  密码学核心。
sm3.c/.h dke_sm3.c/.h dke_hash.c/.h   SM3 与杂凑抽象层（经 dke_hash 调 auxfunc）。
parameters.h              按 DKE_MODE 派生的全部参数（含 ALGORITHM_INSTANCE）。
— 优化实现额外 —  avx2/ avx2-dkek/ avx2-512p/ avx2-512/ avx2-linux/
                  AVX2 NTT 内核（N=256 标准格 NTT 汇编、N=512 packed-domain 汇编）。

构建与编译选项
----------------------------------------------------------------
进入任一实例执行 `bash build.sh`，在 output/ 写出 KAT_KEM_DKEM-*.txt。
DKE_MODE=128/256/512   安全强度（已固定；为代码内部宏名）。
DKE_FORCE_SCALAR       参考实现：纯标量 ISO C。
DKE_AVX2_NTT256_ASM / DKE_NTT512_PACKED   优化实现：N=256 / N=512 的汇编 NTT。
DKE_HASH=0             SM3（KAT 参考值；参考与优化实现相同，故 KAT 一致）。
-fcommon               容许官方模板的 drng_algorithm 暂定定义与算法侧共存。

注：辅助函数仅用于正确性验证与初步性能评估，不考虑安全性，后续轮次将替换。

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
