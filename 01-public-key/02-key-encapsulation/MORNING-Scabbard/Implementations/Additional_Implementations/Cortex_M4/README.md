# Cortex-M4 Implementation

This directory contains the Cortex-M4 implementation of Scabbard KEM for
`scabbard128`, `scabbard256`, and `scabbard512`.

## Layout

- `common/`: STM32F4 HAL glue, `randombytes`, and bare-metal syscall helpers.
- `stm32f405x6.ld`: linker script for the STM32F405 target.
- `scabbard/scabbard128/`: Cortex-M4 implementation for Scabbard-128.
- `scabbard/scabbard256/`: Cortex-M4 implementation for Scabbard-256.
- `scabbard/scabbard512/`: Cortex-M4 implementation for Scabbard-512.

Run all commands from one of the parameter-set directories, for example:

```sh
cd Additional_Implementations/Cortex_M4/scabbard/scabbard128
```

## Host Builds

The normal `Makefile` builds the Linux host KAT generator with GCC. It does not require OpenSSL or `libcrypto`.

```sh
make genKAT
./genKAT
```

`genKAT` generates the KAT output under `output/`.

```sh
make clean
```

Removes host build products and generated host output.

## Cortex-M4 Builds

The board build uses `Makefile.board` and requires `arm-none-eabi-*` tools plus
libopencm3. It does not link OpenSSL or `libcrypto`. Override `OPENCM3DIR` if
libopencm3 is not in the default location.

```sh
make -f Makefile.board test
make -f Makefile.board speed
make -f Makefile.board stack
```

Targets:

- `test`: builds `test.elf`/`test.bin`; runs the board KAT0 self-test.
- `speed`: builds `speed.elf`/`speed.bin`; measures keypair, encaps, and decaps cycles.
- `stack`: builds `stack.elf`/`stack.bin`; measures stack usage.
- `all`: builds `test`, `speed`, and `stack`.
- `clean`: removes board build products such as `.elf`, `.bin`, and `.su` files.

Example:

```sh
make -f Makefile.board all
make -f Makefile.board clean
```

`speed` uses 50 measured runs by default. Override it with:

```sh
make -f Makefile.board speed SPEED_RUN_COUNT=100
```
`stack` uses 50 measured runs by default.

## Assembly Multiplication Options

The M4 builds use optimized assembly polynomial multiplication by default where
available.

- `scabbard128`: `USE_ASM_MUL=1` by default. Use `USE_ASM_MUL=0` for the C path.
- `scabbard256`: `ASM_MUL=mult_notoom_128_16.s` by default.
- `scabbard512`: `ASM_MUL=mult_notoom_256_16.s` by default. Use
  `ASM_MUL=mult_toom4_256_16.s` to select the Toom4 variant.

For example:

```sh
make -f Makefile.board speed ASM_MUL=mult_toom4_256_16.s SPEED_RUN_COUNT=50
```

## Flashing

The Makefiles build `.elf` and `.bin` files. Flash with, for example OpenOCD:

```sh
openocd -f interface/stlink-v2-1.cfg -f target/stm32f4x.cfg \
  -c "program test.elf verify reset exit"
```
