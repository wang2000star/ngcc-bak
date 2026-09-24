# MAMBA-NIKE x86 Self-Evaluation Code

## Purpose

`ci/self_evaluation.py` is the executable companion to the code-aligned x86
self-evaluation report. It evaluates the two submitted implementation tracks:

- `API_PKC/Implementations/Reference_Implementation/`
- `API_PKC/Implementations/Optimized_Implementation/`

The program does **not** regenerate or normalize cryptographic parameters.
`parameters.json`, every submitted `params.h`, and all canonical KAT files are
hashed before the run and checked again at the end.

## Required dependencies

The conformance runner itself uses only the Python standard library.

| Dependency | Requirement | Used for |
|---|---|---|
| Python | 3.9 or newer | Test orchestration and reports |
| C compiler | GCC-compatible C99 compiler | Building Reference and Optimized code |
| GNU Make | Any current release | Profile KAT builds |
| Bash | Any current release | Repository support compatibility |
| Operating system | x86-64 Linux is the primary tested platform | Submitted x86 implementation scope |

No third-party cryptographic library is required. SHAKE, SHA3, ChaCha20, the
KAT deterministic random generator, and all NIKE arithmetic are provided by the
submission source tree.

## Optional dependencies and host features

| Dependency or feature | Used for | Behavior when unavailable |
|---|---|---|
| AVX2-capable x86-64 CPU and `-mavx2` compiler support | AVX2 KAT, API, differential, agreement, and benchmark checks | AVX2-only tests are reported as `SKIP`; portable tests still run |
| AddressSanitizer and UndefinedBehaviorSanitizer | Representative memory/undefined-behavior checks | Sanitizer test is reported as `SKIP` |
| NumPy | `compute_rejection.py` in full mode | Rejection-analysis test is reported as `SKIP` |

The lattice security-estimator record is checked against the committed summary.
The self-evaluation runner does not rerun the full Sage/lattice-estimator stack,
because that environment is substantially heavier than the implementation test
toolchain.

## Evaluation modes

### Quick smoke test

Runs static package checks and one-profile build/API smoke tests.

```bash
python3 ci/self_evaluation.py --mode quick
```

### Conformance test

Runs the main submission checks for all five profiles:

- dependency and package-layout validation;
- immutable parameter/header alignment;
- Reference/Optimized implementation-boundary checks;
- canonical KAT manifest verification;
- clean Reference, portable Optimized, and AVX2 builds;
- centered-binomial sampler tests;
- AVX2-vs-Toom polynomial differential, negacyclic-wrap, and alias tests;
- NGCC API normal and negative tests;
- fresh KAT runs compared byte-for-byte with canonical Reference vectors;
- final protected-file immutability verification.

```bash
python3 ci/self_evaluation.py --mode conformance
```

### Full self-evaluation

Adds the report-level long-running checks:

- representative ASan/UBSan builds;
- 5,000 deterministic complete exchanges per profile;
- paired 1,000-iteration Reference/AVX2 RDTSC benchmarks;
- the current double-precision rejection-analysis program.

```bash
python3 ci/self_evaluation.py --mode full \
  --agreement-trials 5000 \
  --json /tmp/mamba-self-evaluation.json \
  --markdown /tmp/mamba-self-evaluation.md
```

The default agreement track is `optimized-avx2` when AVX2 is available and
`reference` otherwise. It can be selected explicitly:

```bash
python3 ci/self_evaluation.py --mode full \
  --agreement-track reference \
  --agreement-trials 5000
```

## Selecting profiles

Use `--profile` once or multiple times. The option does not alter any parameter
file; it only limits which submitted directories are tested.

```bash
python3 ci/self_evaluation.py --mode conformance \
  --profile MAMBA-NIKE-128 \
  --profile MAMBA-NIKE-512
```

## Reports and exit status

The program prints progress to standard output. Optional JSON and Markdown files
are written only to paths explicitly supplied by the caller.

- Exit code `0`: every required test passed.
- Exit code `1`: at least one required test failed.
- Exit code `2`: setup or command-line error.

A `SKIP` result is reserved for optional host capabilities. It does not convert a
successful portable conformance run into a failure.

## Security and interpretation notes

- The Reference implementation must remain portable coefficient-domain C using
  `poly_convolution()` and `toom4_mul()`. The runner rejects AVX2 tokens or
  compiler flags in the Reference profile source trees.
- The Optimized implementation must retain the portable Toom-Cook fallback while
  confining `poly_mul_small()` and AVX2 ChaCha20 assembly to the Optimized track.
- Fresh Optimized KAT output must match the canonical Reference output
  byte-for-byte.
- Agreement testing is empirical evidence, not a mathematical proof of a zero
  rejection probability.
- The current rejection tool is expected to report `TBD(double_floor)` for all
  profiles. The runner does not convert that numerical floor into a finite
  cryptographic rejection bound.
- Benchmark values are host-specific. The benchmark test checks successful
  execution and zero observed agreement failures; it records new measurements
  rather than requiring a particular cycle count.
