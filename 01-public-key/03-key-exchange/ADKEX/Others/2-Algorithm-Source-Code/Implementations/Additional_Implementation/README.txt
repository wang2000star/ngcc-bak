Additional Implementations — ADKEX
================================================================
Implementations on platforms other than the mainstream 64-bit PC (Section 3.4 encourages
these). Reference = portable ISO C; optimized = x86-64 AVX2. The additional implementations
below are organized by platform: arm64 (AArch64_NEON) and 32-bit ARM (Cortex-M4).

AArch64_NEON/  — ARM 64-bit (AArch64), ARMv8.2-A
----------------------------------------------------------------
Fastest arm64 path: ARMv8.2-A assembly (adapted from the mlkem-native project, Apache-2.0 OR ISC OR MIT) for NTT / inverse-NTT / basemul /
reduce, with NEON polynomial code. Hashing is SM3 via the official auxfunc,
so no SHA3-extension instructions are built.
  ADKEX-128/  ADKEX-256/  ADKEX-512/      each: DKE core + protocol files (all flat at the instance root) + build.sh
Build on an arm64 host:
  bash build.sh                            (native gcc on AArch64 Linux / Apple Silicon clang)
Cross-build from x86-64:
  CC=aarch64-linux-gnu-gcc bash build.sh   then run kat_ADKEX-* under qemu-aarch64
Portability: the native assembly is dual-ABI (bare ELF symbols on AArch64 Linux, Mach-O
leading-underscore on Apple Silicon, via __APPLE__), so it builds on both from one source.
Verification status:
  * Apple Silicon (macOS, Mach-O) — VERIFIED end-to-end on real arm64 hardware: ADKEX-128/
    256/512 build with `bash build.sh` and produce KAT byte-identical to Test_Vectors
    (Apple M-series, macOS 15, Apple clang 17).
  * AArch64 Linux (ELF) — VERIFIED end-to-end on real arm64 hardware: ADKEX-128/256/512 build
    with `bash build.sh` and produce KAT byte-identical to Test_Vectors (Ubuntu 24.04, gcc
    13.3). The native asm is dual-dialect (N=512 NTT converted from Apple "dot" to canonical
    GNU-as syntax) and dual-ABI (by __APPLE__), so the same sources build with both Apple
    clang and GNU gcc.
Compliance: all hashing/XOF goes through the official auxfunc (parallel-SM3 noise removed;
DKE_HASH=0 / SM3).

Cortex-M4/     — ARM 32-bit embedded (STM32, Cortex-M4)
----------------------------------------------------------------
M4 path: the DKE ephemeral KEM core uses Plantard arithmetic + matacc (Cortex-M4 assembly by proposal-team
member Junhao Huang, ePrint 2022/956, Apache-2.0) for the NTT/polynomial core; the ADKEX 2-pass authenticated handshake runs the
fully derandomized API (explicit coins, no RNG). Hashing/XOF goes through the official auxfunc
(SM3 via auxfunc's portable C).
  ADKEX-128/  ADKEX-256/  ADKEX-512/   each: M4 DKE core (flat at root) + adkex_derand.c + qemu/ + build.sh
Compliance: drng.c/.h and auxfunc.c/.h are BYTE-IDENTICAL to the official API_PKC template;
since those use malloc()/free()/fprintf, the harness provides a tiny static-arena heap
(qemu/syscalls.c) so they run unmodified under -nostdlib. No code bypasses auxfunc.
Build and verify WITHOUT hardware:
  bash build.sh    — builds the ELF with arm-none-eabi-gcc and runs the 2-pass handshake
                     round-trip self-test on QEMU (-M netduinoplus2, semihosting), checking
                     that the initiator and responder shared secrets agree.
Requires arm-none-eabi-gcc and qemu-system-arm on PATH. For real hardware (STM32H750/F429)
use the ELF with the board's flash/run flow.
Verified PASS on QEMU Cortex-M4: 2-pass handshake self-test (shared secret matches) for
ADKEX-128/256/512 (official auxfunc SM3). Measured performance is reported in the
Algorithm Specification (Section 3.3.4 Performance Evaluation), not in this README.
