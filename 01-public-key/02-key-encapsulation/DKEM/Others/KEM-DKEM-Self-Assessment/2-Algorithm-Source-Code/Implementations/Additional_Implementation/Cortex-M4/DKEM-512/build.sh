#!/usr/bin/env bash
# DKEM-512 on ARM Cortex-M4 (STM32, Plantard arithmetic + matacc). Self-contained.
# Requires: arm-none-eabi-gcc and qemu-system-arm on PATH (no hardware needed).
#   bash build.sh        -> build the ELF and run the round-trip self-test on QEMU.
# For real hardware (STM32H750/F429), use the ELF with the board's flash/run flow.
set -e
GCC=${GCC:-arm-none-eabi-gcc}
QEMU=${QEMU:-qemu-system-arm}
ARCH="-mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16 -O2 -ffunction-sections -fdata-sections -std=gnu99 -nostdlib"
DEFS="-DDKE_MODE=512 -DDKE_HASH=0 -DDKE_RANDOM=0 -DDKE_USE_CORTEX_M4_PLANTARD -DDKE_USE_MATACC"
INC="-I. -Icortex-m4 -Icortex-m4/plantard"
CORE="$(ls *.c) cortex-m4/dke_m4_plantard.c cortex-m4/plantard/plantard_zetas.c"
ASM="cortex-m4/sm3_compress_asm_m4.S qemu/startup_qemu.S cortex-m4/plantard/plantard512_fastntt.S cortex-m4/plantard/plantard512_fastinvntt.S cortex-m4/plantard/plantard512_fastbasemul.S cortex-m4/plantard/plantard512_fastaddsub.S cortex-m4/plantard/plantard512_reduce_asm.S cortex-m4/plantard/plantard512_poly_asm.S cortex-m4/plantard/plantard512_matacc_asm.S "
$GCC $ARCH $DEFS $INC $CORE qemu/qemu_dke.c qemu/syscalls.c $ASM \
   -T qemu/netduino.ld -Wl,--gc-sections \
   -Wl,--start-group -lgcc -lnosys -lc -Wl,--end-group -o kat_DKEM-512.elf
echo "Built kat_DKEM-512.elf — running round-trip self-test on QEMU:"
$QEMU -M netduinoplus2 -nographic -semihosting-config enable=on,target=native -kernel kat_DKEM-512.elf
