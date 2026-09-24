PolarLAC MLWE ARM Optimized Implementation
==========================================

This directory contains the ARM/SVE optimized implementation for the PolarLAC
MLWE submission. The implementation is organized as fixed compile-time
configurations so that each route can be built and measured without runtime
backend switching.

Directory Layout
----------------

- `SM3/POLARLAC-*`: the default API_PKC route using SM3, with
  `BIT_USE_SHAKE=0`.
- `SHAKE/POLARLAC-*`: the SHAKE route, with `BIT_USE_SHAKE=1`.

Each parameter-set directory is self-contained and can be built independently.
The SM3 and SHAKE routes use the same algorithm interface and parameter files,
with route-specific hash configuration and component-switch settings.

Optimization Boundary
---------------------

The ARM implementation is derived from the finalized portable reference
implementation. The optimized code is limited to implementation-level
replacements of the same algorithms in the following components:

- polynomial arithmetic: NTT/INTT, pointwise multiplication, and
  multiply-accumulate operations;
- sampling-layer helpers: ternary sampling and integer-FFT spectral-bound
  helpers where enabled by the fixed route configuration;
- Polar decoding.

The implementation does not change algorithm parameters, public-key or
ciphertext formats, sampling distributions, rejection thresholds, FO/KDF
behavior, or security-level choices.

Component Configuration
-----------------------

The following compile-time configuration is used.

| Route | Arithmetic | Ternary sampler optimization | FFT-bound optimization | Uniform-matrix sampler optimization | Decoder |
| --- | --- | --- | --- | --- | --- |
| SM3 / API_PKC | enabled | disabled | enabled only for `POLARLAC-512-Star` | disabled | enabled |
| SHAKE | enabled | enabled | enabled for `POLARLAC-Light`, `POLARLAC-128`, `POLARLAC-256`, and `POLARLAC-512`; disabled for `POLARLAC-512-Star` | disabled | enabled |

The uniform-matrix sampler remains part of the algorithm in both routes. The
table above only states that its dedicated ARM/SVE optimization component is not
enabled; the sampler uses the reference implementation path compiled with the
route's optimization flags.

API_PKC Support Files
---------------------

The API_PKC support files `auxfunc.c`, `auxfunc.h`, `drng.c`, `drng.h`, and
`KAT_KEM.c` are kept as API_PKC support code. They are not part of the ARM/SVE
algorithmic optimization boundary.

Make Targets
------------

The Makefile targets in each parameter-set directory are:

- `make clean`: remove generated local build artifacts (`test`, `kat_kem`,
  `cycles_test`, object files, stack-usage files, and `output/`).
- `make test`: build the local functional smoke executable named `test`.
- `make kat_kem`: build the API_PKC KAT executable named `kat_kem`. Running
  `./kat_kem` generates `output/KAT_KEM_<instance>.txt`.
- `make cycles_test`: build the local timing and sanity-check executable named
  `cycles_test`. Running `./cycles_test` prints a sanity result, a cycles block,
  and a microseconds block.

ARM/SVE Validation
------------------

The ARM/SVE implementation is intended to be built on an AArch64 Linux machine
with compiler support for `-march=armv8.2-a+sve`. A macOS host can inspect the
source and KAT files, but it is not the target environment for the ARM/SVE build.

From `Implementations/Optimized_Implementation/ARM`, build all fixed SM3 and
SHAKE configurations with:

```sh
set -e
for route in SM3 SHAKE; do
  for inst in POLARLAC-Light POLARLAC-128 POLARLAC-256 POLARLAC-512 POLARLAC-512-Star; do
    (
      cd "$route/$inst"
      make clean
      make test kat_kem cycles_test
    )
  done
done
```

The `test` executable is a local smoke executable. The deterministic fixed-KAT
check for the default SM3/API_PKC route is the KAT replay below.

Single-Instance Build Check
---------------------------

From any parameter-set directory:

```sh
make clean
make test kat_kem cycles_test
```

The `test`, `kat_kem`, and `cycles_test` targets are local executables for
functional checks, KAT replay, and local timing checks, respectively.

Fixed SM3 KAT Replay
--------------------

The fixed KAT files for the default SM3/API_PKC route are stored in:

```text
Test_Vector/Optimized_Implementation/ARM/
```

From `Implementations/Optimized_Implementation/ARM`, replay the SM3 KAT files
with:

```sh
set -e
TV_DIR="$(cd ../../../Test_Vector/Optimized_Implementation/ARM && pwd)"
for inst in POLARLAC-Light POLARLAC-128 POLARLAC-256 POLARLAC-512 POLARLAC-512-Star; do
  (
    cd "SM3/$inst"
    make clean
    make kat_kem
    ./kat_kem
    cmp -s "output/KAT_KEM_${inst}.txt" "$TV_DIR/KAT_KEM_${inst}.txt"
    echo "KAT OK: $inst"
  )
done
```

The SHAKE route is a separate fixed configuration. It is built independently
under `SHAKE/POLARLAC-*`; the fixed KAT files in this package are for the
default SM3/API_PKC route.

Performance Measurement
-----------------------

For local timing checks, build and run the selected route executable:

```sh
make clean
make cycles_test
./cycles_test
```

To collect timing output for all selected ARM/SVE route configurations from
`Implementations/Optimized_Implementation/ARM`, run:

```sh
set -e
for route in SM3 SHAKE; do
  for inst in POLARLAC-Light POLARLAC-128 POLARLAC-256 POLARLAC-512 POLARLAC-512-Star; do
    (
      cd "$route/$inst"
      make clean
      make cycles_test
      echo "===== $route/$inst ====="
      ./cycles_test
    )
  done
done
```

Performance numbers should be reported only for a fixed machine, compiler, and
build profile. The ARM/SVE measurements in the implementation report use the
selected ARM/SVE source with `-O3 -march=armv8.2-a+sve -flto` and report the
microseconds/ns timing block from the selected route measurement.
