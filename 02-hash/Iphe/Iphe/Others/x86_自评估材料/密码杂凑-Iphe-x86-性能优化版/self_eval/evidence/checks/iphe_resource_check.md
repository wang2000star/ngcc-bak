# Iphe Resource 接入核查

Resource 版本接入正确。adapter 调用 Resource 对应符号，静态库路径指向 Resource 源码构建产物，不存在误接 Reference 或 Performance 的情况。

核查内容：

- Resource adapter 使用 `CryptHash_iphe512_res`、`CryptHash_iphe768_res`、`CryptHash_iphe1024_res`。
- Resource 静态库对应资源优化源码路径。
- archive 审计可见重命名后的 `CryptHash`、permutation、递归 `S`、轮常量 `C` 和合理 section。
- Resource 编译参数采用 `-Os -march=x86-64 -mavx2 -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra`。
- Resource 性能慢于 Performance 是资源优化版实现和 `-Os` 配置的预期表现。
