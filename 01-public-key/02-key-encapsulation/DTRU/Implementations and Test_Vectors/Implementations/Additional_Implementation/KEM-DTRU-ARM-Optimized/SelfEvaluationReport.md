# DTRU ARM Optimized Self-Evaluation Report

## 1. Algorithm Overview

| Item | Value |
| --- | --- |
| Algorithm Type | Key Encapsulation |
| Algorithm Name | DTRU |
| Implementation Version | Optimized |
| Implementation Directory | `crypto_kem/dtru-{light,648,768,1024,1536,2048,prime}/m4fspeed` |
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
| DTRU-Light | `KAT_KEM_DTRU-Light_SPEED.txt` | 10 | 640 | 864 | 512 | 32 | PASS |
| DTRU-648 | `KAT_KEM_DTRU-648_SPEED.txt` | 10 | 972 | 1328 | 729 | 32 | PASS |
| DTRU-768 | `KAT_KEM_DTRU-768_SPEED.txt` | 10 | 1152 | 1568 | 960 | 32 | PASS |
| DTRU-1024 | `KAT_KEM_DTRU-1024_SPEED.txt` | 10 | 1536 | 2080 | 1280 | 32 | PASS |
| DTRU-1536 | `KAT_KEM_DTRU-1536_SPEED.txt` | 10 | 2304 | 3136 | 1920 | 64 | PASS |
| DTRU-2048 | `KAT_KEM_DTRU-2048_SPEED.txt` | 10 | 3072 | 3904 | 2560 | 64 | PASS |
| DTRU-Prime | `KAT_KEM_DTRU-Prime_SPEED.txt` | 10 | 1495 | 1935 | 1359 | 32 | PASS |

### PK_PACK_OPT KAT

| Parameter Set | KAT File | Test Cases | PK | SK | CT | SS | Result |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| DTRU-648 | `KAT_KEM_DTRU-648_PK_PACK_OPT_SPEED.txt` | 10 | 954 | 1310 | 729 | 32 | PASS |
| DTRU-768 | `KAT_KEM_DTRU-768_PK_PACK_OPT_SPEED.txt` | 10 | 1130 | 1546 | 960 | 32 | PASS |
| DTRU-1024 | `KAT_KEM_DTRU-1024_PK_PACK_OPT_SPEED.txt` | 10 | 1506 | 2050 | 1280 | 32 | PASS |
| DTRU-1536 | `KAT_KEM_DTRU-1536_PK_PACK_OPT_SPEED.txt` | 10 | 2259 | 3091 | 1920 | 64 | PASS |
| DTRU-2048 | `KAT_KEM_DTRU-2048_PK_PACK_OPT_SPEED.txt` | 10 | 3012 | 3844 | 2560 | 64 | PASS |

## 4. Performance Benchmarks

The following table shows the speed benchmark results for the optimized implementation, measured in cycles.

| Parameter Set | Key Generation | Encapsulation | Decapsulation |
| --- | ---: | ---: | ---: |
| DTRU-Light | 273,796 | 238,641 | 469,766 |
| DTRU-648 | 911,459 | 413,127 | 806,561 |
| DTRU-768 | 551,022 | 477,117 | 861,066 |
| DTRU-1024 | 854,615 | 612,515 | 1,175,176 |
| DTRU-1536 | 918,191 | 870,543 | 1,595,825 |
| DTRU-2048 | 2,181,919 | 1,898,264 | 3,584,478 |
| DTRU-Prime | 219,541,044 | 769,126 | 1,593,260 |
