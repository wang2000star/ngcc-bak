# Neulaser Optimized Implementation

This directory contains optimized C99 implementations of the following
Neulaser hash-function instances:

- Neulaser-512
- Neulaser-768
- Neulaser-1024

The public `CryptHash()` API, KAT generator, and deterministic random-number
generator are compatible with the corresponding reference implementation.

## Directory Layout

Each algorithm directory contains:

- `CryptHash_AlgorithmInstance.c` -- optimized hash implementation
- `CryptHash_AlgorithmInstance.h` -- CryptHash API and instance parameters
- `KAT_CryptHash.c` -- known-answer-test generator
- `drng.c` and `drng.h` -- deterministic random-number generator
- `KAT_CryptHash.exe` -- compiled KAT generator
- `output/` -- generated test-vector files for that algorithm instance

The root `benchmark_hash.c` file is the performance-test program.

## Build Requirements

- A C99-compatible compiler
- MinGW-w64 GCC or an equivalent GCC toolchain
- GNU Make or `mingw32-make`
- An x86/x64 Windows environment for the supplied benchmark program

The optimized build uses the following compiler options:

```text
-std=c99 -O3 -march=native -flto -DNDEBUG -Wall -Wextra
```

`-march=native` generates instructions for the build machine. Remove this
option when a binary must run on older or different processors.

## Compilation

Open an MSYS2/MinGW terminal and change to this directory:

```sh
cd API_CryptHash/Implementations/Optimized_Implementation
```

Build all three instances:

```sh
mingw32-make all
```

With a toolchain that provides GNU Make under the name `make`, use:

```sh
make all
```

Remove the generated KAT executables with:

```sh
mingw32-make clean
```

## Generating Test Vectors

Run each KAT program from its own algorithm directory so that its output is
written to the corresponding `output` directory:

```sh
cd Neulaser-512
./KAT_CryptHash.exe
cd ../Neulaser-768
./KAT_CryptHash.exe
cd ../Neulaser-1024
./KAT_CryptHash.exe
```

Each `output` directory contains these four files, with the appropriate
algorithm-instance suffix:

```text
KAT_2_12_Neulaser-<instance>.txt
KAT_2_23_Neulaser-<instance>.txt
KAT_2_33_Neulaser-<instance>.txt
KAT_Loop_Neulaser-<instance>.txt
```

The `2^33`-bit test requires approximately 1 GiB of memory. Run the instances
sequentially if available memory is limited.

## Performance Benchmark

Compile the reference and optimized benchmark programs separately. The
following example is for Neulaser-512 and is run from this directory:

```sh
gcc -std=c99 -O2 -Wall -Wextra \
  -I../Reference_Implementation/Neulaser-512 \
  -o Neulaser-512/benchmark_reference.exe \
  benchmark_hash.c \
  ../Reference_Implementation/Neulaser-512/CryptHash_AlgorithmInstance.c

gcc -std=c99 -O3 -march=native -flto -DNDEBUG -Wall -Wextra \
  -INeulaser-512 \
  -o Neulaser-512/benchmark_optimized.exe \
  benchmark_hash.c \
  Neulaser-512/CryptHash_AlgorithmInstance.c
```

Run the benchmarks and save the CSV-formatted results:

```sh
./Neulaser-512/benchmark_reference.exe > reference-512.csv
./Neulaser-512/benchmark_optimized.exe > optimized-512.csv
```

Replace `Neulaser-512` with `Neulaser-768` or `Neulaser-1024` to test the
other instances. The benchmark covers message sizes from 32 bytes to 64 KiB
and reports cycles per hash, cycles per byte, latency, and throughput.

## Measured Performance

The implementations were measured on the development machine using 100
samples per message size. The reference implementation was compiled with
`-O2`; the optimized implementation was compiled with the optimized flags
shown above.

| Instance | Average speedup | Observed range | 64 KiB optimized throughput |
|---|---:|---:|---:|
| Neulaser-512 | 1.77x | 1.69x--1.87x | 49.18 MiB/s |
| Neulaser-768 | 1.81x | 1.66x--2.11x | 45.81 MiB/s |
| Neulaser-1024 | 1.62x | 1.48x--1.84x | 37.53 MiB/s |

Results depend on the processor, compiler version, background load, and power
management settings. For meaningful comparisons, build both versions with the
same compiler, pin the benchmark to the same CPU, and repeat the measurements.

## Main Optimizations

- Fast reduction modulo `p = 2^32 - 5` using the pseudo-Mersenne identity
  `2^32 = 5 (mod p)`, avoiding general 64-bit division.
- Independent per-module `F` computations arranged to expose instruction-level
  parallelism to the compiler.
- Fixed-size state shifts expressed as block copies to enable vectorized moves.
- Direct state loading from the IV and message block without a concatenation
  scratch buffer.
- Direct length-field stores for byte-aligned messages, while retaining the
  bit-accurate path for non-byte-aligned input.
- Whole-program optimization through `-O3`, native instruction selection, and
  link-time optimization.

The pseudo-Mersenne reduction is preferable to Montgomery multiplication in
this implementation because the modular arithmetic consists primarily of
fixed sparse-coefficient products rather than long chains of general modular
multiplications.

## Correctness

The optimized implementation was compared against the reference implementation
for all three instances. The test set included boundary lengths and arbitrary
non-byte-aligned messages. A total of 669 reference/optimized digest
comparisons passed, and the generated Neulaser-512 KAT files matched the
reference files byte for byte.
