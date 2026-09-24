# SQIsign2d-push^1/2

This library is a C implementation of SQIsign.

## Requirements

- CMake (version 3.13 or later)
- C11-compatible compiler
- GMP (version 6.0.0 or later)

### Pre-computation

The constant values in the `src/precomp` directory were generated using the
pre-computation scripts in the `scripts/precomp` directory. It is not necessary
to execute these scripts to compile the project. The scripts have the following
requirements:
- [two-isogenies](https://github.com/ThetaIsogenies/two-isogenies)
  (`Theta-SageMath` version).
- [deuring-2D](https://github.com/Jonathke/deuring-2D)

## Build and Benchmarks

For a generic build
```
$ mkdir -p build
$ cd build
$ cmake -DSQISIGN_BUILD_TYPE=ref -DCMAKE_BUILD_TYPE=Release ..
$ make
$ ./test/sqisign2d_<level>
```
where `<level>=lvl1,lvl2,lvl3,lvl4`, which specifies the SQIsign parameter set.

The benchmarks profile the key generation, signature and verification functions. The results are reported in CPU cycles if available on the host platform, and timing in nanoseconds otherwise.


### SQISIGN_BUILD_TYPE

Specifies the build type for which SQIsign is built. The currently supported values are:
- `ref`: builds the plain reference implementation.

### GMP_LIBRARY

If set to `SYSTEM` (by default), the gmp library on the system is dynamically linked.

If set to `BUILD`, a custom gmp library is linked, which is built as part of the overall build process.
In this case, the following further options are available:
- `ENABLE_GMP_STATIC`: Does static linking against gmp. The default is `OFF`.
- `GMP_BUILD_CONFIG_ARGS`: Provides additional config arguments for the gmp build (for example `--disable-assembly`). By default, no config arguments are provided.

If set to `MINI`, the mini-gmp library is used, whose sources are included in the repository, in the folder `src/mini-gmp`. In this case, no copies of the full gmp library (system or custom-built) are required.

### ENABLE_SIGN

If set to `ON` (default), SQIsign is built with signature and verification functionality.
If set to `OFF`, SQIsign is built with verification functionality only.
In the latter case, GMP is no longer a dependency.

### CMAKE_BUILD_TYPE

Can be used to specify special build types. The options are:

- `Release`: Builds with optimizations enabled and assertions disabled.
- `Debug`: Builds with debug symbols.
- `ASAN`: Builds with AddressSanitizer memory error detector.
- `MSAN`: Builds with MemorySanitizer detector for uninitialized reads.
- `LSAN`: Builds with LeakSanitizer for run-time memory leak detection.
- `UBSAN`: Builds with UndefinedBehaviorSanitizer for undefined behavior detection.

The default build type uses the flags `-O3 -Wstrict-prototypes -Wno-error=strict-prototypes -fvisibility=hidden -Wno-error=implicit-function-declaration -Wno-error=attributes`. (Notice that assertions remain enabled in this configuration, which harms performance.)

## KAT

The KAT file can be genrated by runing the following command in the "build" folder:

```
./iccs/<level>/kat_sig_sqisign2d__<level>

```
where `<level>=lvl1,lvl2,lvl3,lvl4`, which specifies the SQIsign parameter set.
 
The KAT file will given in the "\build\output" folder.



## Project Structure

The source code consists of a number of sub-libraries used to implement the
final SQIsign library:
- `common`: common code for hash function, seed expansion, PRNG, memory handling.
- `mp`: code for saturated-representation multiprecision arithmetic.
- `gf`: GF(p^2) and GF(p) arithmetic.
- `ec`: elliptic curves, isogenies and pairings. Everything that is purely
   finite-fieldy.
- `precomp`: constants and precomputed values.
- `quaternion`: quaternion orders and ideals.
- `hd`: code to compute (2,2)-isogenies in the theta model.
- `id2iso`: code for Ideal <-> Iso.
- `qisigndim2`: code for test,benchmarks, keygen,sign.

The dependencies are depicted below.
```
 ┌─┬──────────┬─┐        ┌─┬──────────┬─┐      ┌─┬──────────┬─┐
 │ ├──────────┤ │        │ ├──────────┤ │      │ ├──────────┤ │
 │ │  Keygen  │ │        │ │   Sign   │ │      │ │  Verify  │ │
 │ ├──────────┤ │        │ ├──────────┤ │      │ ├──────────┤ │
 └─┴────┬─────┴─┘        └─┴────┬─────┴─┘      └─┴────┬─────┴─┘
        │                       │                     │
        └──────────────────┐    │                     │
                           │    │                     │
┌─────────────────┐    ┌───▼────▼────────┐            │
│                 │    │                 │            │
│   Quaternions   ◄────┤  Ideal <-> Iso  ├────────┐   │
│                 │    │                 │        │   │
└────────┬────────┘    └────────┬────────┘        │   │
         │                      │                 │   │
         │                      │     ┌───────────────┘
         │                      │     │           │
┌────────▼────────┐    ┌────────▼─────▼──┐    ┌───▼────────────┐
│                 │    │                 │    │                │
│ Multiprecision  │    │       2D        ├────► Precomputation │
│ integers (GMP)  │    │    Isogenies    │    │                │
│                 │    │                 │    │                │
└─────────────────┘    └────────┬────────┘    └───▲────────────┘
                                │                 │
                                │                 │
                                │                 │
                       ┌────────▼────────┐        │
                       │                 │        │
                       │ Elliptic curves ├────────┘
                       │   & isogenies   │
                       │                 │
                       └──┬───────────┬──┘
                          │           │
                          │           │
                          │           │
              ┌───────────▼───┐   ┌───▼───────────┐
              │     GF(p)     │   │     Fixed     │
              │       &       │   │   precision   │
              │    GF(p^2)    │   │   integers    │
              └───────────────┘   └───────────────┘
