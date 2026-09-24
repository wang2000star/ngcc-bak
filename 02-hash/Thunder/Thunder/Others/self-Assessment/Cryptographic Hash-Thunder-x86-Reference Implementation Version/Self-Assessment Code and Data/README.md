# Self-Assessment Code and Data

This directory contains the complete self-assessment harness and data for Thunder on this architecture.

## Contents

~~~~text
Thunder_X86/API_CryptHash/Implementations/  Thunder shared-library source for all three versions.
Thunder_X86/API_CryptHash/Test_Vector/      KAT vectors read by ngcc.
ngcc_bench-main/                                ngcc benchmark harness.
result/Thunder/                                 Raw JSON result files.
~~~~

## Implementation Versions Included

All three implementation versions are included and tested:

- `Reference_Implementation/Thunder512`, `Thunder768`, `Thunder1024` build `libThunder512ref.so`, `libThunder768ref.so`, and `libThunder1024ref.so`.
- `Optimized_Implementation/Thunder512`, `Thunder768`, `Thunder1024` build `libThunder512Opt.so`, `libThunder768Opt.so`, and `libThunder1024Opt.so`.
- `Additional_Implementation/Thunder512`, `Thunder768`, `Thunder1024` build `libThunder512s.so`, `libThunder768s.so`, and `libThunder1024s.so`.

## Build All Shared Libraries

From this `Self-Assessment Code and Data` directory, run:

~~~~bash
cd Thunder_X86/API_CryptHash/Implementations
sh all.sh
~~~~

`all.sh` builds all nine Thunder shared libraries: three instances times three implementation versions.

## Build the Reference Example Library

This package is named for the resource-optimized version, so the single-library example below uses `Additional_Implementation`. To build Thunder-512 for this version, run:

~~~~bash
cd Thunder_X86/API_CryptHash/Implementations/Additional_Implementation/Thunder512
sh build.sh
~~~~

The expected output library is `libThunder512s.so`. Thunder-768 and Thunder-1024 are built in the sibling `Thunder768` and `Thunder1024` directories with the same `sh build.sh` command.

## Build ngcc_bench

If `ngcc_bench-main/build/ngcc_bench` is not already available, rebuild it:

~~~~bash
cd ngcc_bench-main
mkdir -p build
cd build
cmake ..
make -j
~~~~

## Run Full Self-Assessment Tests

After building the shared libraries and `ngcc_bench`, run the provided script from the benchmark build directory:

~~~~bash
cd ngcc_bench-main/build
chmod +x testThunderX64.sh
./testThunderX64.sh
~~~~

The provided x86 script runs without `sudo`.

The script runs Thunder-512, Thunder-768, and Thunder-1024 for `Reference_Implementation`, `Optimized_Implementation`, and `Additional_Implementation`. It uses `--test hash --mode all`, so ngcc performs correctness, performance, memory, and other enabled hash self-assessment checks.

## KAT Vectors Read by ngcc

The ngcc script reads KAT vectors from these directories through the `--kat` option:

~~~~text
../../Thunder_X86/API_CryptHash/Test_Vector/Thunder512
../../Thunder_X86/API_CryptHash/Test_Vector/Thunder768
../../Thunder_X86/API_CryptHash/Test_Vector/Thunder1024
~~~~

These paths are relative to `ngcc_bench-main/build`, where the script is executed.

## Manual ngcc Example for the resource-optimized Version

The following command runs one resource-optimized Thunder-512 test manually from `ngcc_bench-main/build`: 

~~~~bash
./ngcc_bench \
  --lib ../../Thunder_X86/API_CryptHash/Implementations/Additional_Implementation/Thunder512/libThunder512s.so \
  --test hash \
  --mode all \
  --digest-len-bits 512 \
  --kat ../../Thunder_X86/API_CryptHash/Test_Vector/Thunder512 \
  --json-out Thunder512s_X86_report.json
~~~~

For Thunder-768 and Thunder-1024, change the library path, digest length, KAT directory, and output filename accordingly. The full package script still runs all three implementation versions.

## Result Files

Raw JSON result files are stored in:

~~~~text
result/Thunder/
~~~~

New runs write `.json.en` and `.json.zh` files in `ngcc_bench-main/build` unless the script or command is changed. Preserve those files as raw evidence for the self-assessment report.
