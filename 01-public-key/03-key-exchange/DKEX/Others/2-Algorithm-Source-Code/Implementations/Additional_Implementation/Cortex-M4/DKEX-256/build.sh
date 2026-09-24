#!/usr/bin/env bash
# DKEX-256 on ARM Cortex-M4. DKE ephemeral KEM = Plantard + matacc (M4 asm); ML-DSA
# signature = NIST reference (portable C). 3-pass mutually-authenticated KEX, fully
# derandomized. Self-contained; no hardware needed.
#   bash build.sh   -> build ELF + run the 3-pass handshake self-test on QEMU.
# Requires arm-none-eabi-gcc and qemu-system-arm on PATH.
set -e
GCC=${GCC:-arm-none-eabi-gcc}
QEMU=${QEMU:-qemu-system-arm}
ARCH="-mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16 -O2 -ffunction-sections -fdata-sections -std=gnu99 -nostdlib"
DEFS="-DADKEX_MODE=256 -DDKE_MODE=256 -DDKE_HASH=0 -DDKE_RANDOM=0 -DDKE_USE_CORTEX_M4_PLANTARD -DDKE_USE_MATACC -DADKEX_SIG_BACKEND_MLDSA -DADKEX_SIG_MLDSA_LEVEL=5 -DDILITHIUM_MODE=5"
rm -rf obj; mkdir -p obj; i=0
# DKE core (portable C) + M4 Plantard backend
for f in sm3 dke_sm3 dke_hash reduce ntt poly polyvec random_sampling dke_utils packing verify dkecpa drng auxfunc; do $GCC $ARCH $DEFS   -c $f.c -o obj/c$i.o; i=$((i+1)); done
for s in cortex-m4/dke_m4_plantard.c cortex-m4/plantard/plantard_zetas.c; do $GCC $ARCH $DEFS -I. -Icortex-m4 -Icortex-m4/plantard -c "$s" -o obj/c$i.o; i=$((i+1)); done
for s in cortex-m4/sm3_compress_asm_m4.S qemu/startup_mps2.S cortex-m4/plantard/plantard_fastntt.S cortex-m4/plantard/plantard_fastinvntt.S cortex-m4/plantard/plantard_fastbasemul.S cortex-m4/plantard/plantard_fastaddsub.S cortex-m4/plantard/plantard_reduce_asm.S cortex-m4/plantard/plantard_poly_asm.S cortex-m4/plantard/plantard_matacc_asm.S; do $GCC $ARCH $DEFS -I. -Icortex-m4/plantard -c "$s" -o obj/a$i.o; i=$((i+1)); done
# ML-DSA reference (separate -I group:  and dilithium/ share header basenames)
for f in fips202 ntt packing poly polyvec reduce rounding sign symmetric-shake; do $GCC $ARCH $DEFS -Idilithium -c dilithium/$f.c -o obj/d$i.o; i=$((i+1)); done
# DKEX protocol + sig adapter + randombytes hook + harness
for s in adkex_derand.c adkex_sig_mldsa.c randombytes.c qemu/qemu_dkex.c qemu/syscalls.c; do $GCC $ARCH $DEFS -I.   -Idilithium -c "$s" -o obj/l$i.o; i=$((i+1)); done
$GCC $ARCH obj/*.o -T qemu/mps2.ld -Wl,--gc-sections -Wl,--start-group -lgcc -lnosys -lc -Wl,--end-group -o kat_DKEX-256.elf
echo "Built kat_DKEX-256.elf — running DKEX 3-pass handshake self-test on QEMU:"
$QEMU -M mps2-an386 -nographic -semihosting-config enable=on,target=native -kernel kat_DKEX-256.elf
