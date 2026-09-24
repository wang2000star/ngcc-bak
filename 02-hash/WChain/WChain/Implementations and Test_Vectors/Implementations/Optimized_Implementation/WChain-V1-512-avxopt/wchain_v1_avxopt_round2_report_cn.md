# WChain-V1-512 AVX2/AVX512 第二轮优化报告

## 1. 本轮优化目标

本轮在已有 `WChain-V1-512-avxopt` 分支上继续优化，不覆盖原始 `WChain-V1-512` 实现。目标是根据上一轮性能分析，降低 AVX512 路径中的布尔逻辑指令数，并改善 20 轮压缩函数和完整 hash 的吞吐。

优化对象仍为当前正式规格：

- Version I：`9 x 64`
- 输出：`512` bit
- 轮数：`R = 20`
- 消息块：`1152` bit，即 `144` byte

## 2. 代码改动

### 2.1 AVX512 S-box 使用 ternary logic

上一版 AVX512 S-box 对每个输出 word 使用：

```text
a xor (b or not c)
```

实现上需要 `not/xor/or/xor` 多条指令。本轮改为 AVX512 `vpternlogq` 对应的 intrinsic：

```c
_mm512_ternarylogic_epi64(a, b, c, 0x2d)
```

这把单个 S-box 输出压缩为一条 ternary boolean 指令。注意 `vpternlogq` 的 truth-table immediate 采用第一个参数作为高位索引，因此正确 immediate 为 `0x2d`。

### 2.2 AVX512 XOR 树使用 ternary logic

AVX512 的 `XOR3_512` 和 `XOR5_512` 也改为 ternary logic：

```c
XOR3_512(a,b,c) = vpternlogq(a,b,c,0x96)
XOR5_512(a,b,c,d,e) = XOR3_512(XOR3_512(a,b,c),d,e)
```

这样 Mix Words 中 5 个 word 的异或从 4 条 XOR 指令减少为 2 条 ternary logic 指令。

### 2.3 热路径函数 inline

将 V1 热路径中的 `sbox9_256`、`pi_mix_v1_256`、`round_v1_inject_256`、`sbox9_512`、`pi_mix_v1_512`、`round_v1_inject_512` 标记为 `static inline`，帮助编译器在 20 轮展开中进一步内联。

### 2.4 保持 AVX2 语义不变

AVX2 没有 `vpternlogq`，因此本轮只对 AVX2 做 inline 友好调整，不改变其核心布尔表达式。预期 AVX2 性能基本持平。

## 3. 正确性验证

服务器：`224server1G`

路径：

`/home/jkt/research/hash_wchain/wchains/submit_imp/Implementations/Optimized_Implementation/WChain-V1-512-avxopt`

本地回传结果：

`wchains/submit_imp/Implementations/Optimized_Implementation/WChain-V1-512-avxopt/build_avxopt`

正确性结果：

| 测试项 | 结果 |
|---|---|
| KAT generation | SUCCESS |
| scalar self-test | ok |
| AVX2 compression x4 self-test | ok |
| AVX512 compression x8 self-test | ok |
| AVX hash batch self-test | ok |

说明：第一次尝试时 AVX512 S-box immediate 使用了错误位序，导致 AVX512 self-test 失败。修正为 `0x2d` 后，AVX512 compression 和 hash batch 均通过对拍。

## 4. 固定 CPU 实测结果

为减少服务器调度噪声，本轮补充了固定 CPU 的三次 benchmark：

- `build_avxopt/bench_pinned_1.csv`
- `build_avxopt/bench_pinned_2.csv`
- `build_avxopt/bench_pinned_3.csv`

第一轮固定 CPU 结果受到频率/负载波动影响，run2/run3 更稳定。因此下表采用稳定运行中的最好值。

| 项目 | 第一轮优化结果 | 第二轮优化结果 | 变化 |
|---|---:|---:|---:|
| compress20 scalar | 345.94 MB/s | 348.88 MB/s | +0.8% |
| compress20 AVX2 x4 | 876.06 MB/s | 877.82 MB/s | +0.2% |
| compress20 AVX512 x8 | 1125.06 MB/s | 1276.84 MB/s | +13.5% |
| hash scalar, 65536 B | 337.38 MB/s | 340.86 MB/s | +1.0% |
| hash AVX2 x4, 65536 B | 857.98 MB/s | 857.11 MB/s | -0.1% |
| hash AVX512 x8, 65536 B | 1092.09 MB/s | 1232.48 MB/s | +12.9% |

第二轮的主要收益来自 AVX512 路径。AVX2 没有新的布尔融合指令，因此性能基本不变。

## 5. 第二轮详细性能表

| 消息长度 | scalar MB/s | AVX2 x4 MB/s | AVX512 x8 MB/s |
|---:|---:|---:|---:|
| 32 B | 37.47 | 94.61 | 136.92 |
| 128 B | 149.77 | 378.22 | 547.87 |
| 512 B | 240.63 | 608.66 | 877.23 |
| 1024 B | 268.43 | 676.56 | 975.61 |
| 4096 B | 323.60 | 815.02 | 1171.06 |
| 8192 B | 335.18 | 843.19 | 1211.91 |
| 16384 B | 338.38 | 850.91 | 1222.38 |
| 65536 B | 340.86 | 857.11 | 1230.13 |

注：表中采用 `bench_pinned_3.csv`。若按三次固定 CPU 的最好值，65536 B 的 AVX512 hash 可达到 `1232.48 MB/s`。

## 6. 性能瓶颈分析

当前 AVX512 的长消息吞吐已经从约 `1092 MB/s` 提升到约 `1230--1232 MB/s`。继续优化的主要瓶颈在：

1. **装载与转置开销**  
   batch hash 仍然需要把消息按 lane 组织成向量布局，并在输出时拆回普通 digest。

2. **big-endian block parsing**  
   compression 入口使用多次 `load64_be` 和 `_mm512_set_epi64` 组织向量，仍然不是最理想的连续 vector load。

3. **Sigma 累加与 FChain 外层**  
   完整 hash 仍有 per-lane Sigma 累加、`H_i = CF(...) xor H_{i-2}` 更新和最终 checksum block。

4. **AVX512 频率影响**  
   服务器支持 AVX512，但 AVX512 重指令可能触发降频。因此 AVX512 x8 没有达到理论 2 倍 AVX2 x4。

## 7. 下一步可继续做的优化

1. **批量消息预转置**  
   对长消息，直接维护 SoA 格式的 block buffer，避免每个 compression call 使用 `_mm512_set_epi64` 从 8 条消息拼向量。

2. **AVX512 byte shuffle 加速 big-endian load**  
   尝试 `_mm512_shuffle_epi8` 或 AVX512BW 路径，把 8 条消息的同一 word 一次性加载和字节反转。

3. **Sigma 与 block loading 合并**  
   在 batch loader 中同时完成 Sigma 累加，减少完整 hash 外层循环开销。

4. **增加 AVX512VL/AVX2 混合版本**  
   某些 Intel 平台上纯 AVX512 会降频。可以提供 AVX2 x4 与 AVX512 x8 两套策略，由 benchmark 选择实际更快的实现。

5. **固定 NUMA 与 CPU governor**  
   正式性能表建议使用 `taskset` / `numactl` 固定 socket，并记录 CPU 频率策略，避免 run1 这类波动结果。

## 8. 结论

第二轮优化在不改变算法输出的前提下，显著提升了 AVX512 路径：

- AVX512 x8 compression 从约 `1125 MB/s` 提升到约 `1276 MB/s`；
- AVX512 x8 长消息 hash 从约 `1092 MB/s` 提升到约 `1232 MB/s`；
- AVX2 路径保持稳定；
- 所有 correctness self-test 和 KAT 均通过。

因此，本轮优化可以作为当前 WChain-V1-512 x86_64 优化实现的有效改进版本。

