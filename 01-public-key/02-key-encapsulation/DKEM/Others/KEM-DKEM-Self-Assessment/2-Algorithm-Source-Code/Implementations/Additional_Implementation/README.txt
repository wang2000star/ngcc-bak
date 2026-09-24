Additional Implementations — DKEM
================================================================
Implementations on platforms other than the mainstream 64-bit PC (Section 3.4 encourages
these). The reference implementation is portable ISO C; the optimized implementation is
x86-64 AVX2. The additional implementations below are organized by platform.

AArch64_NEON/  — ARM 64-bit (AArch64), ARMv8.2-A
----------------------------------------------------------------
Fastest arm64 path: ARMv8.2-A assembly (adapted from the mlkem-native project, Apache-2.0 OR ISC OR MIT) for NTT / inverse-NTT / basemul /
reduce, with NEON-intrinsic polynomial code. Hashing is SM3 via the official
auxfunc, so no Keccak / SHA3-extension instructions are built.
  DKEM-128/  DKEM-256/  DKEM-512/      each: source + build.sh
Build on an arm64 host:
  bash build.sh                            (native gcc on AArch64 Linux, or clang on
                                            Apple Silicon)
Cross-build from x86-64:
  CC=aarch64-linux-gnu-gcc bash build.sh   then run kat_DKEM-* under qemu-aarch64
Portability: the native assembly is dual-ABI — bare ELF symbols on AArch64 Linux and
leading-underscore Mach-O symbols on Apple Silicon, selected by __APPLE__. It therefore
assembles and links on BOTH targets from the same sources.
Verification status:
  * Apple Silicon (macOS, Mach-O) — VERIFIED end-to-end on real arm64 hardware: all three
    instances (DKEM-128/256/512) build with `bash build.sh` and produce KAT byte-identical
    to Test_Vectors (Apple M-series, macOS 15, Apple clang 17).
  * AArch64 Linux (ELF) — VERIFIED end-to-end on real arm64 hardware: DKEM-128/256/512 build
    with `bash build.sh` and produce KAT byte-identical to Test_Vectors (Ubuntu 24.04, gcc
    13.3). The native asm is dual-dialect (the compiler-generated N=512 NTT was converted
    from Apple "dot" syntax to canonical GNU-as syntax, which clang also accepts) and dual-ABI
    (symbol decoration / GOT relocation by __APPLE__), so the same sources build with both
    Apple clang and GNU gcc.
Compliance: like the reference/optimized builds, all hashing/XOF goes through the official
auxfunc (the parallel-SM3 noise path is removed; DKE_HASH=0 / SM3).

Cortex-M4/     — ARM 32-bit embedded (STM32, Cortex-M4)
----------------------------------------------------------------
M4 path: Plantard arithmetic + matacc (fused matrix generate-and-multiply)
Cortex-M4 assembly for the NTT/polynomial core. The Plantard NTT assembly is by proposal-team
member Junhao Huang (ePrint 2022/956, Apache-2.0). The hashing/XOF
goes through the official
auxfunc (SM3), so the SM3 here is the auxfunc's portable C implementation (an SM3-assembly
variant would be faster on the hash, but auxfunc.c is kept byte-identical to the template).
  DKEM-128/  DKEM-256/  DKEM-512/      each: DKE source (flat at root) + qemu/ + build.sh
Compliance: drng.c/.h and auxfunc.c/.h are BYTE-IDENTICAL to the official API_PKC template
(unmodified). Because those template files use malloc()/free()/fprintf, the bare-metal
harness provides a tiny self-contained heap (qemu/syscalls.c: a static-arena malloc/free)
so they run unchanged under -nostdlib; no algorithm code bypasses auxfunc.
Build and verify WITHOUT hardware:
  bash build.sh    — builds the ELF with arm-none-eabi-gcc and runs a keygen/encaps/
                     decaps round-trip self-test on QEMU (-M netduinoplus2, semihosting).
Requires arm-none-eabi-gcc and qemu-system-arm on PATH. For real hardware
(STM32H750 / STM32F429) flash and run the ELF via the board's flow.
Verified PASS on QEMU Cortex-M4: keygen/encaps/decaps round-trip self-test for
DKEM-128/256/512 (official auxfunc SM3). Measured performance is reported in the
Algorithm Specification (Section 3.3.4 Performance Evaluation), not in this README.
