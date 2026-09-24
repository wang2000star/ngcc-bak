# CreTAKE Reference Implementation

This source package provides the reference implementation of the **CreTAKE authenticated key-exchange suite** at the 128-, 256-, and 512-bit security levels.

The KEM and signature source trees under `Common/primitives/` are based on the implementations supplied with the corresponding algorithm submissions. They are used here as cryptographic backends for concrete CreTAKE instantiations. The primary purpose of this source package is therefore the **protocol-layer implementation**: integrating the submitted primitives into CreTAKE, defining the role-specific protocol flows, exposing a uniform KEX interface, and providing correctness, known-answer, and performance tests. Except for changes required for interface compatibility, build integration, or protocol use, the primitive implementations remain attributable to their respective algorithm submissions.

The implementation supports four CreTAKE framework types:

- **K2K** — KEM-to-KEM instantiation
- **K2S** — KEM-to-signature instantiation
- **S2K** — Signature-to-KEM instantiation
- **S2S** — Signature-to-signature instantiation

Each CreTAKE instance is built as a separate executable configuration. The top-level `Makefile` can build, test, and clean all instances, while every CreTAKE instance can also be built, tested, and cleaned independently.

> **Reference-implementation notice.** This source package is prepared for algorithm-submission evaluation, protocol validation, known-answer testing, and performance assessment. It has not necessarily been hardened for production deployment or side-channel resistance. Security and implementation claims for the primitive backends should be understood in the context of their respective algorithm submissions.

---

## Source Package Layout

```text
Reference_Implementation/
├── Makefile
├── Common/
│   └── primitives/
│       ├── kem/
│       │   ├── POLARLAC-128/
│       │   ├── POLARLAC-256/
│       │   ├── POLARLAC-512/
│       │   ├── POLARLAC-512-Star/
│       │   ├── ZEN_128/
│       │   ├── ZEN_256/
│       │   └── ZEN_512/
│       └── sig/
│           ├── BiT-128/
│           ├── BiT-256/
│           └── BiT-512/
├── CreTAKE128/
│   ├── CreTAKE-K2K-PLAC128/
│   ├── CreTAKE-K2K-ZEN128/
│   ├── CreTAKE-K2S-PLAC128-BiT128/
│   ├── CreTAKE-K2S-ZEN128-BiT128/
│   ├── CreTAKE-S2K-BiT128-PLAC128/
│   ├── CreTAKE-S2K-BiT128-ZEN128/
│   ├── CreTAKE-S2S-BiT128-ePLAC128/
│   └── CreTAKE-S2S-BiT128-eZEN128/
├── CreTAKE256/
│   └── ...
├── CreTAKE512/
    └── ...                    
```

### Primitive directories

`Common/primitives/` contains the primitive implementations used to instantiate CreTAKE. These implementations originate from the corresponding KEM and signature algorithm submissions and are incorporated as backend components rather than presented as new primitive implementations in this source package.

`Common/primitives/kem/` contains the KEM backends:

- `POLARLAC-*` — PolarLAC parameter sets
- `ZEN_*` — ZEN parameter sets
- `POLARLAC-512-Star` — the PolarLAC-512-Star parameter set used by the corresponding 512-bit K2K instance

`Common/primitives/sig/` contains the BiT signature backends:

- `BiT-128`
- `BiT-256`
- `BiT-512`

Each primitive directory has its own `Makefile` and can produce a static library for use by the CreTAKE implementations. Local changes, where present, are limited to matters such as interface adaptation, build-system integration, parameter selection, and use within the CreTAKE protocol code.

### CreTAKE directories

The `CreTAKE128/`, `CreTAKE256/`, and `CreTAKE512/` directories group protocol instances by security level.

Directory names encode the framework and primitive combination. For example:

```text
CreTAKE-K2S-PLAC128-BiT128
```

denotes a 128-bit **K2S** instance using **PolarLAC-128** and **BiT-128**.

The abbreviations used in directory names are:

| Identifier | Meaning |
|---|---|
| `K2K` | KEM-to-KEM |
| `K2S` | KEM-to-signature |
| `S2K` | Signature-to-KEM |
| `S2S` | Signature-to-signature |
| `PLAC` | PolarLAC |
| `ZEN` | ZEN |
| `BiT` | BiT signature |

Each CreTAKE directory contains the protocol source code, a local `Makefile`, and the test harnesses required to build:

```text
test_correctness
KAT_KEX
test_efficiency
```

---

## Prerequisites

A Unix-like build environment is recommended.

Required tools:

- A C99-compatible compiler, such as GCC or Clang
- `make`
- `ar`
- A POSIX-compatible shell

Typical versions can be checked with:

```sh
cc --version
make --version
ar --version
```

The implementation uses native optimization flags in some configurations. Performance results are therefore platform- and compiler-dependent.

---

## Quick Start

From the top-level directory:

```sh
make
```

This command builds:

1. all KEM static libraries;
2. all BiT signature static libraries; and
3. all CreTAKE test executables.

Plain `make` **does not run the tests**.

After compilation, run the all-instance test categories with:

```sh
make correctness
make kat
make efficiency
```

To run all categories in the intended order:

```sh
make check
```

The execution order is:

```text
all correctness tests
        ↓
all KAT_KEX tests
        ↓
all efficiency tests
```

---

## Top-Level Build Commands

### Build all implementations

```sh
make
```

Equivalent explicit command:

```sh
make all
```

The build stops with a nonzero exit status if one or more CreTAKE instances fail to compile. A build summary is printed at the end.

### List discovered directories

```sh
make list
```

This prints the KEM, signature, and CreTAKE directories discovered by the root `Makefile`.

### Build only

```sh
make build
```

This builds the primitive libraries and all CreTAKE executables without running tests.

### Run correctness tests

```sh
make correctness
```

This runs `test_correctness` for every CreTAKE instance and prints a final pass/fail summary.

The correctness harness executes a complete protocol run and checks the resulting session keys according to the implementation's test logic.

### Run known-answer tests

```sh
make kat
```

This runs `KAT_KEX` for every CreTAKE instance and prints a final pass/fail summary.

The exact vector-generation or vector-checking behavior is controlled by the corresponding KAT source and configuration macros.

### Run efficiency tests

```sh
make efficiency
```

This runs `test_efficiency` for every CreTAKE instance and reports values such as:

- initiator and responder setup time;
- initiator first-message generation time;
- initiator derivation time;
- responder online processing time;
- total online time; and
- initiator and responder communication sizes.

Timing results are reported in microseconds by the current test harness. Communication sizes are reported in bytes.

### Run the complete test suite

```sh
make check
```

`make check` first ensures that all implementations are up to date, then runs:

1. every `test_correctness`;
2. every `KAT_KEX`; and
3. every `test_efficiency`.

A failure in one instance is recorded, but the root test loop continues so that the remaining instances can still be evaluated. The command returns a nonzero status if any test is missing or fails.

---

## Cleaning and Rebuilding the Complete Source Tree

### Full source-tree cleanup

```sh
make clean
```

The top-level cleanup performs three operations:

1. invokes the local clean target in every CreTAKE directory;
2. invokes the primitive cleanup targets in every KEM and signature directory; and
3. removes residual `.o`, `.a`, and CreTAKE test executable files.

This is the recommended command when a completely clean source tree is required.

### Clean and rebuild without running tests

```sh
make rebuild
```

Equivalent workflow:

```sh
make clean
make
```

Use this after changing:

- compiler options;
- preprocessor definitions;
- primitive backends;
- parameter headers; or
- source files shared by multiple instances.

Compiler flags and macro changes are not always represented in ordinary object-file dependencies, so a clean rebuild avoids stale objects.

### Clean, rebuild, and run all tests

```sh
make rebuild-check
```

Equivalent workflow:

```sh
make clean
make check
```

---

## Building and Testing One CreTAKE Instance

Every CreTAKE instance can be managed independently.

For example:

```sh
cd CreTAKE128/CreTAKE-K2S-PLAC128-BiT128
make
```

The local `make` command builds:

```text
test_correctness
test_efficiency
KAT_KEX
```

The required primitive static libraries are built automatically if they are missing or out of date.

### Run the local correctness test

```sh
./test_correctness
```

### Run the local known-answer test

```sh
./KAT_KEX
```

### Run the local efficiency test

```sh
./test_efficiency
```

### Remove only local CreTAKE build products

```sh
make clean
```

This removes the local object files and local test executables:

```text
*.o
test_correctness
test_efficiency
KAT_KEX
```

It does **not** intentionally remove all shared primitive libraries.

### Remove the local products and referenced primitive libraries

```sh
make clean-all
```

This first performs the local cleanup and then invokes the cleanup targets of the KEM and, where applicable, signature directories referenced by that CreTAKE instance.

Because primitive libraries are shared by multiple CreTAKE instances, `make clean-all` in one instance may remove a static library used by another instance. This is safe—the library will be rebuilt by the next `make`—but top-level cleanup is preferable when cleaning the complete source tree.

### Rebuild one instance

Where the local Makefile provides the target:

```sh
make rebuild
```

Otherwise use:

```sh
make clean-all
make
```

---

## Building and Cleaning Primitive Libraries Directly

Direct primitive builds are mainly useful for primitive-level testing or debugging. Normal CreTAKE builds invoke these targets automatically.

### PolarLAC and ZEN KEM libraries

Enter a KEM directory, for example:

```sh
cd Common/primitives/kem/POLARLAC-128
```

Build the static library:

```sh
make kem-lib
```

Remove the KEM static library and its library object files:

```sh
make clean-kem-lib
```

Remove both primitive test executables and library build products:

```sh
make distclean
```

Depending on the primitive, additional native targets may be available, such as:

```sh
make test
make kat_kem
make cycles_test
```

or:

```sh
make KAT_KEM
make SPEED_KEM
```

Consult the local primitive `Makefile` for the targets supported by that parameter set.

### BiT signature libraries

Enter a BiT directory, for example:

```sh
cd Common/primitives/sig/BiT-128
```

Build the static library:

```sh
make lib
```

Build the local signature KAT executable:

```sh
make
```

Run it where supported:

```sh
make run
```

Remove the local KAT executable and object files:

```sh
make clean
```

Remove only the static library:

```sh
make clean-lib
```

Remove all BiT build products:

```sh
make distclean
```

---

## Build Configuration

Each CreTAKE Makefile identifies its primitive dependencies through variables such as:

```make
KEM_DIR := ../../Common/primitives/kem/POLARLAC-128
KEM_LIB := $(KEM_DIR)/libpolarlac128.a

SIG_DIR := ../../Common/primitives/sig/BiT-128
SIG_LIB := $(SIG_DIR)/libbit128.a
```

This keeps each CreTAKE instance explicitly bound to its intended primitive parameter sets.

Some primitive Makefiles also expose optional configuration variables, for example:

```sh
make BIT_USE_SHAKE=1
```

or:

```sh
make RL_KEM_USE_CONJ_NTT_REJECTION=1
```

Only use options supported by the selected primitive directory. After changing backend or compiler configuration, perform a clean rebuild:

```sh
make rebuild
```

or, for a single instance:

```sh
make clean-all
make
```

Compiler and archive tools can be overridden where the local Makefile supports command-line assignments:

```sh
make CC=clang AR=ar
```

## Test Output and Exit Status

All test programs follow the conventional process-exit model:

- exit status `0` indicates success;
- a nonzero exit status indicates a failed check or execution error.

The top-level test targets report each instance separately:

```text
[PASS] CreTAKE128/CreTAKE-K2S-PLAC128-BiT128/test_correctness
[FAIL] CreTAKE512/CreTAKE-S2K-BiT512-ZEN512/test_correctness (exit code 6)
```

Each category ends with a summary:

```text
Correctness test summary
Passed: N
Failed: M
```

The root command itself returns a nonzero status if any included test fails.

---

## Recommended Development Workflow

For ordinary source changes:

```sh
make
make correctness
```

Before collecting performance results:

```sh
make clean
make
make correctness
make kat
make efficiency
```

Before producing a complete release or submission package:

```sh
make rebuild-check
```

After changing compiler flags, backend macros, or shared primitive code:

```sh
make rebuild
```

Do not benchmark sanitizer, debug, or instrumentation builds as release-performance results.

---

## Parallel Builds

The primitive static libraries are shared by multiple CreTAKE instances. Unless all recursive Makefiles have been verified to be parallel-safe, use the default serial build:

```sh
make
```

Avoid aggressive top-level parallel builds such as:

```sh
make -j
```

when multiple subdirectories may attempt to update the same primitive library concurrently.

---

## Troubleshooting

### A test executable is missing

Build the complete implementation or the individual instance first:

```sh
make
```

or:

```sh
cd <CreTAKE-instance-directory>
make
```

### A build appears to use stale configuration

Clean and rebuild:

```sh
make rebuild
```

For one instance:

```sh
make clean-all
make
```

### A primitive library was removed by another instance's `clean-all`

Rebuild the affected CreTAKE instance or the complete source tree:

```sh
make
```

The required library will be recreated automatically.

### A local test exits without printing its final summary

Check its exit status:

```sh
./test_correctness
echo $?
```

or:

```sh
./test_efficiency
echo $?
```

A nonzero status indicates that the harness returned early because a protocol operation or final check failed.

### Duplicate Makefile target warnings appear

Warnings such as:

```text
overriding commands for target ...
ignoring old commands for target ...
```

indicate that the same target has been defined more than once in a child Makefile. Remove or consolidate the duplicate target definitions before relying on that build.

---

## Notes on Performance Results

Performance values depend on:

- processor model and frequency behavior;
- compiler and compiler version;
- optimization flags;
- selected primitive backend;
- operating-system scheduling;
- system load; and
- benchmark iteration count.

For meaningful comparisons, build all compared instances with the same toolchain and flags, run them on the same machine, and record the test environment together with the results.

---

## Licensing and Attribution

The KEM and signature implementations under `Common/primitives/` are derived from the code supplied with their respective algorithm submissions. Their original authorship, copyright statements, licensing conditions, and usage notices remain applicable.

The CreTAKE-specific contribution in this source package consists primarily of the protocol implementation, primitive integration, framework-specific instantiations, unified KEX interfaces, build orchestration, and protocol-level test and benchmarking code.

See the notices in the individual source files and the accompanying submission materials before redistributing or reusing any primitive implementation.
