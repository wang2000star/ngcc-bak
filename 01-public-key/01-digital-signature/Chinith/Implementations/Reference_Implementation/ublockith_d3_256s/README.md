# ublockith-d3-256s - Reference Implementation

Portable C reference implementation of **ublockith-d3-256s**. This directory
intentionally contains no instruction-set acceleration sources, backend probes,
or acceleration build flags. The PRG is the portable Ballet-256/256 core.

Protocol parameters: `lambda=256`, `ell=4608`, `tau=22`, `w_grind=6`,
`T_open=245`, `B=16`, `d=3`.

## Directory Structure

```
.
├── KAT_SIG.c                              # KAT vector generator entry
├── Makefile                               # Portable C build rules
├── README.md                              # This document
├── auxfunc.c / auxfunc.h                  # Hash helper interface
├── bavc.c / bavc.h                        # BAVC commit/reconstruct logic
├── bench_cycles.h                         # Cycle-counter and stats helpers
├── compat.c / compat.h                    # Compatibility wrappers
├── drng.c / drng.h                        # Deterministic RNG for KAT/bench
├── endian_compat.h                        # Endian helpers/macros
├── fallbacks.h                            # Platform fallback defines
├── fields.c / fields.h                    # Portable GF arithmetic
├── macros.h                               # Shared macros
├── owf.c / owf.h                          # One-way function helpers
├── params.c / params.h                    # Parameter-set definitions
├── prg.c / prg.h                          # Portable Ballet PRG interface
├── random_oracle.c / random_oracle.h      # RO / transcript hashing helpers
├── run_kat_sig.sh                         # KAT runner script
├── sig_impl.c / sig_impl.h                # Core sign/verify implementation
├── sig_impl_internal.h                    # Internal sig implementation types
├── ublockith_d3_256s.c / .h               # Public API wrapper
├── ublockith_d3_256s_AlgorithmInstance.c / .h # Algorithm instance entry points
├── ublockith_d3_256s_bench.c              # Benchmark entry
├── universal_hashing.c / .h               # VOLE universal hashing
├── utils.c / utils.h                      # Common utility helpers
├── utils_ballet/                          # Portable Ballet-256/256 components
├── utils_ublock/                          # Portable uBlock components and constraints
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
make ublockith_d3_256s_bench
```

Build settings:

| Setting | Default | Description |
|---------|---------|-------------|
| `NDEBUG` | `1` | `1`: release (`-O3`), `0`: keep base `-O2` flags |
| `USE_BALLET` / `HAVE_BALLET_CORE` | enabled | Fixed in `CFLAGS`; builds the portable Ballet-256/256 PRG core |

## Run

Benchmark:

```bash
./ublockith_d3_256s_bench
./ublockith_d3_256s_bench 100
./ublockith_d3_256s_bench 100 8
```

`./ublockith_d3_256s_bench` runs 100 fixed-56-byte sign/verify iterations by
default. The optional second argument is `MESSAGE_STEP`; it defaults to `0`,
and `8` runs increasing message lengths `56, 64, 72, ...`.

KAT:

```bash
bash run_kat_sig.sh
```

`run_kat_sig.sh` builds `KAT_SIG` with `NDEBUG=1`, runs it, and writes output to
`output/`.
