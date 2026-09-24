# WChain x86 提交包说明

本目录按《密码杂凑算法提交要求》和《新一代商用密码算法 x86 架构实现自评估指引》整理，当前只保留 x86 相关材料。

## 目录对应关系

| 提交要求 | 本目录 |
|---|---|
| 算法基本信息（签字扫描 PDF） | `Algorithm_Basic_Info/`，当前只有模板，需补签字扫描 PDF |
| 算法文本（PDF） | `Algorithm_Text/WChain_Algorithm_Text.pdf` |
| 算法实现代码 | `Implementations/` |
| 算法测试向量 | `Test_Vectors/` |
| 知识产权声明（签字扫描 PDF） | `Intellectual_Property/`，当前只有模板，需补签字扫描 PDF |
| x86 自评估材料 | `x86_Self_Evaluation/密码杂凑算法-WChain-x86-性能优化版/` |

## 当前包含内容

- `Implementations/Reference_Implementation/WChain-V1-512`
- `Implementations/Reference_Implementation/WChain-V2-1024`
- `Implementations/Optimized_Implementation/WChain-V1-512`
- `Implementations/Optimized_Implementation/WChain-V2-1024`
- `Test_Vectors/KAT_2_12_*`, `KAT_2_23_*`, `KAT_2_33_*`, `KAT_Loop_*`
- x86 性能优化版自评估代码、原始日志、CSV 和报告

## 复现命令

从本目录运行单个算法实例的 KAT 构建：

```sh
cd Implementations/Optimized_Implementation/WChain-V1-512
./build_kat.sh
```

x86 自评估报告中的完整复现脚本仍以项目根目录布局为基准：

```sh
bash bench/run_x86_self_eval.sh
```

提交前应先补齐 `MISSING_REQUIRED_FILES.md` 中列出的签字扫描 PDF。
