# Hybrid Equivalent Punctured and Quasi-Cyclic (HEP-QC)

**This repository provides an implementation of HEP-QC, a code-based Key Encapsulation Mechanism (KEM) whose security is based on the hardness of solving the Quasi-Cylic Syndrome Decoding (QCSD) problem and Equivalent Punctured Code (EPC) problem.**

# Structure

+ **Implementations/** – HEP-QC implementations
  + **common/** – common source files shared by all implementations
  + **ref/** – reference implementation
  + **x86_64/** – optimized implementation
+ **Lib/** – provided libraries (e.g. **auxfunc, drng**)
+ **Tests/** – test-suite root (built with CMake)
  + **unit/** – unit tests (GF, Reed–Solomon, …)
  + **api/** – KEM/PKE API tests
  + **bench/** – benchmarks
  + **kats/** – KAT files tests
  + **external/munit/** – copy of the *munit* testing framework
+ **Test_Vectors/** – Known-Answer Test (KAT) files
  + **ref/** – files generated with the reference build
  + **x86_64/** – files generated with the optimized build
+ **CMakeLists.txt** – top-level CMake build script (sub-directories have their own)
+ **README.md** – this file

# Prerequisites

- **CMake** ≥ 3.21
- **A C compiler** (GCC ≥ 11, Clang, etc.) with C11 support
- **Ninja** or **Make** (or another CMake generator)
- **clang-format** for code formatting

# Building & Testing

You can build any variant in an out-of-tree directory and run the full test-suite
with a single command line.  Choose the architecture (`HEP_QC_ARCH`).

```bash
# 1) Configure
cmake -S . -B build-<arch> \
      -DCMAKE_BUILD_TYPE=Release \
      -DHEP_QC_ARCH=<arch>

# 2) Build
cmake --build build-<arch> -- -j$(nproc)

# 3) Test
ctest --test-dir build-<arch> --output-on-failure -j$(nproc)
```

**Configuration Options**

- **`<arch>`**: `ref`, `x86_64`

**Example 1 (Reference implementation)**
```bash
rm -rf build-ref &&
cmake -S . -B build-ref \
-DCMAKE_BUILD_TYPE=Release \
-DHEP_QC_ARCH=ref &&
cmake --build build-ref -j$(nproc) &&
ctest  --test-dir build-ref -j$(nproc)
```
**Example 2 (Optimized implementation)**
```bash
rm -rf build-x86-64 &&
cmake -S . -B build-x86-64 \
-DCMAKE_BUILD_TYPE=Release \
-DHEP_QC_ARCH=x86_64  &&
cmake --build build-x86-64 -j$(nproc) &&
ctest  --test-dir build-x86-64 -j$(nproc)
```
