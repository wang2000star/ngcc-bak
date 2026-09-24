Additional Implementations — DKEX
================================================================
Implementations on platforms other than the mainstream 64-bit PC (Section 3.4 encourages
these). Reference = portable ISO C; optimized = x86-64 AVX2 (DKE core) + ML-DSA reference.

AArch64_NEON/  — ARM 64-bit (AArch64), ARMv8.2-A
----------------------------------------------------------------
Fastest arm64 DKE core: ARMv8.2-A assembly (adapted from the mlkem-native project, Apache-2.0 OR ISC OR MIT) for NTT / inverse-NTT / basemul /
reduce, with NEON polynomial code. Hashing is SM3 via the official auxfunc,
so no SHA3-extension instructions are built. The ML-DSA (Dilithium) signature component
is the NIST reference implementation.
  DKEX-128/  DKEX-256/  DKEX-512/      each: DKE core + protocol (flat at root) + dilithium/ + build.sh
Build on an arm64 host:
  bash build.sh                            (native gcc on AArch64 Linux / Apple Silicon clang)
Cross-build from x86-64:
  CC=aarch64-linux-gnu-gcc bash build.sh   then run kat_DKEX-* under qemu-aarch64
Portability: the native assembly is dual-ABI (bare ELF symbols on AArch64 Linux, Mach-O
leading-underscore on Apple Silicon, via __APPLE__), so it builds on both from one source.
Verification status:
  * Apple Silicon (macOS, Mach-O) — VERIFIED end-to-end on real arm64 hardware: DKEX-128/
    256/512 build with `bash build.sh` and produce KAT byte-identical to Test_Vectors
    (Apple M-series, macOS 15, Apple clang 17; ML-DSA = NIST reference, unchanged).
  * AArch64 Linux (ELF) — VERIFIED end-to-end on real arm64 hardware: DKEX-128/256/512 build
    with `bash build.sh` and produce KAT byte-identical to Test_Vectors (Ubuntu 24.04, gcc
    13.3; ML-DSA = NIST reference). The native asm is dual-dialect (N=512 NTT converted from
    Apple "dot" to canonical GNU-as syntax) and dual-ABI (by __APPLE__), so the same sources
    build with both Apple clang and GNU gcc.
Compliance: all DKE-core hashing/XOF goes through the official auxfunc (parallel-SM3 noise
removed; DKE_HASH=0 / SM3). the DKE core (flat at the instance root) and dilithium/ have colliding header basenames, so they
are compiled in separate -I groups and then linked.

Cortex-M4/     — ARM 32-bit embedded (Cortex-M4)
----------------------------------------------------------------
The DKE ephemeral KEM core uses Plantard arithmetic + matacc (Cortex-M4 assembly by proposal-team
member Junhao Huang, ePrint 2022/956, Apache-2.0); the ML-DSA signature is the NIST reference (portable C, deterministic signing) —
i.e. only the DKE core is M4-optimized, the signature is the unmodified reference. The DKEX
3-pass mutually-authenticated handshake runs the fully derandomized API (keygen randomness
injected via the sig hook; no live RNG).
  DKEX-128/  DKEX-256/  DKEX-512/   each: M4 DKE core (flat at root) + dilithium/ (ML-DSA reference)
                                          + protocol + qemu/ + build.sh
Compliance: DKE-core drng.c/.h and auxfunc.c/.h are BYTE-IDENTICAL to the official API_PKC
template; since those use malloc()/free()/fprintf, the harness provides a tiny static-arena
heap (qemu/syscalls.c) so they run unmodified under -nostdlib. No code bypasses auxfunc.
Build and verify WITHOUT hardware:
  bash build.sh    — builds the ELF with arm-none-eabi-gcc and runs the 3-pass handshake
                     self-test on QEMU (semihosting), checking BOTH signatures verify and the
                     shared secrets agree.
RAM note: DKEX-128 uses ML-DSA-44 and runs on -M netduinoplus2 (STM32F405, 128KB). DKEX-256
and DKEX-512 use ML-DSA-87, whose reference sign stack exceeds 128KB, so their QEMU self-test
targets -M mps2-an386 (Cortex-M4 with multi-MB RAM); on real hardware use a larger-RAM M4
such as STM32F429 (256KB) or STM32H750 (1MB). All require arm-none-eabi-gcc + qemu-system-arm.
Verified PASS on QEMU Cortex-M4: 3-pass mutually-authenticated handshake self-test
(both signatures verify and the shared secret matches) for DKEX-128/256/512 (official
auxfunc SM3). Measured performance is reported in the Algorithm Specification
(Section 3.3.4 Performance Evaluation), not in this README.
