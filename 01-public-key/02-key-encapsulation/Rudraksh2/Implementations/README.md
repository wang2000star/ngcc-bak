# LWE-KEM / Rudraksh2

This repository contains the implementation of Module-Learning with Errors-based key encapsulation mechanism scheme, Rudraksh2:

- `lwekem128`
- `lwekem256`
- `lwekem512`

The project provides reference C implementations, AVX2-optimized implementations, and Cortex-M4 implementations of Rudraksh2.

## Repository layout

- `Reference_Implementation/`
  - Reference C implementations for `lwekem128`, `lwekem256`, and `lwekem512`
- `Optimized_Implementation/`
  - AVX2-optimized implementations for `lwekem128`, `lwekem256`, and `lwekem512`
- `Additional_Implementations/`
  - `Testing/` — shared test helpers and test drivers
  - `Cortex_M4/` — Cortex-M4 implementations for `lwekem128`, `lwekem256`, and `lwekem512` and a `README.md` file
  - `Security_and_DFR_Analysis/` — Decryption failure rate (DFR) analysis and security scripts and corresponding `README.md` files
- `Test_Vectors/`
  - Known-answer test vector files for `lwekem128`, `lwekem256`, and `lwekem512`
- `CMakeLists.txt`
  - Top-level build script
- `scripts`
  - Helper python scripts used in parameter calculation, and other small tasks.
- `flake.nix`/`flake.lock`
  - A Nix flake providing a development/testing environment with all the required tools.

## Usage

### Prerequisites

- CMake 3.2 or newer
- `gcc-13`
- `make`

#### Optional

We use the following tools to gather the memory usage information:

- binutils
- valgrind 
- awk

#### Nix flake (optional)

For convenience and portability, we provide a `flake.nix` which allows you to use the exact same versions
of the tools we used to develop and test this implementation. In order to use the flake you must have the
Nix package manager tool installed and enable flakes. This can be done by:

1. Installing the Nix package manager from [here](https://nixos.org/download/)
2. Enabling flakes in `~/.confix/nix/nix.conf` (for single-user) or `/etc/nix/nix.conf` (for multi-user).
```
experimental-features = nix-command flakes
```
3. Enter the development testing environment with `nix develop`

### Compilation

This project is built with cmake. The most basic way to compile the Reference release build is:

```
mkdir build
cd build
cmake -DAVX2_OPT=OFF -DCMAKE_BUILD_TYPE=Release ..
make
```

You can configure the compilation options (such as AVX2/Reference, Debug build)
either using command line options `-D<OPTION>=<VALUE>` or the more user-friendly
approach is using the ncurses interface provided by `ccmake` or even the QT gui
tool `cmake-gui`.

#### Examples

**Using terminal to compile AVX2:**
```
cd build
ccmake -DAVX2_OPT=ON -DCMAKE_BUILD_TYPE=Release ..
make
```

**Using ccmake to compile AVX2:**
```
cd build
ccmake ..
<... Use ncurses interface to configure options ...>
make
```

Refer to the `ccmake` help for further information, through these options you can further configure your compilation.

### Testing & Benchmarking

This library is equipped with extensive testing in
[Testing](Additional_Implementation/Testing). This is integrated with `cmake`
and can be [**after compiling**](#compilation) by running

```
make test
```

in the build directory. This will verify correct functionality of most aspects of the scheme and compare the generated KATs
against the provided test-vectors. 

For speed benchmarking there is a provided test case which measures the cycles and nanoseconds. Note that the nanosecond 
accuracy speed benchmark will require C23 to compile (compared to the rest of the codebase which is C99 compliant). For 
memory benchmarking see the [benchmarking readme](Additional_Implementation/Benchmarking/README.md).

#### Examples

**Benchmarking speed:**
```
./lwekem128-test_benchmark
```

**Generating KAT's:**
```
./lwekem128-genKat
```

**Verifying KAT's (using provided test):**
```
./lwekem128-test_kat ../Test_Vectors/KAT_KEM_lwekem128.txt
```


### Debugging

For debugging you can set the `CMAKE_BUILD_TYPE` to `Debug`. This will enable
the debugging symbols in the binaries and enable all available sanitizers. Most
are available for both `gcc` and `clang`. There is one sanitizer, the
unsigned-overflow checker which is only available for `clang`. So to choose the
compiler use the `CMAKE_C_COMPILER` option.

#### Examples

**Debugging the basic test:**
```
cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_C_COMPILER=clang ..
gdb ./lwekem128-test_basic
```
