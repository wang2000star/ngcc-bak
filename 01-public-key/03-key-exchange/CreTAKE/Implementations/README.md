# CreTAKE Implementation Package

This package contains the reference and optimized implementations of the **CreTAKE authenticated key-exchange suite** at the 128-, 256-, and 512-bit security levels.

## Directory Structure

```text
.
├── Reference_Implementation/
│   ├── README.md
│   ├── Makefile
│   ├── Common/
│   ├── CreTAKE128/
│   ├── CreTAKE256/
│   ├── CreTAKE512/
├── Optimized_Implementation/
│   ├── README.md
│   ├── Makefile
│   ├── Common/
│   ├── CreTAKE128/
│   ├── CreTAKE256/
│   ├── CreTAKE512/
└── README.md
```

## Directory Description

### `Reference_Implementation/`

Contains the portable reference implementation of CreTAKE. It is intended for functional verification, known-answer testing, interoperability evaluation, and portable performance assessment.

The implementation is written in portable C and does not rely on platform-specific vector instructions.

See:

```text
Reference_Implementation/README.md
```

for the complete directory description, build instructions, test commands, and implementation notes.

### `Optimized_Implementation/`

Contains the optimized implementation of CreTAKE for supported x86-64 platforms. It uses optimized implementations of the underlying cryptographic primitives, including AVX2-enabled code where applicable.

It is intended for optimized performance evaluation while preserving the same protocol interfaces, message formats, and parameter sets as the reference implementation.

See:

```text
Optimized_Implementation/README.md
```

for the complete directory description, build instructions, test commands, platform requirements, and implementation notes.

### `README.md`

This file provides the top-level organization of the implementation package. Detailed descriptions of source files, algorithm instances, primitive directories, build procedures, and test programs are provided in the README file contained in each implementation directory.

## Implementation Organization

Both implementation directories contain:

* `Common/` — implementations of the KEM and signature primitives used as CreTAKE backends;
* `CreTAKE128/` — CreTAKE instances at the 128-bit security level;
* `CreTAKE256/` — CreTAKE instances at the 256-bit security level;
* `CreTAKE512/` — CreTAKE instances at the 512-bit security level;
* `Makefile` — top-level build and test orchestration for the implementation;
* `tools/` — optional scripts for processing test results and generating performance tables;
* `README.md` — detailed documentation for the corresponding implementation.

Each CreTAKE instance directory contains its protocol implementation, build configuration, correctness test, and efficiency test.
