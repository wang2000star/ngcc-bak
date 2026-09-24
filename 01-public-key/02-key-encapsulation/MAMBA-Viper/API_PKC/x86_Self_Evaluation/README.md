# x86 API_PKC Self-Evaluation

This directory contains the one-command x86 self-evaluation harness for the final `API_PKC/` submission package. It is intentionally outside the individual instance directories so the official `API_PKC/Implementations/.../MAMBA-Viper-*` trees are not polluted with ad-hoc benchmark sources.

The performance benchmark targets the official API_PKC wrapper interface only:

- `kem_get_pk_len_bytes`
- `kem_get_sk_len_bytes`
- `kem_get_ss_len_bytes`
- `kem_get_ct_len_bytes`
- `kem_keygen`
- `kem_enc`
- `kem_dec`

It does **not** call the development `crypto_kem_keypair`, `crypto_kem_enc`, or `crypto_kem_dec` interfaces directly. The wrapper may call those lower-level functions internally, as in the final submission package.

## How to run

Quick smoke run:

```sh
bash x86_Self_Evaluation/run_api_pkc_self_eval.sh --runs 20 --warmup 5
```

Report-quality run:

```sh
bash x86_Self_Evaluation/run_api_pkc_self_eval.sh --runs 1000 --warmup 100
```

KAT/API/dependency/package checks without benchmarks:

```sh
bash x86_Self_Evaluation/run_api_pkc_self_eval.sh --no-bench
```

The script automatically finds the repository root, checks `API_PKC/`, records git state and host/toolchain information, runs Reference and Optimized KATs for all five parameter sets, compares generated KATs with official test vectors, compiles/runs API conformance tests, and runs the API-wrapper benchmark.

## Outputs

Each run creates a timestamped directory:

```text
x86_Self_Evaluation/results/YYYYmmdd-HHMMSS/
```

Important files include:

- `environment.txt`: date, `uname`, `lscpu`, compiler/build-tool versions, and CPU model/flags summary.
- `git_status.txt`: branch, HEAD commit, and `git status --short`.
- `build_kat_reference.log` and `build_kat_optimized.log`: `make clean`, `make`, and `make kat` logs.
- `kat_consistency.log`: official-vs-Reference and Reference-vs-Optimized KAT comparisons.
- `api_check.log`: official API wrapper conformance checks, including implicit rejection behavior for invalid ciphertexts.
- `benchmark_reference.log` and `benchmark_optimized.log`: raw benchmark output.
- `benchmark.csv`: machine-readable performance rows for `keygen`, `encaps`, and `decaps`.
- `sizes.csv`: public key, secret key, shared secret, and ciphertext sizes.
- `dependency_scan.log`: scan for forbidden random/system crypto dependencies.
- `artifact_scan.log`: scan for build artifacts left under `API_PKC/` or this harness outside `results/`.
- `summary.md`: PASS/FAIL summary.
- `latex_tables.tex`: copyable LaTeX fragments for the English x86 self-evaluation report.

Use `benchmark.csv` as the source of truth for performance tables. Copy the relevant `latex_tables.tex` fragments into the self-evaluation report; the generated snippets avoid raw underscore-heavy identifiers in normal LaTeX text where practical.

## AVX2 handling

The script checks CPU AVX2 support from `lscpu` or `/proc/cpuinfo`. Reference tests always run. If AVX2 is unavailable, Optimized KAT/API/benchmark steps are marked skipped so the Reference evidence can still be collected.

## Reproducibility and randomness

`benchmark_kem_api.c` initializes the official `drng_algorithm` through `init_random_number` from `drng.c/h`, matching the deterministic style used by official `KAT_KEM.c`. It does not use OpenSSL, `RAND_bytes`, `/dev/urandom`, `getrandom`, `arc4random`, or any other system RNG.
