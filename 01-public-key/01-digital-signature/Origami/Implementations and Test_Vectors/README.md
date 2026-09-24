# Origami -- Post-Quantum Multivariate Signature Scheme

Origami is a multivariate post-quantum signature scheme submitted to the
Next-generation Commercial Cryptographic Algorithms Program (NGCC).  This
repository contains the reference implementation, an optimized scalar
implementation, Known Answer Test (KAT) vectors, and a full experiment
benchmarking suite for communication / storage cost and CPU-cycle performance.

## Directory Layout

`
origami-v2/
|-- README.md
|-- Test_Vectors/
|   |-- KAT_SIG_Origami-128.txt
|   |-- KAT_SIG_Origami-256.txt
|   |-- KAT_SIG_Origami-384.txt
|   +-- KAT_SIG_Origami-512.txt
+-- Implementations/
    |-- Common/
    |   |-- bench_sig.c
    |   +-- comm_cost.c
    |-- Reference_Implementation/
    |   |-- Origami-128/   (aes, auxfunc, drng, KAT_SIG, Makefile, origami_*)
    |   |-- Origami-256/
    |   |-- Origami-384/
    |   +-- Origami-512/
    |-- Optimized_Implementation/
    |   |-- Origami-128/   (... same layout, uses origami_opt.c)
    |   |-- Origami-256/
    |   |-- Origami-384/
    |   +-- Origami-512/
    |-- build_all.sh
    |-- bench_all.sh
    |-- comm_cost_all.sh
    |-- perf_stats_all.sh
    |-- perf_ref_all.sh
    |-- perf_opt_all.sh
    |-- run_all_experiments.sh
    +-- update_makefiles.sh
`

## File Descriptions

### Core source code (per instance)

| File | Description |
|---|---|
|aes.c | AES-256 primitive for deterministic random number generation |
|auxfunc.c / .h | Auxiliary utility functions (byte conversion, hex printing) |
| drng.c / .h | Deterministic Random Number Generator (ICCS DRNG) |
| KAT_SIG.c | Known Answer Test driver -- generates deterministic test vectors |
| origami.h | Core Origami algorithm types, macros, and function declarations |
| origami_gf.h | Galois-field arithmetic over GF(q) |
| origami_params.h | Per-instance security parameters (dimensions, field size) |
| origami_ref.c | **Reference** implementation -- straight algorithmic workflow |
| origami_opt.c | **Optimized** scalar implementation (no AVX2 / SIMD) |
| SIG_AlgorithmInstance.h | Instance metadata and public API |
| SIG_AlgorithmInstance.c | NGCC-standard algorithm-instance wrapper |
| symmetric.h | Symmetric-primitive configuration |
| symmetric_iccs.c | ICCS symmetric-primitive glue |
| README.txt | Per-instance algorithm description (ICCS format) |
| Makefile | Build targets: kat, bench, run-bench, comm-cost, clean |

### Shared driver code

| File | Description |
|---|---|
| Common/bench_sig.c | Wall-clock benchmark driver. Runs keygen/sign/verify N iterations, prints per-operation average timing. |
| Common/comm_cost.c | Communication and storage cost measurement. Prints pk/sk/sig byte sizes, transmission payload, key-pair storage, transmission time at 100 Mbit/s and 1 Gbit/s. |

### Build and Benchmark Scripts

| File | Description |
|---|---|
|build_all.sh | Compile KAT + bench binaries for all 4 instances x 2 implementations |
|bench_all.sh | Full wall-clock benchmark across all instances, collect timing and key-size data |

### Communication and Storage Cost Experiment

| File | Description |
|---|---|
| comm_cost_all.sh | Run comm_cost for every instance, collate results into CommCost_Results/summary.csv |
| gen_comm_table.py | Read CSV and emit paper-ready LaTeX tables: tab:communication-storage-cost, tab:transmission-time-cost, tab:comm-cost-comparison |

### CPU-Cycle Performance Experiment

| File | Description |
|---|---|
| perf_stats_all.sh | Core performance script. Runs bench with BENCH_ITER=1 for per-operation timing. Computes mean/median/stddev. Mode: IMPL_MODE=all|ref|opt |
| perf_ref_all.sh | Thin wrapper -- run performance for Reference implementations only |
| perf_opt_all.sh | Thin wrapper -- run performance for Optimized implementations only |
| gen_perf_table.py | Read raw CSV data and emit paper-ready LaTeX tables: tab:origami_ref_perf, tab:origami_opt_perf, tab:origami_ratio |

### Orchestration and Utility

| File | Description |
|---|---|
| 
un_all_experiments.sh | Master script. Runs all experiments sequentially and generates all LaTeX tables. |
| update_makefiles.sh | Add comm-cost / run-comm-cost make targets to all 8 instance Makefiles |

### Other Assets

| Path | Description |
|---|---|
| Test_Vectors/KAT_SIG_Origami-*.txt | Deterministic KAT test vectors (seed, key pair, message, signature) |

## Quick Start
bash
cd Implementations
bash build_all.sh                  # Build everything
bash bench_all.sh                  # Wall-clock benchmarks
bash comm_cost_all.sh              # Comm/storage cost tables
python3 gen_comm_table.py
bash perf_stats_all.sh             # CPU-cycle performance (10-20 min)
python3 gen_perf_table.py
bash perf_ref_all.sh               # Reference only
bash perf_opt_all.sh               # Optimized only
bash run_all_experiments.sh        # One-shot: all experiments + tables


## Parameter Sets

| Instance | Security | PK | SK | Sig |
|---|---|---|---:|---:|---:|
| Origami-128 | 128-bit (NIST I) | 2,996 B | 16 B | 116 B |
| Origami-256 | 128/192-bit (NIST I) | 14,968 B | 32 B | 516 B |
| Origami-384 | 192/256-bit (NIST III) | 27,940 B | 48 B | 948 B |
| Origami-512 | 256-bit (NIST V) | 35,924 B | 64 B | 1,220 B |