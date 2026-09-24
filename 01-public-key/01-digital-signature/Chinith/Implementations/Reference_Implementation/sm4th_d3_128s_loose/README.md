# sm4th-d3-128s-loose - Reference Implementation

Portable C reference implementation of **sm4th-d3-128s-loose**. This directory
intentionally contains no instruction-set acceleration sources, backend probes,
or acceleration build flags.

Protocol parameters: `lambda=128`, `lambda_f=128`, `lambda_iv=128`,
`ell=1808`, `tau=11`, `w_grind=7`, `T_open=102`, `B=16`, `d=3`.
The loose variant keeps SM4 as the PRG, uses a 128-bit IV, and its d3 leaf
PRG path emits 276 bytes.

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
├── prg.c / prg.h                          # Portable SM4 PRG interface
├── random_oracle.c / random_oracle.h      # RO / transcript hashing helpers
├── run_kat_sig.sh                         # KAT runner script
├── sig_impl.c / sig_impl.h                # Core sign/verify implementation
├── sig_impl_internal.h                    # Internal sig implementation types
├── sig_timing.c / sig_timing.h            # Optional sign/verify component timing
├── sm4_witness.c                          # Witness expansion for SM4
├── sm4th_d3_128s_loose.c / .h             # Public API wrapper
├── sm4th_d3_128s_loose_AlgorithmInstance.c / .h # Algorithm instance entry points
├── sm4th_d3_128s_loose_bench.c            # Benchmark entry
├── sm4th_sm4_128.c / sm4th_sm4_128.h      # SM4TH-specific SM4 wrapper
├── universal_hashing.c / .h               # VOLE universal hashing
├── utils.c / utils.h                      # Common utility helpers
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
make sm4th_d3_128s_loose_bench
```

Build settings:

| Setting | Default | Description |
|---------|---------|-------------|
| `NDEBUG` | `1` | `1`: release (`-O3` with LTO), `0`: keep base `-O2` flags |
| `SM4_SBOX_TABLE` | enabled | Fixed in `CFLAGS`; uses the portable SM4 S-box lookup table |

## Run

Benchmark:

```bash
./sm4th_d3_128s_loose_bench
./sm4th_d3_128s_loose_bench 100
./sm4th_d3_128s_loose_bench 100 8
```

`./sm4th_d3_128s_loose_bench` runs 100 fixed-56-byte sign/verify iterations by
default.
The signed message is the deterministic 56-byte ASCII string `Chinith sm4th ublockith vistrutith 56-byte bench msg v1.`.
The optional second argument is `MESSAGE_STEP`; it defaults to `0`, and `8`
runs increasing message lengths `56, 64, 72, ...`.

The bench prints wall-clock averages, the cycle-counter source, average Mcycles,
and per-iteration min/median/p90/max stats. The median is the typical iteration
time. The p90 value is the 90th percentile: 90% of iterations are no slower than
this value. On shared Hygon hosts, prefer the `per-iteration Mcyc/op stats`
median and p90 over the wall-clock average.

KAT:

```bash
bash run_kat_sig.sh
```

`run_kat_sig.sh` builds `KAT_SIG` with `NDEBUG=1`, runs it, and writes output to
`output/`.

From the repository root, compare Optimized/Reference/Test_Vector hashes with:

```bash
bash Chinith/check_kat_hash.sh --variant sm4th_d3_128s_loose
```
