# HARE self-evaluation code

`Self_Evaluation/` contains the test and benchmark source used by CMake targets.
It is the canonical location for self-evaluation code in this package.

## Functional tests

The CMake test suite covers:

```text
API and derived-size contracts
GF2X multiplication modulo X^n-1
concatenated-code roundtrip
RS correction at the 2g+h=n-k boundary
KR syndrome coverage, projection, and c[10:51] systematic coordinates
KEM roundtrip and invalid-ciphertext implicit rejection
```

Run locally:

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
ctest --test-dir build --output-on-failure
```

## KAT generation and replay

```bash
cmake --build build --target run_kat_all
cmake --build build --target verify_kat_all
cmake --build build --target verify_kat_optimized_all
```

`Test_Vectors/` contains the committed KAT files.  These files are generated and
replayed through the API_PKC-facing KEM interface.

## Benchmark harness

The benchmark source is:

```text
Self_Evaluation/benchmark/bench_kem_instance.c
Self_Evaluation/benchmark/measure_instance.sh
```

Example local smoke run:

```bash
HARE_BENCH_INSTANCES=1 HARE_BENCH_REPEATS=3 HARE_BENCH_WARMUP_REPEATS=1 \
  ./build/bench_HARE_256_kr_x86
```

Target-server procedures and result packaging are in `../SERVER_TEST.md`.  The
server runner uses the tests and benchmark binaries produced from this directory,
plus the reproducibility gates under `tools/`.

## Optional component profiling

The server runner can optionally invoke Linux `perf` through `tools/profiling/` and aggregate symbols into GF2X, vector/sampling, GF(2^8), Reed-Muller, Reed-Solomon, compression, and KEM/PKE/FO components. Enable it in `SERVER_TEST.md` with `RUN_COMPONENT_PROFILE=1`. This profiler is a measurement aid and is not part of the benchmark timing loop or KEM implementation.
