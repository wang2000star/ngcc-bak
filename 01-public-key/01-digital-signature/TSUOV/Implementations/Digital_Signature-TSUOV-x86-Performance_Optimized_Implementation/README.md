# NGCC Digital-Signature Self-Assessment Framework

Algorithm-agnostic test framework for **digital signature** schemes on x86.
Place each parameter set under `API_PKC/Implementations/.../` using the folder
naming convention **`FAMILY_LEVEL`** (e.g. `TSUOV_128`, `TSUOV_256`). The family
prefix (`TSUOV`) is discovered automatically for reporting and CLI names
(`tsuov-128`).

## Layout

```
API_PKC/Implementations/
    Optimized_Implementation/   FAMILY_LEVEL/   (e.g. TSUOV_128/)
    Reference_Implementation/   FAMILY_LEVEL/
adapter/sig/                    Generic SIG_METHOD adapter
bench/                          Functional, performance, memory tests
src/                            Entry, options, JSON reporting
cmake/                          Folder discovery helpers
reports/                        JSON + CSV (generated)
```

## Build

```bash
mkdir build && cd build
cmake -DPKC_OPTIMIZED_IMPL=ON ..
cmake --build . --target ngcc_bench
```

Use `-DPKC_OPTIMIZED_IMPL=OFF` for Reference_Implementation.

CMake scans `*_<digits>` subfolders and builds one static library and one
benchmark binary per folder (`ngcc_bench_TSUOV_128`, `libsigalg_TSUOV_128.a`, …).

### KAT (optional, if `KAT_SIG.c` exists in the folder)

```bash
cmake --build . --target kat           # all folders
cmake --build . --target kat_TSUOV_128 # one folder
```

## Run

```bash
./ngcc_bench_TSUOV_128 -a tsuov-128 -t 1000 \
  -l API_PKC/Implementations/Optimized_Implementation/libsigalg_TSUOV_128.a \
  -o ../reports
```

| Flag | Meaning |
|------|---------|
| `-a` | `{family-lower}-{level}` or `{family-lower}_{level}` |
| `-t` | Performance iterations (default 1000, minimum 100) |
| `-l` | Static library path for memory measurement |
| `-o` | Output directory (default `reports`) |

### One-click self-assessment

```bash
./run_self_assessment.sh 1000              # optimized
./run_self_assessment.sh 1000 reference    # reference
```

Produces `reports/*.json`, `reports/summary.csv`, and `self_assessment_report.md`
(SM3 fixed in report; algorithm name read from folder / JSON).

## Integrating a new signature algorithm

1. Add folders `MYALG_128/`, `MYALG_256/`, … under Optimized and/or Reference.
2. Each folder must provide NGCC-style `SIG_AlgorithmInstance.{c,h}` with
   `ALGORITHM_INSTANCE` matching the folder name (e.g. `"MYALG_128"`).
3. Put all implementation `.c` files in the folder (`KAT_SIG.c` excluded from the library).
4. Re-run `cmake` — no edits to `CMakeLists.txt` per variant are required.
5. Optional: add `KAT_SIG.c` for known-answer test generation.

Compiler flags (applied automatically):

- Reference: `-std=c99 -Wpedantic -Wall -Wextra -O2`
- Optimized: `-O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra`

The harness runs functional, performance, memory, and size tests per NGCC section 3.
