# Script entry points

Run scripts from the repository root. The daily supported entry points are only:

```sh
scripts/test_all.sh
ROUNDS=1000 scripts/bench_all.sh
scripts/clean.sh
```

## Main correctness entry point

### `scripts/test_all.sh`

Complete correctness test for the supported Viper backends. It stops on the first error and does not generate formal KAT files or tracked output.

Coverage:

* Reference current, levels 128/192/256: PKE/KEM correctness, pack/unpack, quantize/reconstruct execution, dither determinism, and FO re-encryption consistency through `test/viper_validation`.
* AVX2 current, levels 128/192/256: the same validation plus `test/viper_arith_compare` for arithmetic agreement.
* Reference current vs AVX2 current fixed-seed dumps, levels 128/192/256: byte-for-byte equality of the deterministic pk/sk/ct/ss_enc/ss_dec dump.
* AVX2 TCHES2021 NTT all, levels 128/192/256: explicit `VIPER_EXPERIMENTAL_TCHES2021_NTT=1` builds, PKE/KEM correctness, NTT arithmetic validation, selected poly/matvec/matTvec/dot validation, and compile-time self-report checks that the route did not silently fall back to current AVX2.

## Main benchmark entry point

### `scripts/bench_all.sh`

Complete Viper performance test for the three main benchmark backends only:

1. `Ref current`
2. `AVX2 current`
3. `AVX2 TCHES2021 NTT all`

`ROUNDS` defaults to `1000` and can be overridden, e.g. `ROUNDS=2000 scripts/bench_all.sh`. The benchmark uses at least 16 warm-up iterations, reports median cycles, prints markdown tables to stdout, and stores only temporary files under `mktemp` directories that are removed automatically.

Before benchmarking, the script performs smoke correctness checks for Reference current, AVX2 current, and AVX2 TCHES2021 NTT all. It does not display HYBRID_ALL, HYBRID_L3L5, fused GenPublic-matvec experiments, or legacy raw NTT experiments.

Output tables:

1. `Table 1: Viper KEM full-flow performance`
2. `Table 2: Viper PKE performance`
3. `Table 3: Viper arithmetic microbench`
4. `Table 4: AVX2 TCHES2021 NTT all speedup over AVX2 current`

## Clean entry point

### `scripts/clean.sh`

Removes local build products and temporary generated files. This script may remove generated KAT-style files if they were produced manually outside the supported workflow; the supported workflow itself does not generate formal KAT files.

## Archive

`scripts/archive/` contains superseded and exploratory scripts kept for traceability only. Archive scripts are not daily entry points and are not guaranteed to stay maintained. Use `scripts/test_all.sh` and `scripts/bench_all.sh` for supported validation and benchmarking.

Hybrid TCHES2021 modes (`VIPER_EXPERIMENTAL_TCHES2021_HYBRID=1` and `VIPER_EXPERIMENTAL_TCHES2021_HYBRID_L3L5=1`) remain exploratory-only implementation options. They are not shown by `bench_all.sh` and are not recommended as mainline benchmark rows.

## Defaults and non-goals

* The default backend remains the current Toom-Cook/Karatsuba polynomial-multiplication path.
* `AVX2 TCHES2021 NTT all` is opt-in experimental and is enabled only with `VIPER_EXPERIMENTAL_TCHES2021_NTT=1`.
* Scripts do not modify Viper parameters, PKE/KEM/FO semantics, public dithered quantization, external pk/ct/sk byte layout, GenPublic, GenDither, or sampling mappings.
* Scripts do not connect API_PKC and do not generate formal KAT files.
* Benchmark output and build artifacts must not be committed.
