# Galas x86 self-evaluation

This directory contains the helper scripts for the x86 self-evaluation of the
Galas signature implementations.

The benchmark policy follows the x86 evaluation guide:

- digital-signature tests use a deterministic 64-byte message;
- the reference implementation is built with the portable C99/O2 profile;
- the optimized implementation is built with the x86-64/AVX2/O3 release
  profile;
- each benchmark command defaults to 100 repetitions;
- key generation, signing, and verification are timed separately;
- each benchmark reports average latency, average cycle count, throughput,
  public-key size, secret-key size, signature size, and peak resident set size;
- static binary size is recorded with the system `size` tool;
- raw logs and CSV summaries are kept under this directory.

Run the reference implementation benchmark:

```bash
cd NGCC_Submit/Self_Evaluation
./run_reference_eval.sh
```

Run the optimized implementation benchmark:

```bash
cd NGCC_Submit/Self_Evaluation
./run_optimized_eval.sh
```

The default repetition count can be overridden:

```bash
REPS=10 ./run_optimized_eval.sh
```

The formal self-evaluation report should use `REPS >= 100`.  Smaller values
are useful only for smoke testing the benchmark harness.

Generated files:

- `environment.txt`: CPU, OS, compiler, and build-tool information;
- `results_reference.csv`, `results_optimized.csv`: timing, cycles,
  throughput, peak RSS, and data-size measurements;
- `static_size_reference.csv`, `static_size_optimized.csv`: text/data/bss
  binary-size measurements;
- `logs/`: raw command output.
