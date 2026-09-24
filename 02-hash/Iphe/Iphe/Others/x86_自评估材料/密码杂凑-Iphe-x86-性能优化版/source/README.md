# Iphe x86 性能优化版源码

本目录包含 Iphe-512、Iphe-768、Iphe-1024 三个实例的算法实现文件。以吞吐率为主要目标，采用非递归归约、GM 映射简化、专用小轮、WR/WP 展开和 SWAR 消息装载；正式版本仍为纯 C Performance 路径。

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
-O3 -march=x86-64 -mavx2 -mtune=native -flto -ffat-lto-objects -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra
```

算法实现本身不依赖第三方密码库。提交目录未包含已有的可执行文件、对象文件和 build 临时文件。
