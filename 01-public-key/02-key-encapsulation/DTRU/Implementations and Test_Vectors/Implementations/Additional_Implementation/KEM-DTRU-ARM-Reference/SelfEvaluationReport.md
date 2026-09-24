# DTRU ARM Reference Self-Evaluation Report

## 1. Algorithm Overview

| Item | Value |
| --- | --- |
| Algorithm Type | Key Encapsulation |
| Algorithm Name | DTRU |
| Implementation Version | Reference |
| Implementation Directory | `crypto_kem/dtru-{light,648,768,1024,1536,2048,prime}/ref` |
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
| DTRU-Light | `KAT_KEM_DTRU-Light.txt` | 10 | 640 | 864 | 512 | 32 | PASS |
| DTRU-648 | `KAT_KEM_DTRU-648.txt` | 10 | 972 | 1328 | 729 | 32 | PASS |
| DTRU-768 | `KAT_KEM_DTRU-768.txt` | 10 | 1152 | 1568 | 960 | 32 | PASS |
| DTRU-1024 | `KAT_KEM_DTRU-1024.txt` | 10 | 1536 | 2080 | 1280 | 32 | PASS |
| DTRU-1536 | `KAT_KEM_DTRU-1536.txt` | 10 | 2304 | 3136 | 1920 | 64 | PASS |
| DTRU-2048 | `KAT_KEM_DTRU-2048.txt` | 10 | 3072 | 3904 | 2560 | 64 | PASS |
| DTRU-Prime | `KAT_KEM_DTRU-Prime.txt` | 10 | 1495 | 1935 | 1359 | 32 | PASS |

### PK_PACK_OPT KAT

| Parameter Set | KAT File | Test Cases | PK | SK | CT | SS | Result |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| DTRU-648 | `KAT_KEM_DTRU-648_PK_PACK_OPT.txt` | 10 | 954 | 1310 | 729 | 32 | PASS |
| DTRU-768 | `KAT_KEM_DTRU-768_PK_PACK_OPT.txt` | 10 | 1130 | 1546 | 960 | 32 | PASS |
| DTRU-1024 | `KAT_KEM_DTRU-1024_PK_PACK_OPT.txt` | 10 | 1506 | 2050 | 1280 | 32 | PASS |
| DTRU-1536 | `KAT_KEM_DTRU-1536_PK_PACK_OPT.txt` | 10 | 2259 | 3091 | 1920 | 64 | PASS |
| DTRU-2048 | `KAT_KEM_DTRU-2048_PK_PACK_OPT.txt` | 10 | 3012 | 3844 | 2560 | 64 | PASS |

## 4. Performance Benchmarks

The following table shows the speed benchmark results for the reference implementation, measured in cycles.

| Parameter Set | Key Generation | Encapsulation | Decapsulation |
| --- | ---: | ---: | ---: |
| DTRU-Light | 464,845 | 447,286 | 887,039 |
| DTRU-648 | 1,174,756 | 676,426 | 1,333,159 |
| DTRU-768 | 990,982 | 867,798 | 1,642,410 |
| DTRU-1024 | 1,354,139 | 1,038,823 | 2,040,310 |
| DTRU-1536 | 1,706,021 | 1,659,292 | 3,185,080 |
| DTRU-2048 | 3,231,574 | 2,386,203 | 4,545,928 |
| DTRU-Prime | 219,958,105 | 1,186,221 | 2,433,139 |

## 5. Resource Consumption Benchmarks

The following table shows the stack usage benchmark results for the reference implementation, measured in bytes.

| Parameter Set | Key Generation | Encapsulation | Decapsulation |
| --- | ---: | ---: | ---: |
| DTRU-Light | 5,632 | 6,776 | 7,492 |
| DTRU-648 | 8,608 | 9,004 | 9,752 |
| DTRU-768 | 9,136 | 10,664 | 11,744 |
| DTRU-1024 | 12,240 | 13,912 | 15,304 |
| DTRU-1536 | 17,416 | 20,088 | 22,168 |
| DTRU-2048 | 23,956 | 26,712 | 29,424 |
| DTRU-Prime | 39,500 | 41,828 | 43,300 |
