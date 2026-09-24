===============================================================================
  UVW-KEM
  （基于广义 (U+V, U+W) 码的密钥封装机制）
===============================================================================

本目录包含 UVW 密钥封装机制的参考与优化 C 语言实现。代码采用 C99 编写，
提供三组安全参数集（128 / 256 / 512 比特经典安全强度）。


目录结构
--------

UVW_KEM/
|
|-- Reference_Implementation/                    参考实现
|   |-- UVW-KEM-128/                             Level 1（128 经典 / 80 量子比特安全）
|   |   |-- include/
|   |   |   |-- KEM_AlgorithmInstance.h          KEM 算法实例接口与密钥/密文结构体定义
|   |   |   |-- auxfunc.h                        辅助函数接口（SM3 哈希、伪哈希、伪 XOF）
|   |   |   |-- drng.h                           确定性随机数生成器（DRNG）接口
|   |   |   |-- gf_math.h                        有限域运算接口（加/减/乘/逆/幂及矩阵向量运算）
|   |   |   |-- params.h                         参数集定义（q=433, n=860, k=430, k1=215, k2=215, w=116, m=256）
|   |   |   |-- uvw_constants.h                  全局预计算常量表声明（逆元表、RS 生成矩阵）
|   |   |
|   |   |-- src/
|   |   |   |-- KEM_AlgorithmInstance.c           KEM 核心算法实现（密钥生成、封装、解封装）
|   |   |   |-- auxfunc.c                         辅助函数实现（SM3、HMAC-SM3、KDF-SM3）
|   |   |   |-- drng.c                            确定性随机数生成器实现（基于 SM3 的 CTR_DRBG）
|   |   |   |-- gf_math.c                         有限域 GF(q) 运算实现
|   |   |   |-- list_decoding.c                   Guruswami-Sudan 列表译码器实现
|   |   |   |-- uvw_constants.c                   预计算常量表数据（逆元表、Vandermonde RS 生成矩阵）
|   |   |   |-- KAT_KEM.c                         KAT（Known Answer Test）向量生成与验证程序
|   |   |
|   |   |-- CMakeLists.txt                        CMake 构建配置
|   |
|   |-- UVW-KEM-256/                             Level 2（256 经典 / 128 量子比特安全）
|   |   |-- include/
|   |   |   |-- KEM_AlgorithmInstance.h           （同 128，ALGORITHM_INSTANCE 为 "UVW_KEM_256"）
|   |   |   |-- auxfunc.h                         （同 128）
|   |   |   |-- drng.h                            （同 128）
|   |   |   |-- gf_math.h                         （同 128）
|   |   |   |-- params.h                          参数集定义（q=857, n=1708, k=854, k1=427, k2=427, w=232, m=256）
|   |   |   |-- uvw_constants.h                   （同 128，常量表尺寸随参数变化）
|   |   |
|   |   |-- src/
|   |   |   |-- KEM_AlgorithmInstance.c           （同 128）
|   |   |   |-- auxfunc.c                         （同 128）
|   |   |   |-- drng.c                            （同 128）
|   |   |   |-- gf_math.c                         （同 128）
|   |   |   |-- list_decoding.c                   （同 128，内部 RS 参数随安全级别调整）
|   |   |   |-- uvw_constants.c                   预计算常量表数据（q=857 对应逆元表与 RS 生成矩阵）
|   |   |   |-- KAT_KEM.c                         （同 128）
|   |   |
|   |   |-- CMakeLists.txt                        CMake 构建配置
|   |
|   |-- UVW-KEM-512/                             Level 3（512 经典 / 256 量子比特安全）
|       |-- include/
|       |   |-- KEM_AlgorithmInstance.h           （同 128，ALGORITHM_INSTANCE 为 "UVW_KEM_512"）
|       |   |-- auxfunc.h                         （同 128）
|       |   |-- drng.h                            （同 128）
|       |   |-- gf_math.h                         （同 128）
|       |   |-- params.h                          参数集定义（q=1709, n=3412, k=1706, k1=853, k2=853, w=463, m=512）
|       |   |-- uvw_constants.h                   （同 128，常量表尺寸随参数变化）
|       |
|       |-- src/
|       |   |-- KEM_AlgorithmInstance.c           （同 128）
|       |   |-- auxfunc.c                         （同 128）
|       |   |-- drng.c                            （同 128）
|       |   |-- gf_math.c                         （同 128）
|       |   |-- list_decoding.c                   （同 128，内部 RS 参数随安全级别调整）
|       |   |-- uvw_constants.c                   预计算常量表数据（q=1709 对应逆元表与 RS 生成矩阵）
|       |   |-- KAT_KEM.c                         （同 128）
|       |
|       |-- CMakeLists.txt                        CMake 构建配置
|
|-- Optimized_Implementation/                    优化实现
|   |-- UVW-KEM-128/                             Level 1 优化版
|   |   |-- (目录结构与参考实现相同，编译选项增加 -march=native 等优化)
|   |-- UVW-KEM-256/                             Level 2 优化版
|   |   |-- (目录结构与参考实现相同)
|   |-- UVW-KEM-512/                             Level 3 优化版
|       |-- (目录结构与参考实现相同)
|
|-- build/                                       CMake 构建输出目录（自动生成）
|
|-- README.txt                                   本文件


各文件简要说明
--------------

include/params.h
    定义 UVW 推荐的三组参数集（128 比特、256 比特和 512 比特经典安全强度），
    以及相应的常数（q, n, k, k1, k2, w, m）与有限域元素类型 gf_elem_t。
    三个安全级别分别对应：
      Level 1: q=433,  n=860,  k=430,  k1=215, k2=215, w=116, m=256
      Level 2: q=857,  n=1708, k=854,  k1=427, k2=427, w=232, m=256
      Level 3: q=1709, n=3412, k=1706, k1=853, k2=853, w=463, m=512

include/gf_math.h
    声明底层有限域运算：加法、减法、乘法、求逆、模幂，以及向量点积和
    向量-矩阵乘法接口。

include/KEM_AlgorithmInstance.h
    KEM 算法实例的主头文件。定义公钥（public_key_t）、私钥（private_key_t）、
    密文（ciphertext_t / kem_ciphertext_t）等核心数据结构，并声明密钥生成
    （kem_keygen）、封装（kem_enc）、解封装（kem_dec）三个 KEM 标准接口函数，
    以及获取各对象字节长度的辅助函数。

include/auxfunc.h
    声明辅助密码学函数：SM3 杂凑函数（sm3hash）、基于 SM3 与 HMAC-SM3 构造的
    伪哈希函数（pseudohash，输出 512/768/1024 比特）、以及基于 KDF-SM3 构造的
    伪扩展输出函数 pseudoXOF。后两者仅用于正确性验证，不保证安全性。

include/drng.h
    声明确定性随机数生成器（DRNG）接口。定义 DRNG_ctx 上下文结构体，提供
    初始化（init_random_number）和生成伪随机数（get_random_number）两个函数。

include/uvw_constants.h
    声明 UVW 方案的全局预计算常量表：GF(q) 乘法逆元表（gf_inv_table）和
    RS 码的 Vandermonde 生成矩阵（FIXED_G_RS）。

src/gf_math.c
    实现有限域 GF(q) 上的基础运算：模加法、模减法（均采用无符号下溢掩码技巧
    避免分支）、模乘法、模逆元、模幂运算，以及向量点积和向量-矩阵乘法。

src/list_decoding.c
    实现 Reed-Solomon 码的 Guruswami-Sudan 列表译码算法。包含插值多项式
    构造、(1, k-1)-加权次数计算、迭代插值、因式分解与候选消息筛选等步骤。

src/KEM_AlgorithmInstance.c
    KEM 核心算法实现。包含：
      - kem_keygen：密钥生成（随机矩阵生成、满秩校验、置换与对角矩阵构造、
        系统形式化简）
      - kem_enc：封装（随机消息编码、纠错码编码、噪声叠加、哈希计算）
      - kem_dec：解封装（列表译码恢复消息、重新编码验证、哈希校验与隐式拒绝）
    内部还包含随机字节获取、随机矩阵/置换生成、矩阵乘法、秩计算等辅助函数。

src/auxfunc.c
    实现辅助密码学函数。包含完整的 SM3 杂凑算法（符合 GB/T 32905-2016）、
    基于 HMAC-SM3 的伪哈希函数、以及基于 KDF-SM3 的伪扩展输出函数。

src/drng.c
    实现确定性随机数生成器。基于 SM3 构造的 CTR_DRBG 方案，支持种子初始化
    和伪随机数生成，内部包含 Reseed 机制。

src/uvw_constants.c
    存放预计算的全局常量数据。包含 GF(q) 乘法逆元查找表和 RS 码的
    Vandermonde 生成矩阵。不同安全级别对应不同的素数 q 和矩阵尺寸。

src/KAT_KEM.c
    KAT（Known Answer Test）向量生成与验证程序。使用固定种子驱动 DRNG，
    执行完整的密钥生成-封装-解封装流程，并将中间结果输出到文件，
    用于跨实现一致性验证。

CMakeLists.txt
    CMake 构建配置文件。设置 C99 标准、编译警告选项（-Wall -Wextra -pedantic）、
    优化选项（-O3 -flto -funroll-all-loops），并将所有源文件编译为 KAT_KEM
    可执行程序。优化实现额外启用 -march=native 选项。


安全参数对照表
--------------

级别     | q     | n    | k    | k1  | k2  | w   | m   | 经典安全 | 量子安全
---------|-------|------|------|-----|-----|-----|-----|----------|----------
Level 1  | 433   | 860  | 430  | 215 | 215 | 116 | 256 | 128 bit  | 80 bit
Level 2  | 857   | 1708 | 854  | 427 | 427 | 232 | 256 | 256 bit  | 128 bit
Level 3  | 1709  | 3412 | 1706 | 853 | 853 | 463 | 512 | 512 bit  | 256 bit


构建说明
--------

以 UVW-KEM-128 参考实现为例：

    cd Reference_Implementation/UVW-KEM-128
    mkdir build && cd build
    cmake ..
    make

编译成功后将在 build 目录下生成 KAT_KEM 可执行文件，运行即可生成 KAT 向量。
