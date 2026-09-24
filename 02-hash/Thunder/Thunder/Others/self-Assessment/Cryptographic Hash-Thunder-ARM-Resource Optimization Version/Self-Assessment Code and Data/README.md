# Self-Assessment Code and Data

This directory contains the complete self-assessment harness and data for Thunder on ARM64.

## Contents

~~~~text
Thunder_ARM64/API_CryptHash/Implementations/  Thunder shared-library source for all three versions.
Thunder_ARM64/API_CryptHash/Test_Vector/      KAT vectors read by ngcc.
ngcc_bench-main/                              ngcc benchmark harness.
result/                                       Raw JSON result files.
~~~~

## Implementation Versions Included

- `Reference_Implementation` builds `libThunder512ref.so`, `libThunder768ref.so`, and `libThunder1024ref.so`.
- `Optimized_Implementation` builds `libThunder512Opt.so`, `libThunder768Opt.so`, and `libThunder1024Opt.so`.
- `Additional_Implementation` builds `libThunder512s.so`, `libThunder768s.so`, and `libThunder1024s.so`.

## Build All Shared Libraries

~~~~bash
cd Thunder_ARM64/API_CryptHash/Implementations
sh all.sh
~~~~

`all.sh` builds all nine Thunder shared libraries: three instances times three implementation versions.

## Build the Resource-Optimized Example Library

This package is named for the resource-optimized version, so this example uses `Additional_Implementation`:

~~~~bash
cd Thunder_ARM64/API_CryptHash/Implementations/Additional_Implementation/Thunder512
sh build.sh
~~~~

The expected output is `libThunder512s.so`. The sibling `Thunder768` and `Thunder1024` directories are built the same way.

## Build ngcc_bench

~~~~bash
cd ngcc_bench-main
mkdir -p build
cd build
cmake ..
make -j
~~~~

## Run Full Self-Assessment Tests

~~~~bash
cd ngcc_bench-main/build
chmod +x testThundera64.sh
./testThundera64.sh
~~~~

The ARM64 script uses `sudo`; run it in an environment where the required privileges are available. It tests Thunder-512, Thunder-768, and Thunder-1024 for all three implementation versions with `--test hash --mode all`.

## KAT Vectors Read by ngcc

~~~~text
../../Thunder_ARM64/API_CryptHash/Test_Vector/Thunder512
../../Thunder_ARM64/API_CryptHash/Test_Vector/Thunder768
../../Thunder_ARM64/API_CryptHash/Test_Vector/Thunder1024
~~~~

These paths are relative to `ngcc_bench-main/build`.

## Manual ngcc Example for the Resource-Optimized Version

~~~~bash
sudo ./ngcc_bench \
  --lib ../../Thunder_ARM64/API_CryptHash/Implementations/Additional_Implementation/Thunder512/libThunder512s.so \
  --test hash \
  --mode all \
  --digest-len-bits 512 \
  --kat ../../Thunder_ARM64/API_CryptHash/Test_Vector/Thunder512 \
  --json-out Thunder512s_A64_report.json
~~~~

For Thunder-768 and Thunder-1024, change the library path, digest length, KAT directory, and output filename accordingly.

## Result Files

Raw JSON result files are stored in `result/`. New runs write `.json.en` and `.json.zh` files in `ngcc_bench-main/build` unless the script or command is changed.
