# DTRU ARM Resource-Optimized Self-Evaluation Report

## 1. Algorithm Overview

| Item | Value |
| --- | --- |
| Algorithm Type | Key Encapsulation |
| Algorithm Name | DTRU |
| Implementation Version | Resource-Optimized |
| Implementation Directory | `crypto_kem/dtru-{light,648,768,1024,1536,2048,prime}/m4fstack` |
| Parameter Sets | DTRU-Light, DTRU-648, DTRU-768, DTRU-1024, DTRU-1536, DTRU-2048, DTRU-Prime |
| Specified Interface | `kem_keygen`, `kem_enc`, `kem_dec` |

## 2. Evaluation Environment

| Item | Current Environment |
| --- | --- |
| Host | x86_64 Linux Mint 22.3, Linux 6.17.0-35-generic |
| CPU | AMD Ryzen 5 9500F 6-Core Processor |
| Cross Compiler | `arm-none-eabi-gcc` 13.2.1 |
| Host Compiler | GCC 13.3.0 |
| Build Tool | GNU Make 4.3 |
| Python | 3.12.3 |
| Target Platform | `stm32f4discovery`, Cortex-M4, `/dev/ttyUSB0`, 38400 baud |

## 3. Functional Tests

Functional tests use the ICCS KAT files in the bundled `Test_Vectors/` directory, with 10 test cases per parameter set. The standard KAT verification command is:

```sh
python3 kat.py --platform stm32f4discovery --uart /dev/ttyUSB0
```

Parameter sets that support public key compression optimization also have `PK_PACK_OPT` KAT files. The verification command is:

```sh
python3 kat.py --platform stm32f4discovery --uart /dev/ttyUSB0 --pk-pack-opt
```

### Standard KAT

| Parameter Set | KAT File | Test Cases | PK | SK | CT | SS | Result |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| DTRU-Light | `KAT_KEM_DTRU-Light_STACK.txt` | 10 | 640 | 864 | 512 | 32 | PASS |
| DTRU-648 | `KAT_KEM_DTRU-648_STACK.txt` | 10 | 972 | 1328 | 729 | 32 | PASS |
| DTRU-768 | `KAT_KEM_DTRU-768_STACK.txt` | 10 | 1152 | 1568 | 960 | 32 | PASS |
| DTRU-1024 | `KAT_KEM_DTRU-1024_STACK.txt` | 10 | 1536 | 2080 | 1280 | 32 | PASS |
| DTRU-1536 | `KAT_KEM_DTRU-1536_STACK.txt` | 10 | 2304 | 3136 | 1920 | 64 | PASS |
| DTRU-2048 | `KAT_KEM_DTRU-2048_STACK.txt` | 10 | 3072 | 3904 | 2560 | 64 | PASS |
| DTRU-Prime | `KAT_KEM_DTRU-Prime_STACK.txt` | 10 | 1495 | 1935 | 1359 | 32 | PASS |

### PK_PACK_OPT KAT

| Parameter Set | KAT File | Test Cases | PK | SK | CT | SS | Result |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| DTRU-648 | `KAT_KEM_DTRU-648_PK_PACK_OPT_STACK.txt` | 10 | 954 | 1310 | 729 | 32 | PASS |
| DTRU-768 | `KAT_KEM_DTRU-768_PK_PACK_OPT_STACK.txt` | 10 | 1130 | 1546 | 960 | 32 | PASS |
| DTRU-1024 | `KAT_KEM_DTRU-1024_PK_PACK_OPT_STACK.txt` | 10 | 1506 | 2050 | 1280 | 32 | PASS |
| DTRU-1536 | `KAT_KEM_DTRU-1536_PK_PACK_OPT_STACK.txt` | 10 | 2259 | 3091 | 1920 | 64 | PASS |
| DTRU-2048 | `KAT_KEM_DTRU-2048_PK_PACK_OPT_STACK.txt` | 10 | 3012 | 3844 | 2560 | 64 | PASS |

## 4. Resource Consumption Benchmarks

The following table shows the stack usage benchmark results for the resource-optimized implementation, measured in bytes.

| Parameter Set | Key Generation | Encapsulation | Decapsulation |
| --- | ---: | ---: | ---: |
| DTRU-Light | 3,260 | 3,596 | 4,148 |
| DTRU-648 | 4,672 | 4,892 | 5,556 |
| DTRU-768 | 4,732 | 5,928 | 6,928 |
| DTRU-1024 | 6,364 | 7,660 | 8,980 |
| DTRU-1536 | 9,328 | 10,568 | 12,568 |
| DTRU-2048 | 12,728 | 14,172 | 16,924 |
| DTRU-Prime | 34,276 | 35,260 | 36,548 |
