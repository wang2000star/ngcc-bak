# HARE code package — KR-only final-parameter implementation

This package contains the HARE code-based KEM implementation for the active HARE v1.5 KR `[51,41]_2` covering-code line. Historical hamming regression instances are not included in this KR-only package.

HARE-128/256/384/512 correspond to HARE-2/5/7/9 in the algorithm text. Because the commercial-cryptography submission only requires these levels, this package provides only these implementations.

## Package structure

```text
HARE_Code_Package/
  CMakeLists.txt                         top-level automated build script
  README.md                              package structure, build, KAT and validation guidance
  DEPENDENCIES.md                        build and toolchain dependency notes
  KNOWN_LIMITATIONS.md                   declared implementation and evaluation boundaries
  SERVER_TEST.md                         reproducible x86 and ARM/SVE server-validation guide
  MANIFEST.tsv                           deterministic SHA-256 source manifest
  MANIFEST.sha256                        SHA-256 digest of MANIFEST.tsv
  PARAMETER_MANIFEST.tsv                 HARE-128/256/384/512 KR parameter and size summary
  cmake/
    HareAddInstance.cmake                CMake helper for adding HARE instances and tests
    HareCompilerOptions.cmake            Reference, x86 and ARM/SVE compiler flag profiles
  Implementations/
    README.md                            implementation directory overview
    Reference_Implementation/
      README.md                          Reference implementation overview
      HARE-128/kr/                       HARE-128 KR Reference instance adapter
      HARE-256/kr/                       HARE-256 KR Reference instance adapter
      HARE-384/kr/                       HARE-384 KR Reference instance adapter
      HARE-512/kr/                       HARE-512 KR Reference instance adapter
    Optimized_Implementation/
      README.md                          x86 optimized implementation overview
      HARE-128/kr/                       HARE-128 KR x86 optimized instance adapter
      HARE-256/kr/                       HARE-256 KR x86 optimized instance adapter
      HARE-384/kr/                       HARE-384 KR x86 optimized instance adapter
      HARE-512/kr/                       HARE-512 KR x86 optimized instance adapter
    Additional_Implementation/
      README.md                          ARM/SVE additional implementation overview
      HARE-128/kr-arm-sve/               HARE-128 KR ARM/SVE instance adapter
      HARE-256/kr-arm-sve/               HARE-256 KR ARM/SVE instance adapter
      HARE-384/kr-arm-sve/               HARE-384 KR ARM/SVE instance adapter
      HARE-512/kr-arm-sve/               HARE-512 KR ARM/SVE instance adapter
    _shared/
      README.md                          shared-code overview
      api_pkc/                           API_PKC helper copy used by KAT/self-evaluation
      hare_core/
        README.md                        shared HARE core overview
        common/                          KEM control flow, code/compression/symmetric interfaces
        ref/                             portable C99 PKE, parsing, vector, GF/GF2X, RM, RS code
        x86_64/avx256/                   AVX2/PCLMUL kernels used by x86 optimized targets
        aarch64/sve/                     SVE/PMULL kernels used by ARM/SVE additional targets
  Test_Vectors/
    README.md                            KAT file overview
    KAT_KEM_HARE-128-kr.txt              API_PKC KEM KAT for HARE-128-kr
    KAT_KEM_HARE-256-kr.txt              API_PKC KEM KAT for HARE-256-kr
    KAT_KEM_HARE-384-kr.txt              API_PKC KEM KAT for HARE-384-kr
    KAT_KEM_HARE-512-kr.txt              API_PKC KEM KAT for HARE-512-kr
  Self_Evaluation/
    README.md                            test, KAT replay and benchmark instructions
    benchmark/                           deterministic benchmark harness
    tests/                               CTest correctness and KAT replay sources
    results/                             clean result directory for fresh evaluation outputs
  tools/
    README.md                            reproducibility tooling overview
    gates/                               manifest, generated-artifact and instruction-audit gates
    generators/                          deterministic generated-source and README generators
    server/                              x86/ARM server validation runner
    profiling/                           optional component hotspot profiling helper
    arm_sve/                             ARM/SVE feature probe helper
  docs/
    HARE_IMPLEMENTATION_OVERVIEW.md      implementation overview
    HARE_X86_ARM_OPTIMIZATION_MATRIX.md  reference/x86/ARM optimization matrix
```

Each algorithm-instance directory contains the API_PKC-facing adapter, instance
parameters, and instance metadata for that implementation line. The common HARE
implementation sources are shared under `Implementations/_shared/hare_core/`,
and the API_PKC helper copy is under `Implementations/_shared/api_pkc/`. The
submitted package is self-contained: top-level CMake combines each instance
directory with these shared sources to build the Reference, x86 Optimized, and
ARM/SVE Additional targets. Individual instance directories are not intended to
be copied out and built without the shared sources.

`Self_Evaluation/`, `tools/`, and `SERVER_TEST.md` are provided for reproducible
self-evaluation, validation, benchmarking, and packaging checks. They are not
part of the KEM runtime API.

## Implementation lines

```text
Reference_Implementation:
  HARE-128/256/384/512 KR

Optimized_Implementation:
  HARE-128/256/384/512 KR x86

Additional_Implementation:
  HARE-128/256/384/512 KR ARM/SVE
```

## Selected x86 optimized implementation

```text
vector.c          AVX2 add/compare/truncate and public-address support expansion
gf.c              PCLMUL GF(2^8) arithmetic
gf2x.c            PCLMUL base multiply, public-parameter Toom-3,
                  dense Karatsuba/PCLMUL submultiplication, AVX2-assisted reduction
reed_muller.c     AVX2 Hadamard-style path preserving erasure semantics
reed_solomon.c    erasure-aware RS with static generator constants
```

## Selected ARM/SVE Additional implementation

```text
SVE public-length vector add/compare/truncate
SVE public-address support-to-vector mask scan
fixed-loop GF(2^8)
public-parameter top-level Toom-3 GF2X for KR instances
dense Karatsuba GF2X submultiplication
NEON PMULL 64x64 base carry-less multiply when enabled
software CLMUL fallback when PMULL is disabled
SVE-assisted X^PARAM_N-1 reduction
conservative RM path preserving erasures
erasure-aware RS with static generator constants
```

## Final KR sizes

| Instance | Public key | Expanded secret key | Ciphertext | Shared secret |
|---|---:|---:|---:|---:|
| HARE-128-KR | 2629 | 2677 | 4688 | 16 |
| HARE-256-KR | 6580 | 6676 | 11790 | 32 |
| HARE-384-KR | 13157 | 13301 | 23693 | 48 |
| HARE-512-KR | 21812 | 22004 | 39294 | 64 |

The submitted API uses the expanded secret-key representation:

```text
dkKEM = ekKEM || dkPKE || sigma || seedKEM
```

## Local build and validation

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j$(nproc)
ctest --test-dir build --output-on-failure
cmake --build build --target run_kat_all
cmake --build build --target verify_kat_all
cmake --build build --target verify_kat_optimized_all
```

Reproducibility gates:

```bash
bash tools/gates/check_manifest.sh
bash tools/gates/check_generated_artifacts.sh
```

## Server validation

Use `SERVER_TEST.md`. Optional Linux `perf`-based component hotspot profiling can be enabled with `RUN_COMPONENT_PROFILE=1`; it emits CSV and Markdown heatmaps outside the KEM runtime path.

## Security boundary

```text
no PKE/KEM semantic change
no parameter change
no KAT layout change
no secret sparse multiplication
no secret-support indexed memory write
full-length ciphertext comparison
masked implicit-rejection selection
RM erasure semantics preserved
RS error+erasure decoding preserved
```

This package does not claim a formal whole-decapsulation constant-time proof. Assembly inspection, dudect-style timing checks, and production seed-expansion hardening are outside this source package and should be handled in the accompanying evaluation evidence.
