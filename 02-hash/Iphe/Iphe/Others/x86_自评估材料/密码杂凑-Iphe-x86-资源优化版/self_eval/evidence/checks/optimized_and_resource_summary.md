# Iphe 实现摘要

本文件仅保留提交包内需要引用的实现摘要。

- Reference：正确性基准，用于摘要一致性验证。
- Performance：吞吐率优化版，保持输出与 Reference 一致。
- Resource：资源占用优化版，降低源码存储和静态代码体积。

正确性状态：三版本三实例在 NGCC functional self-test 中均为 PASS；S1-S8 数据完整；非字节对齐输入和 rate 边界测试已有脚本证据。

资源状态：Resource 接入已核查，静态库、符号、section、栈使用文件均存在。
