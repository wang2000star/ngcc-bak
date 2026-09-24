# Pavelor 实现代码

本目录包含 Pavelor 密码杂凑算法的参考软件实现和优化软件实现。各实现遵循商用密码标准研究院（ICCS）为新一代商用密码算法征集活动提交所提供的 `CryptHash` 编程接口。

## 1. 目录结构

```text
Implementations/
  README
  Reference_Implementation/
    Pavelor-512/
      CryptHash_AlgorithmInstance.c
      CryptHash_AlgorithmInstance.h
      KAT_CryptHash.c
      drng.c
      drng.h
    Pavelor-768/
      CryptHash_AlgorithmInstance.c
      CryptHash_AlgorithmInstance.h
      KAT_CryptHash.c
      drng.c
      drng.h
    Pavelor-1024/
      CryptHash_AlgorithmInstance.c
      CryptHash_AlgorithmInstance.h
      KAT_CryptHash.c
      drng.c
      drng.h
  Optimized_Implementation/
    Pavelor-512/
      CryptHash_AlgorithmInstance.c
      CryptHash_AlgorithmInstance.h
      KAT_CryptHash.c
      drng.c
      drng.h
    Pavelor-768/
      CryptHash_AlgorithmInstance.c
      CryptHash_AlgorithmInstance.h
      KAT_CryptHash.c
      drng.c
      drng.h
    Pavelor-1024/
      CryptHash_AlgorithmInstance.c
      CryptHash_AlgorithmInstance.h
      KAT_CryptHash.c
      drng.c
      drng.h
```

本提交包不包含其他附加实现。

## 2. 算法实例

本提交提供以下算法实例，并将各实例放在独立的实现目录中：

| 实例 | 杂凑值长度 | 速率 | 容量 | 实现目录 |
| --- | ---: | ---: | ---: | --- |
| `Pavelor-512` | 512 比特 | 1536 比特 | 1024 比特 | `Reference_Implementation/Pavelor-512`, `Optimized_Implementation/Pavelor-512` |
| `Pavelor-768` | 768 比特 | 1024 比特 | 1536 比特 | `Reference_Implementation/Pavelor-768`, `Optimized_Implementation/Pavelor-768` |
| `Pavelor-1024` | 1024 比特 | 512 比特 | 2048 比特 | `Reference_Implementation/Pavelor-1024`, `Optimized_Implementation/Pavelor-1024` |

每个实例目录均为自包含目录，可单独编译。

## 3. 文件说明

每个实例目录中的文件用途如下：

| 文件 | 说明 |
| --- | --- |
| `CryptHash_AlgorithmInstance.c` | 所选 Pavelor 实例的实现文件。该文件定义 `CryptHash` 函数，以及内部置换、填充、吸收和挤出过程。 |
| `CryptHash_AlgorithmInstance.h` | ICCS 接口头文件。该文件定义算法实例名称、杂凑值长度、测试向量输出模式以及 `CryptHash` 函数原型。 |
| `KAT_CryptHash.c` | ICCS 为密码杂凑算法提交提供的已知答案测试向量生成程序。该程序生成 `KAT_2_12`、`KAT_2_23`、`KAT_2_33` 和 `KAT_Loop` 文件。 |
| `drng.c` | ICCS KAT 生成程序所使用的确定性随机数生成器实现文件。 |
| `drng.h` | `drng.c` 的头文件。 |

## 4. 编程接口

所有实现均提供以下函数：

```c
int CryptHash(int digest_len_bits,
              const unsigned char *msg,
              unsigned long long msg_len_bits,
              unsigned char *digest);
```

参数含义如下：

| 参数 | 说明 |
| --- | --- |
| `digest_len_bits` | 请求输出的杂凑值长度，单位为比特。该值必须与当前目录中的算法实例匹配。 |
| `msg` | 输入消息指针。对于空消息，仅当 `msg_len_bits` 为零时，该指针可以为 `NULL`。 |
| `msg_len_bits` | 输入消息长度，单位为比特。实现支持按比特计长的消息。 |
| `digest` | 输出缓冲区指针。该缓冲区大小应至少为 `digest_len_bits / 8` 字节。 |

函数执行成功时返回 `0`，发生错误时返回非零值。

拆分后的每个实例仅接受自身对应的杂凑值长度。例如，`Pavelor-512` 实现仅接受 `digest_len_bits = 512`，当输入其他杂凑值长度时返回错误。

## 5. 参考实现

参考实现位于：

```text
Implementations/Reference_Implementation/
```

参考实现使用 ISO C 编写，不依赖特定平台的 AES 指令内在函数。该实现主要用于清晰性、可移植性以及对算法规范进行独立验证。

若要为参考实现编译 KAT 生成程序，请进入对应的算法实例目录并执行：

```sh
gcc -O2 -std=c99 -Wall -Wextra KAT_CryptHash.c drng.c CryptHash_AlgorithmInstance.c -o kat
```

在 Windows/MSYS2 环境下，输出可执行文件可命名为 `kat.exe`：

```sh
gcc -O2 -std=c99 -Wall -Wextra KAT_CryptHash.c drng.c CryptHash_AlgorithmInstance.c -o kat.exe
```

## 6. 优化实现

优化实现位于：

```text
Implementations/Optimized_Implementation/
```

优化实现面向支持 AES-NI 兼容 AES 轮指令的主流 64 位 PC 处理器。该实现使用 128 比特 AES 轮函数内在函数实现内部置换。

若要为优化实现编译 KAT 生成程序，请进入对应的算法实例目录并执行：

```sh
gcc -O3 -std=c99 -Wall -Wextra -maes -msse2 KAT_CryptHash.c drng.c CryptHash_AlgorithmInstance.c -o kat
```

在 Windows/MSYS2 环境下，输出可执行文件可命名为 `kat.exe`：

```sh
gcc -O3 -std=c99 -Wall -Wextra -maes -msse2 KAT_CryptHash.c drng.c CryptHash_AlgorithmInstance.c -o kat.exe
```

如果目标编译器不支持 AES 内在函数，或者目标处理器不支持相应指令集，应改用参考实现。

## 7. KAT 生成

KAT 生成程序使用 `CryptHash_AlgorithmInstance.h` 中定义的以下宏：

```c
#define OUTPUT_BLANK_TEST_VECTORS 0
#define ALGORITHM_INSTANCE "Pavelor-512"   /* 或 "Pavelor-768", "Pavelor-1024" */
#define DIGEST_BIT_LENGTH 512              /* 或 768, 1024 */
```

正式生成 KAT 文件时，`OUTPUT_BLANK_TEST_VECTORS` 必须设置为 `0`。如果该宏设置为 `1`，生成程序将输出空白测试向量模板，而不会输出真实杂凑值。

编译得到 KAT 可执行文件后，运行：

```sh
./kat
```

或在 Windows/MSYS2 环境下运行：

```sh
./kat.exe
```

生成的文件将写入当前实例目录下的 `output/` 目录：

```text
output/KAT_2_12_[AlgorithmInstance].txt
output/KAT_2_23_[AlgorithmInstance].txt
output/KAT_2_33_[AlgorithmInstance].txt
output/KAT_Loop_[AlgorithmInstance].txt
```

正式提交时，应将这些文件复制到顶层 `Test_Vectors/` 目录，并保留官方 KAT 程序生成的文件名。例如：

```text
Test_Vectors/KAT_2_12_Pavelor-512.txt
Test_Vectors/KAT_2_23_Pavelor-512.txt
Test_Vectors/KAT_2_33_Pavelor-512.txt
Test_Vectors/KAT_Loop_Pavelor-512.txt
```

对于 `Pavelor-768` 和 `Pavelor-1024`，应重复执行相同流程。

注意：生成 `KAT_2_33` 需要大小为 `2^33` 比特的消息缓冲区，即 1 GiB，并且还需要额外工作内存。建议使用具有足够内存的 64 位构建环境。循环测试需要执行 1,000,000 次杂凑计算，因此也需要较长时间。

## 8. 建议构建流程

为单个优化实现实例生成 KAT 文件的典型流程如下：

```sh
cd Implementations/Optimized_Implementation/Pavelor-512
gcc -O3 -std=c99 -Wall -Wextra -maes -msse2 KAT_CryptHash.c drng.c CryptHash_AlgorithmInstance.c -o kat.exe
./kat.exe
```

为单个参考实现实例生成 KAT 文件的典型流程如下：

```sh
cd Implementations/Reference_Implementation/Pavelor-512
gcc -O2 -std=c99 -Wall -Wextra KAT_CryptHash.c drng.c CryptHash_AlgorithmInstance.c -o kat.exe
./kat.exe
```
