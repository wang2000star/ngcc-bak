# BiT-256（AVX2 优化实现）

算法与参数同 `Reference_Implementation/BiT-256`，相同输入产生相同输出。NTT、Keccak、
逐点乘法等热点用 AVX2 汇编加速。

## 参数

| N | Q | (K,L) | τ/β | γ1/γ2/γ_B | ‖h‖∞ |
|------|--------|-------|-------|-------------|------|
| 512 | 119297 | (3,3) | 58/58 | 4096/5517/64 | 3 |

公钥 2144，私钥 4160，签名 3456（字节）。

## 编译

需支持 AVX2 的 x86-64（Makefile 默认 `-mavx2`）。

```sh
make             # 生成 KAT_SIG
make correctness # 正确性测试
make speed       # 性能测试
make clean
```

`./KAT_SIG` 在 `output/` 下生成 `KAT_SIG_BiT-256.txt`，含 10 组向量。

文件说明见上级目录的 `README.md`。

## 说明

- 哈希后端由 `symmetric.h` 的 `BIT_USE_SHAKE` 选择：0 为 SM3（默认），1 为 SHAKE。
- hint 的 ‖h‖∞ = 3，按 3 比特/系数编码（`pack_polyveck_h_bits`，存 h+3）。
- b1、z0、z1、b0 用通用比特打包器 `pack_bits` / `unpack_bits`。
