# DTRU ARM Resource-Optimized

This directory contains the resource-optimized implementation of the DTRU key encapsulation algorithm for ARM Cortex-M4, covering seven parameter sets: `dtru-light`, `dtru-648`, `dtru-768`, `dtru-1024`, `dtru-1536`, `dtru-2048`, and `dtru-prime`.

| Parameter Set | Source Directory | Implementation |
| --- | --- | --- |
| DTRU-Light | `crypto_kem/dtru-light/m4fstack` | `m4fstack` |
| DTRU-648 | `crypto_kem/dtru-648/m4fstack` | `m4fstack` |
| DTRU-768 | `crypto_kem/dtru-768/m4fstack` | `m4fstack` |
| DTRU-1024 | `crypto_kem/dtru-1024/m4fstack` | `m4fstack` |
| DTRU-1536 | `crypto_kem/dtru-1536/m4fstack` | `m4fstack` |
| DTRU-2048 | `crypto_kem/dtru-2048/m4fstack` | `m4fstack` |
| DTRU-Prime | `crypto_kem/dtru-prime/m4fstack` | `m4fstack` |

`Test_Vectors/` contains standard KAT files, as well as `PK_PACK_OPT` KAT files for parameter sets that support public key compression optimization. `PK_PACK_OPT` covers `dtru-648`, `dtru-768`, `dtru-1024`, `dtru-1536`, and `dtru-2048`.

Common commands:

```sh
python3 test.py --platform stm32f4discovery --uart /dev/ttyUSB0 dtru-light
python3 kat.py --platform stm32f4discovery --uart /dev/ttyUSB0
python3 kat.py --platform stm32f4discovery --uart /dev/ttyUSB0 --pk-pack-opt
python3 benchmarks.py --platform stm32f4discovery --uart /dev/ttyUSB0 -i 1000 dtru-light
```

Clean build artifacts:

```sh
make PLATFORM=stm32f4discovery clean
```
