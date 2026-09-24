# Iphe-768 资源优化实现

本目录为 Iphe-768 的资源优化 C99 实现；按本次提交组织要求列入 `Additional_Implementation`。目录包含算法接口源码、官方 KAT 辅助程序、DRNG 和自测程序。

构建：`cmake -S . -B build && cmake --build build`

自测：`ctest --test-dir build --output-on-failure`

生成 KAT：在本目录运行 `build/KAT_CryptHash`（Windows 为 `build/KAT_CryptHash.exe`），结果写入 `output/`。
