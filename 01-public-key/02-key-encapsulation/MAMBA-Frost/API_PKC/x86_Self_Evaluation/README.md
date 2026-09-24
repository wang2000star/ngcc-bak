# API_PKC x86 self-evaluation harness

This directory contains the local x86 self-evaluation harness for the single
`API_PKC/` submission package.  The package contains both MAMBA-Frost and
MAMBA-Frost-CC KEM family/variant instances.

## Directory structure

```text
x86_Self_Evaluation/
  README.md
  run_api_pkc_self_eval.sh   # one-command entry point
  collect_environment.sh     # environment/git/layout capture
  benchmark_kem_api.c        # API_PKC wrapper-level benchmark driver
  parse_results.py           # CSV summarizer and summary.md generator
  results/                   # timestamped result directories
```

All generated data is written to `x86_Self_Evaluation/results/<timestamp>/`.
Temporary benchmark binaries are built below that result directory, not inside
`API_PKC/`.

## Commands

Quick debug run covering all ten instances:

```sh
bash x86_Self_Evaluation/run_api_pkc_self_eval.sh --runs 100 --warmup 20 --quick
```

Formal run without full 1000-round correctness checks:

```sh
bash x86_Self_Evaluation/run_api_pkc_self_eval.sh --runs 1000 --warmup 100
```

Formal run including full `make check` and `make optimized-check`:

```sh
bash x86_Self_Evaluation/run_api_pkc_self_eval.sh --runs 1000 --warmup 100 --full-check
```

`--full-check` can be slow for the 384/512-bit parameter sets.  Optimized tests
require an x86/x86_64 CPU with AVX2 and AES-NI; if either feature is missing,
optimized runtime tests are recorded as skipped rather than PASS.

## Output files

Each result directory contains environment and package-layout captures,
Reference/Optimized build and KAT logs, dependency scans, artifact scans, and:

* `benchmark.csv` — per-operation cycles and wall-clock throughput for
  `kem_keygen`, `kem_enc`, and `kem_dec` through the official API_PKC wrapper.
* `throughput.csv` — compact operation throughput table.
* `sizes.csv` — pk/sk/ct/ss byte sizes for every implementation/instance.
* `resources.csv` — binary section sizes and peak RSS where available; missing
  measurements are recorded as `NA`.
* `summary.md` — human-readable summary with status, size, benchmark, speedup,
  and resource tables.

The CSV and `summary.md` tables can be copied into the final LaTeX x86
self-evaluation report.  Machine-specific fields such as CPU model, OS, compiler
version, benchmark medians, speedups, and resource data should be filled from the
result directory produced on the target evaluation machine.
