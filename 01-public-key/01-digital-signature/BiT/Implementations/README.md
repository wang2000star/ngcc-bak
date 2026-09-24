# BiT 签名算法 — 实现

BiT 是一种基于格的数字签名算法，提交至新一代商用密码算法征集（NGCC）。本目录包含
三个安全等级、各两套实现。

```
Implementations/
├── Reference_Implementation/      C99 参考实现
│   ├── BiT-128/
│   ├── BiT-256/
│   └── BiT-512/
└── Optimized_Implementation/      x86-64 AVX2 优化实现，输出与参考实现一致
    ├── BiT-128-avx2/
    ├── BiT-256-avx2/
    └── BiT-512-avx2/
```

各目录内有独立的 README.md，给出该等级的参数与编译方法。

## 参数与尺寸

| 等级 | N | Q | (K,L) | τ/β | 公钥 | 私钥 | 签名 |
|------|------|--------|-------|---------|------|------|------|
| BiT-128 | 256 | 26881 | (3,3) | 30/30 | 1048 | 1864 | 1504 |
| BiT-256 | 512 | 119297 | (3,3) | 58/58 | 2144 | 4160 | 3456 |
| BiT-512 | 1024 | 520193 | (3,3) | 115/115 | 5056 | 9024 | 6695 |

尺寸单位为字节。

## 文件说明

每个实现目录的文件作用一致，区别在于优化实现额外含 AVX2 汇编。

### 核心实现

| 文件 | 说明 |
|------|------|
| `params.h` | 参数：模数、维度、各编码位宽、密钥与签名长度 |
| `sign.c` / `sign.h` | 密钥生成、签名、验签 |
| `poly.c` / `poly.h` | 多项式：加减、高低位分解、挑战扩展、稀疏乘法 |
| `polyvec.c` / `polyvec.h` | 多项式向量：矩阵展开、NTT、w 计算、hint 生成 |
| `ntt.c` / `ntt.h` | NTT 正逆变换、逐点乘加（仅参考实现） |
| `sample.c` / `sample.h` | 三角分布采样、拒绝采样判定 |
| `packing.c` / `packing.h` | 密钥与签名的序列化、反序列化 |
| `symmetric.c` / `symmetric.h` | 哈希与 XOF 封装，SM3 / SHAKE 双后端 |
| `reduce.h` | 模约简、有符号与无符号转换 |
| `endian.h` | 端序无关的字节读写 |
| `align.h` | 内存对齐宏 |

### AVX2 汇编（仅优化实现）

| 文件 | 说明 |
|------|------|
| `ntt.S` / `intt.S` | NTT 正逆变换 |
| `pointwise.S` | NTT 域逐点乘法与乘加 |
| `shuffle.S` / `shuffle.inc` | 系数重排（部分等级） |
| `ntt_avx.h` | 汇编例程的 C 声明 |
| `consts.c` / `consts.h` | 旋转因子与常量表 |
| `f1600x4.S` | Keccak-f[1600] 四路并行置换 |
| `fips202x4.c` / `fips202x4.h` | 四路并行 SHAKE |
| `rej_table.h` | 拒绝采样查表（部分等级） |
| `shim_asm.c` | 汇编符号别名（部分等级） |

### 提交框架与外部依赖（未做修改）

| 文件 | 说明 |
|------|------|
| `SIG_AlgorithmInstance.c` / `.h` | NGCC 标准 API：`sig_keygen` / `sig_sign` / `sig_verify` |
| `KAT_SIG.c` | KAT 向量生成程序，含 `main()` |
| `drng.c` / `drng.h` | 确定性随机数生成器，ICCS/NGCC 提供 |
| `auxfunc.c` / `auxfunc.h` | SM3，ICCS/NGCC 提供 |
| `fips202.c` / `fips202.h` | SHAKE / SHA-3，源自 PQClean |

### test/

| 文件 | 说明 |
|------|------|
| `test_correctness.c` | 签名、验签、篡改拒绝 |
| `test_speed.c` | 各模块与整体的性能基准 |
| `cpucycles.{c,h}` | 时钟周期计数 |
| `speed_print.{c,h}` | 性能统计输出 |
| `test_common.h` | 测试公共定义 |

## 编译

进入任一实现目录：

```sh
make             # 生成 KAT_SIG
make correctness # 正确性测试
make speed       # 性能测试
make clean
```

优化实现需支持 AVX2 的 x86-64。运行 `./KAT_SIG` 在 `output/` 下生成对应等级的
KAT 向量文件。哈希后端由 `symmetric.h` 的 `BIT_USE_SHAKE` 选择：0 为 SM3（默认），
1 为 SHAKE。
