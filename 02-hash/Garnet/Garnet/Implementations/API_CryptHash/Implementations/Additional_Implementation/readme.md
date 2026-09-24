# Garnet hash算法32位嵌入式优化实现

## 1. 简介

本模块是 Garnet 算法家族的嵌入式实现，支持从 512 位到 1024 位的全变体配置。现已支持以下环境：

- **Zephyr RTOS** (基于 RISC-V RV32IMAC, 上海乐鑫 ESP32-C6)
- **FreeRTOS** (基于 ARM Cortex-M4,  意法半导体 STM32F407vgt6)

## 2. 快速开始

### 2.1 在 FreeRTOS 上运行

- **测试文件**：`src/garnet_app_freeRTOS.c`
- **构建环境**：STM32CubeIDE / makefile
- **关键配置**：确保开启 `-O3` 优化，并正确配置 `.ld` 链接脚本中的 CCMRAM 段。makefile包含garnet.mk

### 2.2 在 Zephyr 上运行

- **测试文件**：`src/garnet_app_zephyr.c`
- **构建命令**：
  ```bash
  west build -b esp32c6_devkitc/esp32c6/hpcore
  west flash
  ```
- **关键配置**：`prj.conf` 需包含 `CONFIG_SPEED_OPTIMIZATIONS=y` 和 `CONFIG_PICOLIBC_IO_FLOAT=y`。

## 5. 项目结构

- `hash_garnet_universal.c`: 统一的核心算法引擎（全平台共享）。
- `garnet_app_freeRTOS.c`: **FreeRTOS** 专属测试逻辑与 DWT 计时器驱动。
- `garnet_app_zephyr.c`: **Zephyr** 专属测试逻辑与 SoC HAL 计时器集成。
- `garnet_config.h`: 算法 Counter 配置与性能宏定义。
- `main.cpp`: qemu仿真garnet DEMO
- `Makefile`: 针对 QEMU 用户态仿真的交叉编译。
- `CryptHash_Garnet.h`：标准hash接口引出

