CTL-257-512 KEM 参考实现
================================================================================

本目录是 CTL-257-512 参数集的密钥封装机制（KEM）参考实现。

主要文件
--------------------------------------------------------------------------------
  - KEM_AlgorithmInstance.c/.h  : KEM 对外接口封装
  - KAT_KEM.c                   : KAT 测试向量生成程序
  - test_kem.c                  : 基本正确性测试
  - test_kem_correctness_ctl.c  : 自检与 KAT 辅助测试
  - benchmark.c                 : 性能基准测试
  - benchmark_selfeval_ctl.c    : 自评估测试
  - api.c, api_257_512.c        : CTL API 实现
  - drng.c/.h                   : 确定性随机数生成器
  - prng.c                      : CTL 内部随机接口
  - Makefile                    : 编译脚本

接口头文件
--------------------------------------------------------------------------------
    #include "KEM_AlgorithmInstance.h"

主要 API
--------------------------------------------------------------------------------
    kem_get_pk_len_bytes()
    kem_get_sk_len_bytes()
    kem_get_ct_len_bytes()
    kem_get_ss_len_bytes()
    kem_keygen(pk, &pk_len, sk, &sk_len)
    kem_enc(pk, pk_len, ss, &ss_len, ct, &ct_len)
    kem_dec(sk, sk_len, ct, ct_len, ss2, &ss2_len)

长度参数
--------------------------------------------------------------------------------
  - public key  : 521 bytes
  - private key : 2953 bytes
  - ciphertext  : 473 bytes
  - shared key  : 16 bytes

编译与测试
--------------------------------------------------------------------------------
    make
    ./test_kem_correctness_ctl
    ./KAT_KEM

KAT 输出位于 output/ 目录。