# 官方 KAT 证据状态

已有官方 KAT 向量文件已复制到各版本 evidence/<version>/kat/。本轮未重新运行 KAT_CryptHash.exe，也未修改 KAT_CryptHash.c、drng.c 或 drng.h。

覆盖项：

- KAT_2_12：0 至 2^12 bit 消息。
- KAT_2_23：2^23 bit 消息。
- KAT_2_33：2^33 bit 消息。
- KAT_Loop：2^13 bit loop 测试。

三实例 Iphe-512、Iphe-768、Iphe-1024 均包含上述四类文件。
