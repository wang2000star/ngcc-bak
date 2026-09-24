# WChain-V1-512 20轮优化实现服务器评测报告

## 1. 测试对象

本报告对应新建优化分支：

`wchains/submit_imp/Implementations/Optimized_Implementation/WChain-V1-512-avxopt`

该分支不覆盖原 `WChain-V1-512` 目录。测试对象为当前规格中的 Version I：

- 状态规模：`9 x 64 = 576` bit
- 输出长度：`512` bit
- 压缩函数消息块：`1152` bit，即 `144` byte
- 轮数：`R = 20`
- 消息扩展：rolling 3-buffer，实现 `19` 次轻量 `MEF`
- SIMD 策略：AVX2 使用 4 路消息并行，AVX512 使用 8 路消息并行

## 2. 测试环境

服务器：`224server1G`

远端路径：

`/home/jkt/research/hash_wchain/wchains/submit_imp/Implementations/Optimized_Implementation/WChain-V1-512-avxopt`

本地回传结果：

`wchains/submit_imp/Implementations/Optimized_Implementation/WChain-V1-512-avxopt/build_avxopt`

硬件与编译器：

- CPU：Intel Xeon Platinum 8358 @ 2.60 GHz
- 核心/线程：双路，每路 32 核，合计 128 线程
- 指令集：AVX2、AVX512F、AVX512BW、AVX512VL、AVX512DQ、AVX512VBMI、VAES 等
- 编译器：GCC 11.4.0
- 系统：Ubuntu 22.04 系列 Linux kernel 5.19

## 3. 正确性结果

服务器上重新编译并运行一键评测脚本，KAT 与自测结果如下。

| 测试项 | 结果 |
|---|---|
| KAT generation | SUCCESS |
| scalar self-test | ok |
| AVX2 compression x4 self-test | ok |
| AVX512 compression x8 self-test | ok |
| AVX hash batch self-test | ok |

说明：AVX2/AVX512 的 compression 与 hash batch 输出均与 20 轮标量实现对拍通过。

## 4. 置换函数与压缩函数性能

| 项目 | 平均时间 | 吞吐或说明 |
|---|---:|---:|
| 20-round permutation, scalar | 303.34 ns/call | 单状态置换 |
| 20-round compression, scalar | 416.26 ns/call | 345.94 MB/s |
| 20-round compression, AVX2 x4 | 657.49 ns/batch | 876.06 MB/s |
| 20-round compression, AVX512 x8 | 1023.94 ns/batch | 1125.06 MB/s |

由此可见，标量压缩函数相比单纯 20 轮置换多出约 `112.92 ns`：

```text
416.26 ns - 303.34 ns = 112.92 ns
```

该额外开销约为置换时间的 `37.2%`，约占压缩函数总时间的 `27.1%`。主要来源包括：

- 20 轮消息注入；
- 19 次轻量 `MEF`；
- rolling message schedule 的寄存器/内存调度；
- 最后的 `X_R xor B_R xor V` feed-forward；
- compression benchmark 的输入/输出装载开销。

与标量压缩相比，AVX2 x4 的批量吞吐提升约 `2.53x`，AVX512 x8 的批量吞吐提升约 `3.25x`。提升没有达到理论 4x/8x，主要受限于：

- 每轮包含 9 个 64-bit word 的跨 word 组合，SIMD 主要适合多消息并行，无法完全横向利用单消息内部并行；
- bit-sliced S-box、Mix Words 和消息扩展均有较多 XOR/rotate 指令，端口压力较高；
- AVX512 可能触发频率下降，且 8 路批处理对寄存器调度和指令缓存更敏感；
- hash benchmark 中 padding、Sigma、FChain 外层控制逻辑仍为批处理外的固定开销。

## 5. 完整 Hash 吞吐

| 消息长度 | Scalar MB/s | AVX2 x4 MB/s | AVX512 x8 MB/s | AVX2/Scalar | AVX512/Scalar |
|---:|---:|---:|---:|---:|---:|
| 32 B | 37.48 | 94.80 | 120.92 | 2.53x | 3.23x |
| 128 B | 149.68 | 379.16 | 484.14 | 2.53x | 3.23x |
| 512 B | 238.99 | 610.01 | 775.62 | 2.55x | 3.25x |
| 1024 B | 266.32 | 677.44 | 864.16 | 2.54x | 3.25x |
| 4096 B | 320.57 | 816.21 | 1038.64 | 2.55x | 3.24x |
| 8192 B | 331.98 | 845.83 | 1075.12 | 2.55x | 3.24x |
| 16384 B | 335.07 | 852.65 | 1084.88 | 2.54x | 3.24x |
| 65536 B | 337.38 | 857.98 | 1092.09 | 2.54x | 3.24x |

长消息下，标量版本稳定在约 `337 MB/s`，AVX2 x4 稳定在约 `858 MB/s`，AVX512 x8 稳定在约 `1092 MB/s`。

## 6. 优化效果判断

本轮优化完成了三个关键目标：

1. 正式轮数从旧 16 轮同步到当前规格的 20 轮；
2. scalar、AVX2 x4、AVX512 x8 三条路径均通过服务器自测；
3. AVX2/AVX512 批量吞吐相对标量有稳定提升。

由于原 `WChain-V1-512` 目录仍是旧 16 轮展开，本报告不将旧 benchmark 作为正式同口径性能对比。若需要和旧实现对比，应先把旧实现改为 20 轮，或者明确标注旧结果只反映 16 轮历史版本。

## 7. 后续优化建议

短消息性能主要受 padding、Sigma、FChain 外层和 batch 组织开销影响；长消息性能主要受 compression throughput 限制。下一步可以继续优化：

- 将 Sigma 累加、block parsing 和 compression 输入装载进一步合并；
- 对 AVX512 版本尝试减少寄存器压力，观察是否能降低频率下降影响；
- 增加固定 CPU core / NUMA 绑定的 benchmark，减少服务器调度噪声；
- 追加 OpenSSL SHA3-512 与 portable Keccak 同机对照，形成论文可引用的最终性能表。

