# ngcc_bench_iphe_resource

本目录是 Iphe x86 资源优化版 的独立 NGCC 风格自评估工程，只注册本版本三个算法实例。

## 已接入算法 ID

- `iphe-512-res`
- `iphe-768-res`
- `iphe-1024-res`

## 构建命令

`powershell
mkdir build
cd build
cmake ..
cmake --build . -j
`

## 128 Bytes 基础测试命令

`powershell
.\ngcc_bench.exe -a iphe-512-res,iphe-768-res,iphe-1024-res -t 1000 -l 128
`

## S1-S8 长度

S1-S8 输入长度为 32、128、512、1024、4096、8192、16384、65536 Bytes。

## 一键运行

`powershell
.\run_s1_s8.ps1
`

un_s1_s8.ps1 会构建并运行本版本三个实例的 S1-S8 测试。运行结果默认输出到本工程的 eports/ 和 logs/。

NGCC 原始输出单位为 Mbps，报告中 MB/s 按 MB/s = Mbps / 8 换算。cycles 使用 __rdtscp 计数。重新运行结果可能受系统调度和负载影响。
