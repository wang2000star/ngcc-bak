# Iphe 密码杂凑算法提交目录

本目录按《密码杂凑算法提交要求》第 3.4 节和第 3.5 节整理，包含 Iphe 三个算法实例的三类实现代码与测试向量。

## 目录

- `Implementations/Reference_Implementation/`：ISO C99 参考实现。
- `Implementations/Optimized_Implementation/`：性能优化实现。
- `Implementations/Additional_Implementation/`：资源优化实现。
- `Test_Vectors/`：Iphe-512、Iphe-768、Iphe-1024 的 12 个 KAT 文件。
- `submit_build_and_kat_check.md`：最终构建、KAT 对比及完整性检查记录。

每类实现均覆盖 Iphe-512、Iphe-768、Iphe-1024。每个实例目录包含算法实现、官方接口头文件、官方 KAT 辅助程序、DRNG、自测程序及 CMake 自动化构建脚本。

## 构建单个实例

进入任一实例目录后执行：

```sh
cmake -S . -B build
cmake --build build
ctest --test-dir build --output-on-failure
```

以上命令已按 MSYS2 UCRT64 的 GCC/CMake 环境验证。其他支持 C99 与 CMake 3.16 以上的环境也可使用。

## 生成并验证 KAT

在实例目录中运行构建生成的 `KAT_CryptHash`（Windows 为 `build/KAT_CryptHash.exe`）。程序在当前工作目录的 `output/` 中生成四个 KAT 文件：

- `KAT_2_12_[AlgorithmInstance].txt`
- `KAT_2_23_[AlgorithmInstance].txt`
- `KAT_2_33_[AlgorithmInstance].txt`
- `KAT_Loop_[AlgorithmInstance].txt`

将生成文件与 `../../../Test_Vectors/` 中同名文件逐字节比较即可验证。实际验证结果见 `submit_build_and_kat_check.md`。
