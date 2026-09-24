CTL-257-512 KEM 优化实现
================================================================================

概述
--------------------------------------------------------------------------------
CTL-257-512 是基于格密码学的密钥封装机制（KEM）算法优化实现，遵循商用密码标准研究院的编程接口规范。本实现采用 AVX2 指令集优化，显著提升了性能�?
目录结构
--------------------------------------------------------------------------------
CTL-257-512/
  +-- api.c              # 核心API实现
  +-- api_257_512.c      # CTL-257-512特有的API实现
  +-- auxfunc.c/.h       # 辅助函数
  +-- benchmark.c        # 性能基准测试程序（时钟周期）
  +-- codec.c            # 编解码实�?  +-- ctl.h              # CTL库主头文�?  +-- ctl_avx2_modq.h    # AVX2模运算优化头文件
  +-- ctl_opt_x86.h      # x86优化头文�?  +-- drng.c/.h          # 确定性随机数生成�?  +-- fft.c              # FFT实现（AVX2优化�?  +-- fnr.c              # FNR实现（AVX2优化�?  +-- inner.h            # 内部头文�?  +-- KAT_KEM.c          # KAT测试向量生成
  +-- kem257.c           # CTL-257-512 KEM核心实现
  +-- kem769.c           # CTL-769-1024 KEM核心实现
  +-- kem3329.c          # CTL-3329-2048 KEM核心实现
  +-- KEM_AlgorithmInstance.c/.h  # KEM接口封装
  +-- keygen.c           # 密钥生成
  +-- keygen_primes_4096.h  # 密钥生成素数�?  +-- Makefile           # 编译脚本
  +-- modgen.c           # 模数生成
  +-- modqp.c            # 模运算（AVX2优化�?  +-- modq_asm.S/.h      # x86汇编模运算实�?  +-- ng_config.h        # NTRU生成器配�?  +-- ng_fxp.c           # NTRU生成器固定点运算
  +-- ng_inner.h         # NTRU生成器内部头文件
  +-- ng_mp31.c          # NTRU生成器MP31运算
  +-- ng_ntru.c          # NTRU生成器核�?  +-- ng_poly.c          # NTRU生成器多项式运算
  +-- ng_zint31.c        # NTRU生成器整数运�?  +-- ntru_solver.c/.h   # NTRU求解�?  +-- ntru_utils.c/.h    # NTRU工具函数
  +-- perf.h             # 性能相关宏定�?  +-- prng.c             # 伪随机数生成�?  +-- readme.txt         # 本文�?  +-- sha3.c             # SHA3哈希函数
  +-- test_kem.c         # 正确性测试程�?
编译说明
--------------------------------------------------------------------------------

依赖环境:
  - GCC 编译器（支持 C11 标准�?AVX2 指令集）
  - GMP 库（GNU Multiple Precision Arithmetic Library�?  - Quadmath 库（四精度浮点运算库�?  - CPU 支持 AVX2 指令集（Intel Haswell 及以上，AMD Excavator 及以上）

编译命令:
  # 编译所有目标（自动启用AVX2优化�?  make all

  # 清理编译产物
  make clean

编译选项:
  本实现默认使用以下编译标志：
  - -mavx2: 启用 AVX2 指令�?  - -DCTL_AVX2=1: 启用 AVX2 优化代码路径
  - -DCTL_X86_ASM=1: 启用 x86 汇编优化
  - -O3: 最高级别优�?
使用方法
--------------------------------------------------------------------------------

密钥封装机制 API:

1. 获取密钥长度
   #include "KEM_AlgorithmInstance.h"

   // 获取公钥长度（字节）
   unsigned long long pk_len = kem_get_pk_len_bytes();

   // 获取私钥长度（字节）
   unsigned long long sk_len = kem_get_sk_len_bytes();

   // 获取密文长度（字节）
   unsigned long long ct_len = kem_get_ct_len_bytes();

   // 获取共享密钥长度（字节）
   unsigned long long ss_len = kem_get_ss_len_bytes();

2. 密钥生成
   unsigned char pk[521];    // 公钥缓冲�?   unsigned char sk[2953];   // 私钥缓冲�?   unsigned long long pk_len, sk_len;

   int ret = kem_keygen(pk, &pk_len, sk, &sk_len);
   // ret == 0 表示成功

3. 密钥封装（Encapsulation�?   unsigned char ct[473];   // 密文缓冲�?   unsigned char ss[16];    // 共享密钥缓冲�?   unsigned long long ct_len, ss_len;

   int ret = kem_enc(pk, pk_len, ss, &ss_len, ct, &ct_len);
   // ret == 0 表示成功

4. 密钥解封装（Decapsulation�?   unsigned char ss2[16];   // 解密后的共享密钥
   unsigned long long ss2_len;

   int ret = kem_dec(sk, sk_len, ct, ct_len, ss2, &ss2_len);
   // ret == 0 表示成功
   // ss2 应与封装时的 ss 相同

测试
--------------------------------------------------------------------------------

正确性测�?
  # 运行测试程序
  ./test_kem.exe

  测试程序会执行以下步骤：
  1. 初始化随机数生成�?  2. 生成密钥�?  3. 执行密钥封装
  4. 执行密钥解封�?  5. 验证封装和解封装的共享密钥是否一�?
KAT 测试向量生成:
  # 生成KAT测试向量
  ./KAT_KEM.exe

  生成的测试向量将输出�?output/KAT_KEM_CTL-257-512.txt 文件�?
性能基准测试:
  # 运行性能基准测试
  ./benchmark.exe

  性能基准测试使用时钟周期数来衡量运算性能�?  - Keygen: 密钥生成性能
  - Encaps: 密钥封装性能
  - Decaps: 密钥解封装性能
  - Total: 总性能

性能优化
--------------------------------------------------------------------------------
本实现相比参考实现，主要优化包括�?
1. AVX2 向量化：FFT、多项式乘法、模运算等核心操作使�?AVX2 指令向量�?2. 汇编优化：关键循环使�?x86 汇编实现
3. 内存访问优化：优化数据布局，提高缓存命中率

================================================================================