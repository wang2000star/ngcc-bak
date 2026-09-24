# Octarine Implementation Package

This folder contains three Octarine implementation families, separated by
primitive and optimization level. Each family contains one directory per
security level: `Octarine-128`, `Octarine-256`, and `Octarine-512`.

## Folder Contents

| Path | Description |
| --- | --- |
| `README.md` | This package overview and test guide. |
| `.gitignore` | Ignore rules for generated binaries, KAT output folders, speed-test output, and local build artifacts. |
| `Reference_Implementation/` | SM3-based pseudoXOF reference implementation. Each `Octarine-*` subdirectory supports only its matching security level. |
| `Optimized_Implementation/` | SM3-based pseudoXOF AVX2 implementation. It keeps the AVX2 arithmetic and packing optimizations while using the SM3 hashing path. |
| `Additional_Implementation/` | SHA3/SHAKE AVX2 implementation copied from the original `avx2` path. This is the additional AVX2 implementation using the SHA3/SHAKE hashing path. |
| `Test_Vectors/` | Shared known-answer test files for the SM3-based pseudoXOF Octarine parameter sets: `KAT_SIG_Octarine-128.txt`, `KAT_SIG_Octarine-256.txt`, and `KAT_SIG_Octarine-512.txt`. These files validate `Reference_Implementation` and `Optimized_Implementation`; they are not the SHA3/SHAKE Additional KATs. |

Local repository/tooling metadata such as `.git/`, `.agents/`, and `.codex/`
may exist in this workspace, but they are not implementation files.

## Security-Level Layout

Each implementation family has the same layout:

```text
<Implementation_Family>/
  Octarine-128/
  Octarine-256/
  Octarine-512/
```

Each `Octarine-*` directory is self-contained and only supports the security
level in its name. For example, `Octarine-128` builds only `SIGN128` targets.

## Build And Test

Run commands from inside the target security-level directory.

Example for the SM3 reference implementation:

```sh
cd Reference_Implementation/Octarine-128
make test
make test run=1
make KAT run=1
make speed run=1
make breakdown run=1
make clean
```

The same command pattern applies to:

```sh
cd Reference_Implementation/Octarine-256
cd Reference_Implementation/Octarine-512
cd Optimized_Implementation/Octarine-128
cd Optimized_Implementation/Octarine-256
cd Optimized_Implementation/Octarine-512
cd Additional_Implementation/Octarine-128
cd Additional_Implementation/Octarine-256
cd Additional_Implementation/Octarine-512
```

Target behavior:

| Command | Behavior |
| --- | --- |
| `make test` | Builds the functional and unit-test binaries for the directory's security level. |
| `make test run=1` | Builds and runs the functional and unit tests. |
| `make KAT` | Builds the KAT binary. |
| `make KAT run=1` | Builds and runs the KAT binary, writing `output/KAT_SIG_SIGN_RRLWR.txt`. |
| `make speed` | Builds the whole-stage speed-test binary. |
| `make speed run=1` | Builds and runs whole-stage keygen/sign/verify speed tests. |
| `make breakdown` | Builds the stage-breakdown speed-test binary. |
| `make breakdown run=1` | Builds and runs stage-breakdown speed tests. |
| `make clean` | Removes generated binaries and local output files for that directory. |

From this `ARCANE-Octarine` directory, run
`python3 test_hash_domain_encoding.py` to check that the signature hash and XOF
call sites use the domain-separated wrappers, including the stage-breakdown
sources.

The AVX2 implementation families also provide:

| Command | Behavior |
| --- | --- |
| `make packing-avx-test` | Builds the AVX2 packing self-test for the directory's security level. |
| `make packing-avx-test run=1` | Builds and runs the AVX2 packing self-test. |

## KAT Consistency

The shared `Test_Vectors/` files are the canonical SM3-based pseudoXOF
Octarine KAT outputs.
They are expected to reproduce from the `Reference_Implementation` and
`Optimized_Implementation` families. The `Additional_Implementation` family
uses the original SHA3/SHAKE hashing path and a different DRNG, so its
deterministic `make KAT run=1` output starts from a different seed and is not
expected to match the shared SM3 vectors.

The expected KAT relationships are:

| Implementation | Expected KAT Match |
| --- | --- |
| `Reference_Implementation/Octarine-*` | Matches `Test_Vectors/KAT_SIG_Octarine-*.txt`. |
| `Optimized_Implementation/Octarine-*` | Matches `Test_Vectors/KAT_SIG_Octarine-*.txt`. |
| `Additional_Implementation/Octarine-*` | Does not match the shared SM3 vectors; it produces deterministic SHA3/SHAKE Additional KAT output under its local `output/` directory. |

The `Test_Vectors/` files contain the SM3-based pseudoXOF Octarine KAT
outputs.
