# QUBE Implementations

This directory contains the QUBE KEM implementation package.

## Contents

```text
Implementations/
├── Reference_Implementation/   # PDF-aligned portable reference code
├── Optimized_Implementation/   # x86-64/AVX2 optimized code
└── Additional_Implementation/  # Reserved for optional submissions
```

## Reference Implementation

`Reference_Implementation/` is the portable API_PKC implementation. It builds
the five PDF parameter sets:

```text
QUBE-128, QUBE-192, QUBE-256, QUBE-384, QUBE-512
```

Build and test:

```bash
cmake -S Reference_Implementation -B /tmp/qube-ref-build
cmake --build /tmp/qube-ref-build --parallel
ctest --test-dir /tmp/qube-ref-build --output-on-failure
```

See `Reference_Implementation/README.md` for details.

## Optimized Implementation

`Optimized_Implementation/` is the x86-64/AVX2 optimized implementation. The
default build covers:

```text
qube-1, qube-3, qube-4, qube-5
```

These correspond to QUBE-128, QUBE-256, QUBE-384, and QUBE-512.

Build:

```bash
cmake -S Optimized_Implementation -B /tmp/qube-opt-build
cmake --build /tmp/qube-opt-build --parallel
```

Run a functional test:

```bash
/tmp/qube-opt-build/bin/qube-opt-1
```

Run standalone KEM benchmarks:

```bash
/tmp/qube-opt-build/bin/benchmark-kem-1
/tmp/qube-opt-build/bin/benchmark-kem-3
/tmp/qube-opt-build/bin/benchmark-kem-4
/tmp/qube-opt-build/bin/benchmark-kem-5
```

See `Optimized_Implementation/README.md` for details.

## Notes

Use out-of-tree build directories such as `/tmp/qube-ref-build` and
`/tmp/qube-opt-build`. Generated binaries, CMake files, and temporary build
artifacts should not be committed.
