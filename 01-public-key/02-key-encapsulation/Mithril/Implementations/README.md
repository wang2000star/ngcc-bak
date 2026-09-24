# RRLWR Implementation Package

This folder contains the Mithril KEM implementation package.

## Folder Contents

| Path | Description |
| --- | --- |
| `README.md` | Package overview and test guide. |
| `.gitignore` | Ignore rules for generated binaries, KAT output folders, speed-test output, and local build artifacts. |
| `Reference_Implementation/` | Reference implementations. `Mithril-*` directories are scalar SM3 KEM implementations. |
| `Optimized_Implementation/` | Optimized implementations. `Mithril-*` directories are AVX2/NTT SM3 KEM implementations. |
| `Additional_Implementation/` | Additional SHA3/SHAKE AVX2 Mithril KEM implementations. `Mithril-*` directories are AVX2/NTT implementations using the SHA3/SHAKE hashing path. |
| `Test_Vectors/` | Known-answer test files. Mithril KEM SM3 files are named `KAT_KEM_Mithril-128.txt`, `KAT_KEM_Mithril-256.txt`, and `KAT_KEM_Mithril-512.txt`. |

Local repository/tooling metadata such as `.git/`, `.agents/`, and `.codex/`
may exist in this workspace, but they are not implementation files.

## Mithril KEM Layout

```text
Reference_Implementation/
  Mithril-128/
  Mithril-256/
  Mithril-512/
Optimized_Implementation/
  Mithril-128/
  Mithril-256/
  Mithril-512/
Additional_Implementation/
  Mithril-128/
  Mithril-256/
  Mithril-512/
```

Each `Mithril-*` directory is self-contained and only builds the security level
in its name. For example, `Mithril-128` builds only `KEM128` targets.

The optimized Mithril directories are derived from:

```text
/home/ubuntu/ARCANE-Mithril/RRLWR_KEM_NTT_AVX copy
```

The reference Mithril directories are derived from:

```text
/home/ubuntu/ARCANE-Mithril/RRLWR_KEM_TCook copy
```

Both families use the SM3 `auxfunc.c`/`drng.c` hashing path.

The additional Mithril directories are derived from the original SHA3/SHAKE
AVX2 implementation:

```text
/home/ubuntu/ARCANE-Mithril/RRLWR_KEM_NTT_AVX
```

## Build And Test

Run `python3 test_hash_domain_encoding.py` from this package directory to check
that the KEM hash and XOF domain inputs use explicit labels and
length-delimited fields.

Run commands from inside the target security-level directory.

Example for the SM3 reference implementation:

```sh
cd Reference_Implementation/Mithril-128
make test
make test run=1
make KAT run=1
make speed run=1
make clean
```

The same command pattern applies to:

```sh
cd Reference_Implementation/Mithril-256
cd Reference_Implementation/Mithril-512
cd Optimized_Implementation/Mithril-128
cd Optimized_Implementation/Mithril-256
cd Optimized_Implementation/Mithril-512
cd Additional_Implementation/Mithril-128
cd Additional_Implementation/Mithril-256
cd Additional_Implementation/Mithril-512
```

Target behavior:

| Command | Behavior |
| --- | --- |
| `make test` | Builds the functional and unit-test binaries for the directory's security level. Reference directories also build arithmetic correctness. |
| `make test run=1` | Builds and runs the functional and unit tests. Reference directories also run arithmetic correctness. |
| `make KAT` | Builds the KAT binary. |
| `make KAT run=1` | Builds and runs the KAT binary, writing `output/KAT_KEM_KEM_RRLWR*.txt`. |
| `make speed` | Builds the whole-stage speed-test binary. |
| `make speed run=1` | Builds and runs whole-stage keygen/encaps/decaps speed tests. |
| `make clean` | Removes generated binaries and local output files for that directory. |

The optimized Mithril directories also provide:

| Command | Behavior |
| --- | --- |
| `make breakdown` | Builds the stage-breakdown speed-test binary. |
| `make breakdown run=1` | Builds and runs stage-breakdown speed tests. |

## KAT Consistency

The expected Mithril KAT relationships are:

| Implementation | Expected KAT Match |
| --- | --- |
| `Reference_Implementation/Mithril-*` | Matches the corresponding SM3 optimized Mithril KAT. |
| `Optimized_Implementation/Mithril-*` | Matches `/home/ubuntu/ARCANE-Mithril/RRLWR_KEM_NTT_AVX copy` SM3 KAT. |
| `Additional_Implementation/Mithril-*` | Matches the corresponding original SHA3/SHAKE AVX2 `/home/ubuntu/ARCANE-Mithril/RRLWR_KEM_NTT_AVX` KAT. |
| `Test_Vectors/KAT_KEM_Mithril-*.txt` | Copied from the verified SM3 KAT output. |
