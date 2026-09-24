# WChain-V1-512 18轮优化实现本地复测报告

## 1. 测试对象

本报告对应当前 Version I 规格：

- 状态规模：`9 x 64 = 576` bit
- 输出长度：`512` bit
- 压缩函数消息块：`1152` bit，即 `144` byte
- 轮数：`R = 18`
- 消息扩展：rolling 3-buffer，实现 `17` 次轻量 `MEF`
- Padding：`10*`

测试目录：

`wchains/submit_imp/Implementations/Optimized_Implementation/WChain-V1-512-avxopt`

## 2. 正确性结果

本地已重新编译 Reference 与 Optimized scalar 路径，并重新生成 Version I KAT。

| 测试项 | 结果 |
|---|---|
| Reference KAT generation | SUCCESS |
| Optimized scalar KAT generation | SUCCESS |
| Reference vs optimized KAT files | identical |
| scalar benchmark self-test | ok |
| SIMD benchmark self-test | disabled on local arm64 |

V1 KAT 文件 SHA-256：

| 文件 | SHA-256 |
|---|---|
| `KAT_2_12_WChain-V1-512.txt` | `1c7456ee5a7782aa1ac9067b7fdb845a2a947feb3145ed789900758c62af3510` |
| `KAT_2_23_WChain-V1-512.txt` | `8476caad48d5876318e263bcac5dbb917b23ba3af0766a2e178a9cb91e85c631` |
| `KAT_2_33_WChain-V1-512.txt` | `2d79ef3a14ddc94a6b09bfc8e24698c657510a49355602c2c1c74ad02322f22c` |
| `KAT_Loop_WChain-V1-512.txt` | `8e293b48cb85c6912136518ed3d7ac4f0f7953d01ea7ddb596698d24633ca539` |

## 3. 本地标量性能

本地测试使用 portable scalar path，编译参数为：

```text
cc -O3 -DWCHAIN_DISABLE_SIMD -std=c99 -Wall -Wextra -Wpedantic
```

| 项目 | 平均时间 | 吞吐或说明 |
|---|---:|---:|
| 18-round permutation, scalar | 96.87 ns/call | 单状态置换 |
| 18-round compression, scalar | 113.65 ns/call | 1267.01 MB/s |

完整 hash 吞吐：

| 消息长度 | Scalar MB/s |
|---:|---:|
| 32 B | 136.14 |
| 128 B | 543.11 |
| 512 B | 876.95 |
| 1024 B | 978.76 |
| 4096 B | 1177.72 |
| 8192 B | 1218.95 |
| 16384 B | 1229.00 |
| 65536 B | 1235.63 |

## 4. 说明

本报告中的数据是 18 轮当前规格的本地 scalar 复测结果。历史服务器报告中的 20 轮 AVX2/AVX-512 数据不能直接作为当前 18 轮规格的数据引用。AVX2 x4 与 AVX-512 x8 路径已经随 `WCHAIN_V1_ROUNDS=18` 自动同步，但正式 SIMD 吞吐需要在 x86 服务器上重新运行一键评测脚本后更新。
