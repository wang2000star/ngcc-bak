# WChain-V1-512 18轮 AVX2/AVX512 服务器评测报告

## 1. 测试对象

测试目录：

`wchains/submit_imp/Implementations/Optimized_Implementation/WChain-V1-512-avxopt`

当前 Version I 参数：

- 状态规模：`9 x 64 = 576` bit
- 输出长度：`512` bit
- 压缩函数消息块：`1152` bit，即 `144` byte
- 轮数：`R = 18`
- 消息扩展：rolling 3-buffer，实现 `17` 次轻量 `MEF`
- Padding：`10*`

## 2. 测试环境

服务器：`224server1G`

远端路径：

`/home/jkt/research/hash_wchain/wchains/submit_imp/Implementations/Optimized_Implementation/WChain-V1-512-avxopt`

结果目录：

`build_avxopt_18round`

硬件与编译器：

- CPU：Intel Xeon Platinum 8358 @ 2.60 GHz
- CPU 数：128 logical CPUs
- 指令集：AVX2、AVX512F、AVX512BW、AVX512VL、AVX512DQ、AVX512VBMI、VAES 等
- 编译器：GCC 11.4.0
- 系统：Ubuntu 22.04 系列 Linux kernel 5.19

## 3. 正确性结果

服务器上重新编译并运行一键评测脚本，结果如下。

| 测试项 | 结果 |
|---|---|
| KAT generation | SUCCESS |
| scalar self-test | ok |
| AVX2 compression x4 self-test | ok |
| AVX512 compression x8 self-test | ok |
| AVX hash batch self-test | ok |

说明：第一次远端测试发现 AVX2/AVX512 路径仍保留 20 轮展开；已修正为最后注入 round 17、feed-forward 使用 `Bhat_18` 后重新测试，全部自测通过。

## 4. 置换函数与压缩函数性能

| 项目 | 平均时间 | 吞吐或说明 |
|---|---:|---:|
| 18-round permutation, scalar | 311.27 ns/call | 单状态置换 |
| 18-round compression, scalar | 366.95 ns/call | 392.42 MB/s |
| 18-round compression, AVX2 x4 | 615.64 ns/batch | 935.62 MB/s |
| 18-round compression, AVX512 x8 | 826.50 ns/batch | 1393.82 MB/s |

标量压缩函数相比单纯 18 轮置换多出约 `55.68 ns`：

```text
366.95 ns - 311.27 ns = 55.68 ns
```

该额外开销约为置换时间的 `17.9%`，约占压缩函数总时间的 `15.2%`。主要来源包括：

- 18 轮消息注入；
- 17 次轻量 `MEF`；
- rolling message schedule 的寄存器/内存调度；
- 最后的 `X_R xor B_R xor V` feed-forward；
- compression benchmark 的输入/输出装载开销。

与标量压缩相比，AVX2 x4 的批量吞吐提升约 `2.38x`，AVX512 x8 的批量吞吐提升约 `3.55x`。

## 5. 完整 Hash 吞吐

| 消息长度 | Scalar MB/s | AVX2 x4 MB/s | AVX512 x8 MB/s | AVX2/Scalar | AVX512/Scalar |
|---:|---:|---:|---:|---:|---:|
| 32 B | 36.14 | 100.61 | 149.03 | 2.78x | 4.12x |
| 128 B | 169.31 | 402.34 | 595.28 | 2.38x | 3.52x |
| 512 B | 237.58 | 648.35 | 955.30 | 2.73x | 4.02x |
| 1024 B | 262.12 | 694.29 | 1014.52 | 2.65x | 3.87x |
| 4096 B | 302.23 | 835.26 | 1124.52 | 2.76x | 3.72x |
| 8192 B | 317.71 | 876.01 | 1297.50 | 2.76x | 4.08x |
| 16384 B | 326.46 | 888.56 | 1227.08 | 2.72x | 3.76x |
| 65536 B | 332.66 | 912.18 | 1339.94 | 2.74x | 4.03x |

长消息下，标量版本稳定在约 `333 MB/s`，AVX2 x4 稳定在约 `912 MB/s`，AVX512 x8 稳定在约 `1340 MB/s`。

## 6. 结论

本次评测确认当前 18 轮 Version I 优化实现已完成以下同步：

1. scalar、AVX2 x4、AVX512 x8 三条路径均使用 `WCHAIN_V1_ROUNDS=18`；
2. AVX2/AVX512 压缩函数输出与 18 轮标量实现对拍通过；
3. AVX hash batch 输出通过自测；
4. 18 轮 AVX2 与 AVX512 批量吞吐相对标量有稳定提升。

历史 20 轮服务器报告仅作为旧版本记录，不再作为当前 Version I 规格的性能数据引用。
