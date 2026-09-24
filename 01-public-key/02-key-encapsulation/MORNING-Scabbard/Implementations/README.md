# LWR-KEM / Scabbard

This repository contains the implementations of Module-learning with rounding-based key encapsulation mechanism scheme, Scabbard:

- `scabbard128`
- `scabbard256`
- `scabbard512`

The project provides reference C implementations, AVX2-optimized implementations, and Cortex-M4 implementations of Scabbard.

## Repository layout

- `Reference_Implementation/`
  - Reference C implementations for `scabbard128`, `scabbard256`, and `scabbard512`
- `Optimized_Implementation/`
  - AVX2-optimized implementations for `scabbard128`, `scabbard256`, and `scabbard512`
- `Additional_Implementations/`
  - `Testing/` — shared test helpers and test drivers
  - `Cortex_M4/` — Cortex-M4 implementations for `scabbard128`, `scabbard256`, and `scabbard512` under the `scabbard` folder and a `README.md` file
  - `Security_and_DFR_Analysis/` — Decryption failure rate (DFR) analysis and security scripts and corresponding `README.md` files
- `Test_Vectors/`
  - Known-answer test vector files for `scabbard128`, `scabbard256`, and `scabbard512`
- `CMakeLists.txt`
  - Top-level build script  

## Prerequisites

- CMake 4.3 or newer
- `gcc-13` (or another supported C compiler)
- `make`

## Build instructions

From the repository root:

```bash
mkdir build
cd build
cmake ..
make
```

This creates the executables for each implementation and test target.

## Build modes

The top-level `CMakeLists.txt` controls whether the AVX2-optimized implementation is built. The project default in line 17 of `CMakeLists.txt` is:

```cmake
option(AVX2_OPT "Build the AVX2 optimised implementation instead of the Reference" OFF)
```

### Reference implementation (Deafult)
You do not need to edit `CMakeLists.txt` for the reference implementation. However, if an edit was made previously in `CMakeLists.txt`, please make sure to turn off the AVX2_OPT flag (set to "OFF") in `CMakeLists.txt` (on line 17) with the following line. 

```cmake
option(AVX2_OPT "Build the AVX2 optimised implementation instead of the Reference" OFF)
```

Then run the following commands from the repository root:

```bash
mkdir build
cd build
cmake ..
make
```

### AVX2 optimized implementation
To run the AVX2 optimized implementation, you need to edit the `CMakeLists.txt` file. Please make sure `CMakeLists.txt` enables (set at "ON") the AVX2_OPT flag (on line 17) with the following line. 

```cmake
option(AVX2_OPT "Build the AVX2 optimised implementation instead of the Reference" ON)
```

Then run the following commands from the repository root:

```bash
mkdir build
cd build
cmake ..
make
```

## KAT generations

To generate the known-answer test (KAT) vectors for different instances of Scabbard, execute the following files from the `build` folder.

```bash
./scabbard128-genKat
./scabbard256-genKat
./scabbard512-genKat
```

## Test Speed 

To test the speed of the different instances of Scabbard, execute the following files from the `build` folder.

```bash
./scabbard128-test_speed
./scabbard256-test_speed
./scabbard512-test_speed
```

## Detailed Benchmark 

For a detailed benchmark of the speed of the different instances of Scabbard, execute the following files from the `build` folder.

```bash
./scabbard128-test_benchmark
./scabbard256-test_benchmark
./scabbard512-test_benchmark
```

## Tests

CTest is enabled in the build system. After building, run the following from the `build` folder:

```bash
make test
```
This runs the tests for all supported reference/optimized AVX2 implementations.


## Notes

- The generated executables are named like `scabbard128-genKat`, `scabbard128-test_speed`, `scabbard128-test_benchmark`
- For Cortex-M4 support, check the `README.md` file under `Additional_Implementations/Cortex_M4/`.

