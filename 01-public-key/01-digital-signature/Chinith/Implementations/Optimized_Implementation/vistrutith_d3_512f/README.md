# vistrutith-d3-512f — Optimized Implementation

Optimized implementation of **vistrutith-d3-512f** with x86 AES-NI acceleration for the
Vistrutah PRG path (single-core only, no OpenMP).

Key policy for this target:
- OWF is fixed to `vistrutah_512_encrypt` (see `owf.h`).
- PRG is fixed to `vistrutah_512_encrypt` counter mode (`seclvl=512`, see `prg.c`).
- This directory is self-contained and independent from `Reference_Implementation`.
- On x86, default build enables `PRG_ACCE=1` and uses AES-NI rounds.

## Directory Structure

```text
.
├── KAT_SIG.c                                      # KAT vector generator entry
├── Makefile                                       # Build rules (optimized defaults)
├── README.md                                      # This document
├── auxfunc.c / auxfunc.h                          # Portable hash helper interface
├── bavc.c / bavc.h                                # BAVC commit/reconstruct logic
├── compat.c / compat.h                            # Compatibility wrappers
├── drng.c / drng.h                                # Deterministic RNG for KAT/bench
├── endian_compat.h                                # Endian helpers/macros
├── fallbacks.h                                    # Platform fallback defines
├── fields.c / fields.h                            # GF arithmetic (bf512 and helpers)
├── macros.h                                       # Shared macros
├── owf.h                                          # OWF macro wrapper to vistrutah_512_encrypt
├── params.c / params.h                            # Parameter-set definitions
├── prg.c / prg.h                                  # Vistrutah-based PRG implementation
├── random_oracle.c / random_oracle.h              # Random-oracle / transcript hashing
├── run_kat_sig.sh                                 # KAT runner script
├── sig_impl.c / sig_impl.h / sig_impl_internal.h  # Shared sign/verify transcript logic
├── universal_hashing.c / .h                       # VOLE universal hashing
├── utils.c / utils.h                              # Common utility helpers
├── vole.c / vole.h                                # VOLE protocol logic
├── vistrutith_d3_512f.c / .h                      # Public API wrapper
├── vistrutith_d3_512f_AlgorithmInstance.c / .h    # Algorithm instance entry points
├── vistrutith_d3_512f_bench.c                     # Benchmark entry
├── vistrutith_d3_512f_test.c                      # Basic sign/verify self-test
└── utils_vistrutah/
    ├── vistrutah.h                                # Vistrutah constants + core declarations
    ├── vistrutah.c                                # Unified Vistrutah implementation (portable + x86 AES-NI fast path)
    ├── vistrutith_witness.c / .h                  # Extended witness generation
    ├── vistrutith_constraints.c / .h              # Enc constraints (prover/verifier)
    ├── vistrutith_vistrutah_512.c / .h            # QuickSilver wrapper for constraints
    └── sig_impl_vistrutith.c                      # vistrutith sign/verify backend hook
```

## Requirements

- GCC >= 7 or Clang >= 6
- GNU Make
- C11 runtime (`-lm`)

## Build

Default target:

```bash
make
```

Explicit targets:

```bash
make vistrutith_d3_512f_test
make vistrutith_d3_512f_bench
make KAT_SIG
```

Build options:

| Variable | Default | Description |
|----------|---------|-------------|
| `NDEBUG` | `1` | `1`: release (`-O3` + LTO), `0`: base flags |
| `PRG_ACCE` | `x86:1, non-x86:0` | Enable x86 AES-NI PRG acceleration |
| `USE_SBOX_TABLE` | `PRG_ACCE=1 -> 0, else 1` | Enable table-based portable S-box path |
| `SBOX` | follows `USE_SBOX_TABLE` | Compatibility alias |

## Run

Self-test:

```bash
./vistrutith_d3_512f_test
```

Benchmark:

```bash
./vistrutith_d3_512f_bench
./vistrutith_d3_512f_bench 100
./vistrutith_d3_512f_bench 100 8
```

Benchmark arguments:
- `ITERATIONS` defaults to `100`.
- `MESSAGE_STEP` is optional and gives the per-iteration message-length increment in bytes.
- If `MESSAGE_STEP` is omitted, Optimized signature benches use `0`, so every message remains fixed at 56 bytes.
- `MESSAGE_STEP=0` fixes every message at 56 bytes; `MESSAGE_STEP=8` uses 56, 64, 72, ... bytes.
- Benchmark messages are deterministic ASCII strings beginning with `Chinith sm4th ublockith vistrutith 56-byte bench msg v1.`.
- Thus `./vistrutith_d3_512f_bench` and `./vistrutith_d3_512f_bench 100` run 100 fixed-56-byte sign/verify iterations, while `./vistrutith_d3_512f_bench 100 8` forces the increasing-message run.

KAT:

```bash
bash run_kat_sig.sh
```

KAT output is written to `output/`.
