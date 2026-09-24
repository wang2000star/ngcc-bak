# Dependency Notes

This delivery targets on-board testing on the STM32F4DISCOVERY. Running functional tests, KAT verification, and performance benchmarks requires:

| Dependency | Purpose |
| --- | --- |
| `arm-none-eabi-gcc`, `binutils-arm-none-eabi` | Cortex-M4 cross-compilation |
| GNU Make | Firmware build |
| `st-flash` | Flashing the board via ST-Link |
| Python 3 | Running test scripts |
| `pyserial`, `tqdm` | Serial communication and progress display; see `requirements.txt` |
| Host GCC / build-essential | Building host-side auxiliary targets required by the test framework |

This directory defaults to `/dev/ttyUSB0` at 38400 baud. No QEMU emulation dependencies are used.
