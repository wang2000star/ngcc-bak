# Wish — Implementations

In this repo, we provide the implmentations of the Wish hash family, including 512-bit version **Wish512** and 1024-bit version **Wish1024**.
Three implementations of the Wish hash family are provided as follows:

| Implementation              | Optimized for            | Architecture-specific? |
|-----------------------------|--------------------------|------------------------|
| `Reference_Implementation`  | Clarity / portability    | No — plain C99         |
| `Optimized_Implementation`  | Software performance     | Yes — per ISA          |
| `Additional_Implementation` | Memory performance       | Yes — per ISA          |

## How the three differ

- **Reference** is portable C99. It does **not** depend on the target
  architecture and uses no hardware-acceleration intrinsics — the same code
  compiles and runs anywhere a C99 compiler is available. It is intended as a readable
  specification of the algorithm and the source of the Known-Answer Tests.

- **Optimized** is the **speed-optimized** variant. It is split into one build
  tree per target ISA (x86-64 and AArch64) and uses hardware AES support. The
  vector extensions (AVX2 on x86, SVE on ARM) are conditional. Build each tree on a host of the
  matching architecture.

- **Additional** is a **memory-optimized** version of the optimized
  code: the same per-ISA structure, but the core (`wish.c`) is reworked to keep a
  smaller working-set / code footprint, and both builds are compiled for size
  (`-Os`) rather than for speed.

## Directory layout

### `Reference_Implementation/` — architecture-independent

```
Reference_Implementation/
├── Wish512_reference/
└── Wish1024_reference/
```

One folder per instance. No ISA suffix because the code is the same everywhere.

### `Optimized_Implementation/` and `Additional_Implementation/` — per architecture

```
Optimized_Implementation/
├── Wish512_x86_performance_optimized/    Wish512,  x86-64
├── Wish1024_x86_performance_optimized/   Wish1024, x86-64
├── Wish512_arm_performance_optimized/    Wish512,  AArch64
└── Wish1024_arm_performance_optimized/   Wish1024, AArch64

Additional_Implementation/
├── Wish512_x86_resource_optimized/       Wish512,  x86-64
├── Wish1024_x86_resource_optimized/      Wish1024, x86-64
├── Wish512_arm_resource_optimized/       Wish512,  AArch64
└── Wish1024_arm_resource_optimized/      Wish1024, AArch64
```

The `*_x86_*` trees must be built on an x86-64 host and the `*_arm_*` trees on an
AArch64 host — the build flags are ISA-specific and will not cross-compile
without a matching toolchain.

## Source files

Every tree (in all three implementations) shares the same layout:

- `KAT_CryptHash.c` — Known-Answer-Test driver. When run it creates an `output/`
  directory and writes the generated `.txt` KAT vectors into it. That `output/`
  directory is a runtime artifact; it is not shipped with the sources.
- `drng.c`, `CryptHash_AlgorithmInstance.c`, `wish.c` — the core implementation.
  In the Optimized and Additional Makefiles these three files are the `CORE`
  sources; the Reference Makefile compiles all four files together as `SRC`.

## Make targets

Run `make` from inside the directory you want to build. Every tree exposes the
same four targets; `kat` is the default, so a bare `make` builds the KAT
executable.

| Target         | Reference | Optimized | Additional | What it does                                               |
|----------------|:---------:|:---------:|:----------:|------------------------------------------------------------|
| `make kat`     |     ✓     |     ✓     |     ✓      | Build the KAT executable `KAT_CryptHash` (default target). |
| `make run-kat` |     ✓     |     ✓     |     ✓      | Build (if needed) and run `KAT_CryptHash`.                 |
| `make bench`   |     —     |     ✓     |     ✓      | Build the shared libraries (`.so`) used for benchmarking.  |
| `make clean`   |     ✓     |     ✓     |     ✓      | Remove the `KAT_CryptHash` executable and any compiled `.so` libraries (the generated `output/` KAT files are not removed). |

> Reference has no `bench` target — it builds no `.so` benchmark libraries.

### `make bench` outputs

`bench` compiles the core sources into position-independent shared libraries
(`-shared -fPIC`) so they can be loaded by an external benchmark harness.

**Optimized** — one `.so` per ISA variant:

| Tree            | Outputs |
|-----------------|---------|
| `*_x86_*`       | `<Instance>_x86_aes.so`, `<Instance>_x86_aes_avx2.so` (`-mavx2` adds AVX2 support) |
| `*_arm_*`       | `<Instance>_arm_aes.so`, `<Instance>_arm_aes_sve.so` (`+sve` adds SVE support) |

**Additional** — a single memory-optimized `.so`:

| Tree            | Output |
|-----------------|--------|
| `*_x86_*`       | `<Instance>_x86_aes_mem.so` |
| `*_arm_*`       | `<Instance>_arm_aes_mem.so` |

> **Note on ARM SVE:** the `make bench` target for the Optimized ARM trees also
> emits `<Instance>_arm_aes_sve.so` (built with `+sve`), but we have **not**
> benchmarked the SVE variant on ARM because we have no SVE-capable hardware
> available to run the tests. Consequently no `*_arm_aes_sve.so` library is
> shipped under `Self_Assessment/Data/arm/` and it is not exercised by
> `testwish.sh`; only
> the `aes` and `aes_mem` ARM variants have measured results.

## Compiler flags

`CC` defaults to `gcc` in every tree. Override it on the command line if needed,
e.g. `make CC=clang bench`.

### Reference

| Flag | Purpose |
|------|---------|
| `-O2` | Moderate optimization. |
| `-std=c99` | Compile as C99. |
| `-Wpedantic -Wall -Wextra` | Strict warnings. |

No architecture (`-march`) or hardware-feature flags — the reference build is
fully portable.

### Optimized & Additional — common flags

| Flag | Purpose |
|------|---------|
| `-O3` | Maximum speed optimization (Optimized). |
| `-Os` | Optimize for size (Additional — the memory-optimized build). |
| `-flto` | Link-time optimization across translation units. |
| `-fomit-frame-pointer` | Free the frame-pointer register for general use. |
| `-mtune=native` | Tune scheduling for the build machine's CPU (Optimized x86 only). |
| `-std=c99` | Compile as C99. |
| `-Wpedantic -Wall -Wextra` | Strict warnings. |
| `-shared -fPIC` | (`bench` only) emit a position-independent shared library. |

### x86 architecture flags

| Flag | Purpose | Used by |
|------|---------|---------|
| `-march=x86-64` | Target the generic x86-64 baseline (portable across x86-64 CPUs). | Optimized, Additional |
| `-maes` | Enable AES-NI hardware AES instructions. | Optimized, Additional |
| `-mavx2` | Enable 256-bit AVX2 vectors (only the `*_avx2.so` variant). | Optimized |

### ARM architecture flags

| Flag                       | Purpose                                                                                  | Used by    |
|----------------------------|------------------------------------------------------------------------------------------|------------|
| `-march=armv8.2-a+aes`     | ARMv8.2-A baseline with the AES crypto extension (NEON implied).                         | Optimized  |
| `-march=armv8.2-a+aes+sve` | Same, additionally enabling the Scalable Vector Extension (only the `*_sve.so` variant). | Optimized  |
| `-march=armv8-a+aes`       | ARMv8-A baseline with the AES crypto extension (NEON implied).                           | Additional |

## Quick start

```sh
# Reference (portable) — from e.g. Reference_Implementation/Wish512_reference/
make            # build KAT_CryptHash (default target: kat)
make run-kat    # build and run the known-answer test
make clean      # remove build artifacts

# Optimized / Additional — from a matching tree, e.g. Wish1024_arm_performance_optimized/
make            # build KAT_CryptHash (default target: kat)
make run-kat    # build and run the known-answer test
make bench      # build the benchmark .so files
make clean      # remove build artifacts
```
