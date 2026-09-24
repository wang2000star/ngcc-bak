#!/usr/bin/env bash
# ADKEX-512 on ARM Cortex-M4. DKE core = Plantard arithmetic + matacc; ADKEX = 2-pass
# derandomized authenticated key exchange. Self-contained; no hardware needed.
#   bash build.sh   -> build ELF + run the handshake round-trip self-test on QEMU.
# Requires arm-none-eabi-gcc and qemu-system-arm on PATH.
set -e
GCC=${GCC:-arm-none-eabi-gcc}
QEMU=${QEMU:-qemu-system-arm}
ARCH="-mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16 -O2 -ffunction-sections -fdata-sections -std=gnu99 -nostdlib"
DEFS="-DADKEX_MODE=512 -DDKE_MODE=512 -DDKE_HASH=0 -DDKE_RANDOM=0 -DDKE_USE_CORTEX_M4_PLANTARD -DDKE_USE_MATACC"
INC="-I.   -Icortex-m4 -Icortex-m4/plantard"
CORE="KEM_AlgorithmInstance.c auxfunc.c dke_hash.c dke_sm3.c dke_utils.c dkecca.c dkecpa.c drng.c ntt.c packing.c poly.c polyvec.c random_sampling.c reduce.c sm3.c verify.c cortex-m4/dke_m4_plantard.c cortex-m4/plantard/plantard_zetas.c adkex_derand.c"
ASM="cortex-m4/sm3_compress_asm_m4.S qemu/startup_qemu.S cortex-m4/plantard/plantard512_fastntt.S cortex-m4/plantard/plantard512_fastinvntt.S cortex-m4/plantard/plantard512_fastbasemul.S cortex-m4/plantard/plantard512_fastaddsub.S cortex-m4/plantard/plantard512_reduce_asm.S cortex-m4/plantard/plantard512_poly_asm.S cortex-m4/plantard/plantard512_matacc_asm.S "
$GCC $ARCH $DEFS $INC $CORE qemu/qemu_kex.c qemu/syscalls.c $ASM    -T qemu/netduino.ld -Wl,--gc-sections    -Wl,--start-group -lgcc -lnosys -lc -Wl,--end-group -o kat_ADKEX-512.elf
echo "Built kat_ADKEX-512.elf — running ADKEX 2-pass handshake self-test on QEMU:"
$QEMU -M netduinoplus2 -nographic -semihosting-config enable=on,target=native -kernel kat_ADKEX-512.elf
