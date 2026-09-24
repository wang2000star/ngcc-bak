# Iphe NGCC 数据完整性检查

- 固定绑核：逻辑 CPU 0，亲和性 mask 0x1。
- 三版本三实例 functional self-test：PASS。
- S1-S8 覆盖：72/72 行完整。
- JSON：72/72 存在。
- 日志：stdout/stderr 各 72 份。
- Mbps 到 MB/s 换算：按 `MB/s = Mbps / 8`。
- 官方 KAT：三实例四类 KAT 文件均已复制。
- 栈峰值静态分析文件：9/9 存在。
- 静态库审计文件：9/9 存在。
- 数据状态：完整。
