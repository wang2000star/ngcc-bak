# Cuishen Hash Algorithm - x86 Performance-Optimized Version

This directory contains x86 AVX2+BMI2 assembly implementations optimized for
the three Cuishen parameter sets: Cuishen-512, Cuishen-768, and Cuishen-1024.

This package is organized for the performance submission: only the AVX2+BMI2
assembly path is included. The target evaluation platform should support AVX2,
BMI2, and ADX. This package is not a general AVX2-compatible implementation for
processors without BMI2.

Each parameter set contains:

- `CryptHash_Cuishen-*_x86.S`: single-file AVX2+BMI2 assembly implementation.
- `CryptHash_Cuishen-*.h`: public interface header for the corresponding
  parameter set.

File mapping:

| Parameter set | Submitted file                              |
| ------------ | --------------------------------------------- |
| Cuishen-512  | `Cuishen-512/CryptHash_Cuishen-512_x86.S`   |
| Cuishen-768  | `Cuishen-768/CryptHash_Cuishen-768_x86.S`   |
| Cuishen-1024 | `Cuishen-1024/CryptHash_Cuishen-1024_x86.S` |

## Compilation

It is recommended to use
`NGCC-benchmark/build_ngcc_hash_benchmark.sh --variant avx2` to select the
files automatically. Example for manually compiling Cuishen-512:

```sh
gcc -O3 -march=x86-64 -mavx2 -mbmi -mbmi2 -madx \
  -mtune=native -flto -fomit-frame-pointer \
  -std=c99 -Wpedantic -Wall -Wextra \
  -I Cuishen-512 \
  Cuishen-512/CryptHash_Cuishen-512_x86.S \
  <test_or_benchmark_sources> \
  -o <output>
```

Example for Cuishen-768:

```sh
gcc -O3 -march=x86-64 -mavx2 -mbmi -mbmi2 -madx \
  -mtune=native -flto -fomit-frame-pointer \
  -std=c99 -Wpedantic -Wall -Wextra \
  -I Cuishen-768 \
  Cuishen-768/CryptHash_Cuishen-768_x86.S \
  <test_or_benchmark_sources> \
  -o <output>
```

Example for Cuishen-1024:

```sh
gcc -O3 -march=x86-64 -mavx2 -mbmi -mbmi2 -madx \
  -mtune=native -flto -fomit-frame-pointer \
  -std=c99 -Wpedantic -Wall -Wextra \
  -I Cuishen-1024 \
  Cuishen-1024/CryptHash_Cuishen-1024_x86.S \
  <test_or_benchmark_sources> \
  -o <output>
```

## Notes

- This package targets an x86-64 AVX2/BMI2/ADX evaluation environment. AVX-512
  compiler options should not be added.
- The main `.S` files can be compiled directly and do not depend on additional
  assembly fragment directories.
- For each parameter set, link exactly one `CryptHash` implementation: the
  AVX2+BMI2 assembly implementation in this directory.
