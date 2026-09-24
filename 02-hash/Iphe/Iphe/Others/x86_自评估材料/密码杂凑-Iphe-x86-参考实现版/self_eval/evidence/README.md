# Iphe x86 参考实现版 原始证据目录说明

本目录存放 Iphe x86 参考实现版 自评估报告引用的全部正式原始证据。

## 子目录说明

- kat/：官方 KAT 测试向量或 KAT 状态说明。
- 
gcc_json/：NGCC 生成的 JSON 结果文件。
- 
gcc_log/：NGCC 生成的日志或 PDF 日志。
- csv/：本版本性能、资源和全局汇总 CSV/Markdown 数据。
- udit/：静态库成员、符号和 section 审计结果。
- stack_usage/：GCC -fstack-usage 生成的 .su 文件。
- checks/：数据完整性、接入核查、源码一致性等检查结果。
- scripts/：用于运行测试、汇总数据或检查完整性的脚本。

报告中的“原始证据索引”应只引用本目录下的相对路径。