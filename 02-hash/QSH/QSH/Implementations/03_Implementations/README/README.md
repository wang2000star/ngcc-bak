# QuantaSylva Hash (QSH) —— 算法实现代码说明（README）

本目录为 QuantaSylva Hash（QSH）杂凑算法的全部实现代码，按《密码杂凑算法提交要求》第 3.4 节组织。
本文件给出 `03_Implementations` 目录下的文件结构及各文件的简要描述。

---

## 1. 算法实例

本算法共提交 3 个算法实例，全部实现均覆盖这 3 个实例：

| 算法实例 | 字宽 w | 杂凑值输出长度 | 说明 |
|----------|--------|----------------|------|
| QSH-512  | 32 比特 | 512 比特  | 默认强制实例 |
| QSH-768  | 64 比特 | 768 比特  | 可选实例 |
| QSH-1024 | 64 比特 | 1024 比特 | 默认强制实例 |

底层置换为 ChaCha-Bahru（9 个完整 R 轮 + 1 个仅列变换的收尾层），采用二叉树（tree）模式：
内部状态 h = 2048、消息块 m = h/2、每 chunk 含 16 个消息块。

约定：消息比特在字节内按 MSB-first 排列；字与 128 比特长度均为小端序；杂凑值按小端序序列化输出。

---

## 2. 目录结构

```
03_Implementations/
├── README/
│   ├── README.md                          ← 本文件
│   └── README_EN.md                       ← 英文版│
├── 1_Reference_Implementation/            参考实现（纯 ISO C99，不依赖特定平台指令集）
│   ├── README.txt
│   ├── QSH-512/
│   ├── QSH-768/
│   └── QSH-1024/
│
├── 2_Optimized_Implementation/            优化实现（适用于主流 64 位 PC，x86-64 AVX2）
│   ├── QSH-512/
│   ├── QSH-768/
│   ├── QSH-1024/
│  
│
└── 3_Additional_Implementation/           附加实现（ARM AArch64 / ARMv8-A，NEON）
    ├── QSH-512/
    ├── QSH-768/
    └── QSH-1024/
```

每个 `QSH-512/` `QSH-768/` `QSH-1024/` 子目录均为自包含工程，构建后生成可执行程序
`katgen`，运行后在 `./output/` 下生成该实例的已知答案测试（KAT）向量文件
（`KAT_2_12_*`、`KAT_2_23_*`、`KAT_2_33_*`、`KAT_Loop_*`），与本提交包
`04_TestVectors/` 中的测试向量一致。

---

## 3. 各算法实例目录内文件说明

每个算法实例目录包含以下文件：

| 文件 | 说明 |
|------|------|
| `CryptHash_AlgorithmInstance.h` | 编程接口头文件，采用商用密码标准研究院提供的官方 API（`API_CryptHash`）。定义本实例的 `ALGORITHM_INSTANCE` 与 `DIGEST_BIT_LENGTH`，声明 `CryptHash()` 函数。 |
| `CryptHash_AlgorithmInstance.c` | QSH 算法本体，`CryptHash()` 的实现。涵盖填充、chunk 循环与二叉树模式。 |
| `drng.c` / `drng.h` | 官方 ICCS 确定性随机数发生器（DRNG），用于生成测试消息。未作任何修改。 |
| `KAT_CryptHash.c` | 官方 KAT 生成器，调用 `CryptHash()` 生成 4 类已知答案测试向量。 |
| `build.sh` | 自动化构建脚本，编译生成可执行程序 `katgen`。 |
| `CMakeLists.txt` | CMake 构建文件（仅参考实现各实例包含）。 |
| `README.txt` | 该实例的简要说明（仅参考实现包含）。 |

统一的对外接口：

```c
int CryptHash(int digest_len_bits,
              const unsigned char *msg,
              unsigned long long   msg_len_bits,
              unsigned char       *digest);
```

---

## 4. 三类实现

### 4.1 参考实现 —— `1_Reference_Implementation/`

- 纯 ISO C99 编写，不使用任何平台内建函数（intrinsics），不依赖特定平台指令集，可移植。
- 作为算法语义的权威基准；优化实现与附加实现的输出均与之逐比特一致。
- 构建：`sh build.sh`，或 `cmake -B build && cmake --build build`。
- 构建命令（节选）：`gcc -std=c99 -Wpedantic -Wall -Wextra -O2 drng.c KAT_CryptHash.c CryptHash_AlgorithmInstance.c -o katgen`

### 4.2 优化实现 —— `2_Optimized_Implementation/`

- 面向主流 64 位 PC 处理器，使用 x86-64 AVX2 指令集，需 CPU 支持 AVX2。
- SIMD 策略为 within-permutation：将每层 16 个相互独立的 G 函数置于 16 个 SIMD 通道并行计算，
  单个 ChaCha-Bahru 置换的 64 字状态全程驻留寄存器；模式部分（填充、chunk 循环、二叉树）为标量。
- 与参考实现对所有实例、所有长度逐比特一致。
- 构建：`sh build.sh`。
- 构建命令（节选）：`gcc -O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 ...`
- 子目录 `Optimized_Implementation_WithinPerm/` 为优化实现的 within-permutation SIMD 变体，
  属低时延变体：短消息更快、长消息具竞争力，同样要求 AVX2。

### 4.3 附加实现 —— `3_Additional_Implementation/`

- 面向 ARM AArch64 / ARMv8-A 平台，使用 NEON。
- 策略：w=32 采用 within-permutation；w=64 采用 2-way 批处理。
- 构建：`sh build.sh`。
- 构建命令（节选）：`gcc -O3 -march=armv8-a -flto -fomit-frame-pointer -std=c99 ...`
- 注意：NEON 路径未在编写环境中验证，移植到 ARM 平台后请先用 ARM/qemu 进行 KAT 校验。

---

## 5. 构建与生成测试向量

在任一算法实例目录下执行：

```sh
sh build.sh        # 生成可执行程序 katgen
./katgen           # 在 ./output/ 下生成 KAT_2_12 / KAT_2_23 / KAT_2_33 / KAT_Loop 向量文件
```

KAT 生成器按提交要求第 3.5 节，对以下消息生成对应杂凑值：长度 0 至 2^12 比特的消息、
长度 2^23 比特的消息、长度 2^33 比特的消息，以及长度 2^13 比特消息的循环测试。

> 构建要求：兼容 C99 的编译器（如 GCC）。优化实现需支持 AVX2 的 x86-64；附加实现需 ARM AArch64 工具链。
