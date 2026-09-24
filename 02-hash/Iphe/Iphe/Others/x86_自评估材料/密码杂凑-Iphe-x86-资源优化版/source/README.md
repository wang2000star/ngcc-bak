# Iphe x86 资源优化版源码

本目录包含 Iphe-512、Iphe-768、Iphe-1024 三个实例的算法实现文件。以源码与静态代码体积为主要目标，使用统一 small_round、循环 WR/WP 和紧凑辅助逻辑；已确认未误接 Reference 或 Performance。

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
-Os -march=x86-64 -mavx2 -flto -ffat-lto-objects -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra
```

算法实现本身不依赖第三方密码库。提交目录未包含已有的可执行文件、对象文件和 build 临时文件。
