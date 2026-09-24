# BAG-Piglet Implementations

This directory contains the BAG-Piglet reference and optimized implementation
layouts. Each layout is divided into four independent security-strength
instances:

```text
Reference_Implementation/
|-- bag_piglet128/
|-- bag_piglet256/
|-- bag_piglet384/
`-- bag_piglet512/

Optimized_Implementation/
|-- bag_piglet128/
|-- bag_piglet256/
|-- bag_piglet384/
`-- bag_piglet512/
```

Every instance contains its own parameters, scheme sources, FFI, RBC sources,
official KAT adapter, and build files. It does not depend on source files from
another security-strength directory.

The reference and optimized directories currently contain the same reviewed
C11 code baseline. They remain separate so that optimized implementations can
be developed independently without changing the expected submission layout.

## Instance Layout

```text
bag_pigletXXX/
|-- CMakeLists.txt
|-- Makefile
|-- README
|-- doxygen.conf
|-- doc/
|-- lib/
|   |-- api_pkc/
|   `-- randombytes/
`-- src/
    |-- common/
    |-- ffi/
    |-- kat/
    |-- rbc/
    `-- scheme/
```

The main modules are:

- `src/common/`: CCA-KEM, PKE, Gabidulin, linearized-polynomial, parsing, and
  shared utility code.
- `src/scheme/`: the BAG-Piglet core implementation and parameters for the
  current security strength.
- `src/ffi/`: the pure-C finite-field interface used by the upper scheme code.
- `src/rbc/`: bundled RBC field, vector, space, polynomial, and quotient-ring
  arithmetic.
- `src/kat/`: the official KAT generator and BAG-Piglet interface adapter.
- `lib/api_pkc/`: official auxiliary functions and deterministic random-number
  generation.
- `lib/randombytes/`: the system random-byte interface used during ordinary,
  non-KAT execution.

## Formal Build

Enter an instance directory and run:

```sh
make
```

The default target builds only the official KAT. For example:

```sh
cd Reference_Implementation/bag_piglet128
make
./build/bin/bag_piglet128-kat
```

The equivalent direct CMake build, with local development tests explicitly
disabled, is:

```sh
cmake -S . -B build -DBAG_PIGLET_BUILD_LOCAL_TESTS=OFF
cmake --build build --target bag_piglet128-kat -j
./build/bin/bag_piglet128-kat
```

The KAT executable writes its result under `output/` in the current instance
directory. The four output names are:

- `KAT_KEM_bag_piglet_128.txt`
- `KAT_KEM_bag_piglet_256.txt`
- `KAT_KEM_bag_piglet_384.txt`
- `KAT_KEM_bag_piglet_512.txt`

The repository's top-level `Test_Vectors/` directory contains the expected
results for byte-for-byte comparison.

## Official KAT Boundary

The formal repository retains only the following test source path:

```text
src/kat/KAT_KEM.c
src/kat/KEM_AlgorithmInstance.c
src/kat/KEM_AlgorithmInstance.h
```

`KAT_KEM.c`, `lib/api_pkc/auxfunc.*`, and `lib/api_pkc/drng.*` are fixed
official files and must not be modified. The BAG-Piglet algorithm name,
lengths, and `ccakem_*` calls are connected only through
`KEM_AlgorithmInstance.c/.h`.

Local functional tests, benchmarks, and the legacy KAT entry point are not
uploaded to the remote repository, but they remain in the developer's local
working directory:

```text
src/main_bag_piglet.c
src/main_benchmark.c
src/main_kat.c
src/common/kem_bag_piglet.c
src/common/kem_bag_piglet.h
```

When these files exist locally, their build targets are:

```sh
make functional
make benchmark
```

## Encoding Sizes

| Instance | Public key | Secret key | PKE ciphertext | KEM ciphertext | Shared secret |
| --- | ---: | ---: | ---: | ---: | ---: |
| 128 | 522 | 16 | 1011 | 1027 | 16 |
| 256 | 1573 | 32 | 3081 | 3097 | 32 |
| 384 | 2778 | 48 | 5459 | 5475 | 48 |
| 512 | 4158 | 64 | 8188 | 8204 | 64 |

The KEM ciphertext size includes the compact PKE ciphertext and a 16-byte
salt.

## Build Dependencies

- CMake 3.15 or newer
- GCC or Clang with C11 support
- pthread

NTL is no longer used. RBC is included with each instance, and the build does
not require OpenSSL.
