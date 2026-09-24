# sm4th-em-d2-128s-tight - Reference Implementation

Portable C reference implementation of **sm4th-em-d2-128s-tight**. This
directory intentionally contains no instruction-set acceleration sources,
backend probes, or acceleration build flags. The tight variant uses SM4 for the
OWF and the portable Ballet-256/256 core as the PRG.

Protocol parameters: `lambda=128`, `lambda_f=160`, `lambda_iv=256`,
`lambda_prg=256`, `ell=1024`, `tau=14`, `w_grind=7`, `T_open=132`, `B=16`,
`d=2`, and `ell_hat=1360` bits (`170` bytes).

## Directory Structure

```
.
├── KAT_SIG.c                              # KAT vector generator entry
├── Makefile                               # Portable C build rules
├── README.md                              # This document
├── auxfunc.c / auxfunc.h                  # SM3 helper interface
├── bavc.c / bavc.h                        # BAVC commit/reconstruct
├── bench_cycles.h                         # Cycle-counter and stats helpers
├── compat.c / compat.h                    # Compatibility wrappers
├── drng.c / drng.h                        # Deterministic RNG used by KAT/bench
├── endian_compat.h                        # Endian helpers/macros
├── fallbacks.h                            # Feature fallback defines
├── fields.c / fields.h                    # Portable GF arithmetic
├── macros.h                               # Shared macros
├── owf.c / owf.h                          # One-way function helpers
├── params.c / params.h                    # Parameter set definitions
├── prg.c / prg.h                          # Portable Ballet PRG interface
├── random_oracle.c / random_oracle.h      # RO / transcript hashing helpers
├── run_kat_sig.sh                         # KAT runner script
├── sig_impl.c / sig_impl.h                # Core sign/verify implementation
├── sig_impl_internal.h                    # Internal sig implementation types
├── sm4_witness.c                          # Witness expansion for SM4
├── sm4th_em_d2_128s_tight.c / .h          # Public API wrapper
├── sm4th_em_d2_128s_tight_AlgorithmInstance.c / .h # Algorithm instance entry points
├── sm4th_em_d2_128s_tight_bench.c         # Benchmark entry
├── sm4th_sm4_128.c / sm4th_sm4_128.h      # SM4TH-specific SM4 wrapper
├── universal_hashing.c / .h               # VOLE universal hashing
├── utils.c / utils.h                      # Common utility helpers
├── utils_ballet/                          # Portable Ballet-256/256 components
├── utils_sm4/                             # Portable SM4 components
├── vole.c / vole.h                        # VOLE protocol logic
└── output/                                # Generated KAT output
```

## Requirements

- GCC >= 7
- GNU Make
- C11 runtime (`-lm`)

## Build

Default build is release:

```bash
make sm4th_em_d2_128s_tight_bench
```

Build settings:

| Setting | Default | Description |
|---------|---------|-------------|
| `NDEBUG` | `1` | `1`: release (`-O3` with LTO), `0`: keep base `-O2` flags |
| `SM4_SBOX_TABLE` | enabled | Fixed in `CFLAGS`; uses the portable SM4 S-box lookup table |
| `USE_BALLET` / `HAVE_BALLET_CORE` | enabled | Fixed in `CFLAGS`; builds the portable Ballet-256/256 PRG core |

## Run

Benchmark:

```bash
./sm4th_em_d2_128s_tight_bench
./sm4th_em_d2_128s_tight_bench 100
./sm4th_em_d2_128s_tight_bench 100 8
```

`./sm4th_em_d2_128s_tight_bench` runs 100 fixed-56-byte sign/verify iterations
by default. The optional second argument is `MESSAGE_STEP`; it defaults to `0`,
and `8` runs increasing message lengths `56, 64, 72, ...`.

KAT:

```bash
bash run_kat_sig.sh
```

`run_kat_sig.sh` builds `KAT_SIG` with `NDEBUG=1`, runs it, and writes output to
`output/`.
