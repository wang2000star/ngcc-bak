# AFS-KEX on ARM Cortex-M4

本目录为 AFS-KEX 的 ARM Cortex-M4 参考实现版交付，包含 `AFS-KEX-C128`、`AFS-KEX-C256`、`AFS-KEX-C512` 三个参数集。

| 方案 | 源码目录 | 实现 |
| --- | --- | --- |
| AFS-KEX-C128 | `crypto_kex/afs-kex-128/ref` | `ref` |
| AFS-KEX-C256 | `crypto_kex/afs-kex-256/ref` | `ref` |
| AFS-KEX-C512 | `crypto_kex/afs-kex-512/ref` | `ref` |

其余目录为自评估构建与测试框架：`common/`、`mupq/`、`libopencm3/`、`mk/`、`ldscripts/`、`Makefile`。`Test_Vectors/` 存放随包交付的固定 KAT 文件。

## 测试命令

所有命令在本目录执行，默认实板平台为 `stm32f4discovery`，串口为 `/dev/ttyUSB0`。

```sh
python3 test.py --platform stm32f4discovery --uart /dev/ttyUSB0 afs-kex-128
python3 benchmarks.py --platform stm32f4discovery --uart /dev/ttyUSB0 -i 1000 afs-kex-128
python3 kat.py --platform stm32f4discovery --uart /dev/ttyUSB0 afs-kex-128
make clean
```

`kat.py` 读取 `Test_Vectors/` 中的固定 KAT 文件，板端运行 `testvectors_iccs` 后比对完整输出。

## 测试结果

见 `自评估报告.md`。
