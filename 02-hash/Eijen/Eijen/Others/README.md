# 密码杂凑-Eijen-x86-提交包

本目录按《密码杂凑算法提交要求.pdf》和《新一代商用密码算法 x86 架构实现自评估指引.pdf》整理 Eijen 的 x86 代码提交材料。

当前提交包只保留 x86 相关内容，不包含 FPGA 或其他硬件实现。

## 目录结构

- `Implementations/`：对应《密码杂凑算法提交要求》第 3.4 节的算法实现代码目录。
  - `Reference_Implementation/Eijen-*`：参考实现，使用 ISO C99 和 `CryptHash` API。
  - `Optimized_Implementation/Eijen-*`：x86-64 AVX2 性能优化实现，使用相同 `CryptHash` API。
  - `Additional_Implementation/`：当前不提交额外实现，仅保留说明文件。
- `Test_Vectors/`：对应第 3.5 节的算法测试向量目录。
  - 覆盖 `Eijen-256`、`Eijen-384`、`Eijen-512`、`Eijen-768`、`Eijen-1024`。
  - 包含 `KAT_2_12_*`、`KAT_2_23_*`、`KAT_2_33_*`、`KAT_Loop_*` 四类文件。
- `scripts/`：构建全部 `CryptHash` API 实例、重新生成测试向量的辅助脚本。
- `x86_Self_Assessment/`：对应 x86 自评估指引的实现版本材料。
  - `密码杂凑-Eijen-x86-参考实现版`
  - `密码杂凑-Eijen-x86-性能优化版`
  - `密码杂凑-Eijen-x86-资源优化版`
- `MISSING_MATERIALS.md`：最终正式提交前仍需人工补齐的非代码材料。

## 构建与测试

构建所有 `CryptHash` API 实例：

```sh
./scripts/build_all.sh
```

重新生成提交要求中的测试向量：

```sh
./scripts/generate_test_vectors.sh
```

单独复核某个 x86 自评估版本：

```sh
cmake -S x86_Self_Assessment/密码杂凑-Eijen-x86-参考实现版 -B /tmp/eijen-ref-build -DCMAKE_BUILD_TYPE=Release
cmake --build /tmp/eijen-ref-build -j 1
ctest --test-dir /tmp/eijen-ref-build --output-on-failure
```

或直接运行该版本目录内的完整自评估脚本：

```sh
cd x86_Self_Assessment/密码杂凑-Eijen-x86-参考实现版
self_assessment/run_self_assessment.sh
```

性能优化版和资源优化版将路径替换为对应目录即可。
