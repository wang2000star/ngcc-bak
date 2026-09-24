# AFS-KEX

本项目AFS-KEX为pMAKE-BW算法。

## 目录结构

```
AFS-KEX/
├── Implementations/
│   ├── README                          # 实现目录总说明
│   ├── Reference_Implementation/
│   |   ├── AFS_KEX_C128/               # C128 实例参考实现
│   |   ├── AFS_KEX_C256/               # C256 实例参考实现
│   |   └── AFS_KEX_C512/               # C512 实例参考实现
│   └── Optimized_Implementation/
|   |   └── AVX2/                       # AFS-KEX的AVX实现
|   └── Additional_Implementation/
|       └── ARM_Cortex_M4/              # AFS-KEX的ARM Cortex-M4实现
└── Test_Vector/
    ├── KAT_KEX_AFS_KEX_C128.txt        # 各实例的 KAT
    ├── KAT_KEX_AFS_KEX_C256.txt
    └── KAT_KEX_AFS_KEX_C512.txt
```

每个实例目录均为**自包含的 ISO C 参考实现包**,文件构成一致:

### KEX / 测试驱动层(ICCS 接口)

| 文件 | 作用 |
|------|------|
| `KEX_AlgorithmInstance.h/.c` | ICCS KEX 编程接口及实例封装:`kex_init_a/b`、`kex_generate_pass1~4_msg_*`、`kex_derive_ss_a/b` 等 |
| `KAT_KEX.c` | KEX 的 KAT测试驱动,生成测试向量文件 |
| `drng.c/.h` | KAT 与封装层使用的确定性随机数发生器(DRNG) |
| `randombytes_api.c` / `randombytes.h` | `randombytes` 到 DRNG 上下文的桥接 |
| `auxfunc.c/.h` | ICCS 辅助 Hash 与 XOF 函数 |

### KEM 核心层

| 文件 | 作用 |
|------|------|
| `params.h` | 实例参数定义 |
| `kem.c/.h` | KEM 顶层:密钥对生成 / 封装 / 解封装|
| `indcpa.c/.h` | IND-CPA 公钥加密底层 |
| `poly.c/.h`、`polyvec.c/.h` | 多项式与多项式向量运算、序列化 |
| `ntt.c/.h`、`reduce.c/.h` | 数论变换(NTT)与模约减 |
| `cbd.c/.h` | 中心二项分布噪声采样 |
| `BWcoding.c/.h` | Barnes–Wall 编解码模块 |
| `verify.c/.h` | 常量时间比较 / 条件拷贝 |
| `symmetric.h`、`symmetric-iccs.c` | Hash/XOF 调用经 ICCS 辅助函数后端路由 |

## 构建与测试

每个实例目录下提供独立 `Makefile`,生成 `kat_kex` 可执行文件:

```bash
cd Implementations/Reference_Implementation/AFS_KEX_C128   # 或 C256 / C512
make clean && make        # 编译,产物位于 build/
make kat                  # 运行 KAT 并生成测试向量
```

- `make kat` 运行后会将 KAT 文件写入 `../../../Test_Vector/KAT_KEX_<实例名>.txt`。
- `make clean` 清理 `build/` 中间产物。


**密钥 / 状态 / 消息长度(单位:bytes)**

| 项目 | AFS_KEX_C128 | AFS_KEX_C256 | AFS_KEX_C512 |
|------|-------------:|-------------:|-------------:|
| `kex_rounds`(趟数,count) | 4 | 4 | 4 |
| `public_key` | 1568 | 3136 | 6272 |
| `private_key` | 3170 | 6338 | 12674 |
| `party_a_state` | 64 | 128 | 256 |
| `party_b_state` | 64 | 128 | 256 |
| `pass1_message` | 768 | 1440 | 2944 |
| `pass2_message` | 784 | 1472 | 3008 |
| `pass3_message` | 16 | 32 | 64 |
| `pass4_message` | 0 | 0 | 0 |
| `shared_secret` | 16 | 32 | 64 |
| `total_messages` | 1568 | 2944 | 6016 |

## AVX实现与ARM实现

构建与测试方法见对应目录里说明文档