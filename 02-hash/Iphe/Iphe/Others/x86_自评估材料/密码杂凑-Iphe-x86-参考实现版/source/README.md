# Iphe x86 参考实现版源码

本目录包含 Iphe-512、Iphe-768、Iphe-1024 三个实例的算法实现文件。语义清晰、结构直接的正确性基准实现，用于其余版本的摘要一致性验证。

## 目录

- `Iphe-512/`: 512-bit 摘要实例。
- `Iphe-768/`: 768-bit 摘要实例。
- `Iphe-1024/`: 1024-bit 摘要实例。
- `CMakeLists.txt`: 同时生成三个独立静态库，并通过编译宏避免 `CryptHash` 符号冲突。

## 构建

```powershell
cmake -S . -B build -G "MinGW Makefiles"
cmake --build build -j
```

实际 NGCC 自评估编译参数：

```text
-std=c99 -Wpedantic -Wall -Wextra -O2
```

算法实现本身不依赖第三方密码库。提交目录未包含已有的可执行文件、对象文件和 build 临时文件。
