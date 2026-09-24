# Self-Assessment Code and Data

This directory contains the complete self-assessment harness and data for Dragon on this architecture.

## Contents

~~~~text
Dragon_ARM64/API_CryptHash/Implementations/   Dragon shared-library source for all three versions.
Dragon_ARM64/API_CryptHash/Test_Vector/       KAT vectors read by ngcc.
ngcc_bench-main/                                ngcc benchmark harness.
Result/                                         Raw JSON result files.
~~~~

## Implementation Versions Included

All three implementation versions are included and tested:

- `Reference_Implementation/Dragon512`, `Dragon768`, `Dragon1024` build `libDragon512ref.so`, `libDragon768ref.so`, and `libDragon1024ref.so`.
- `Optimized_Implementation/Dragon512`, `Dragon768`, `Dragon1024` build `libDragon512Opt.so`, `libDragon768Opt.so`, and `libDragon1024Opt.so`.
- `Additional_Implementation/Dragon512`, `Dragon768`, `Dragon1024` build `libDragon512s.so`, `libDragon768s.so`, and `libDragon1024s.so`.

## Build All Shared Libraries

From this `Self-Assessment Code and Data` directory, run:

~~~~bash
cd Dragon_ARM64/API_CryptHash/Implementations
sh all.sh
~~~~

`all.sh` builds all nine Dragon shared libraries: three instances times three implementation versions.

## Build the performance-optimized Example Library

This package is named for the performance-optimized version, so the single-library example below uses `Optimized_Implementation`. To build Dragon-512 for this version, run:

~~~~bash
cd Dragon_ARM64/API_CryptHash/Implementations/Optimized_Implementation/Dragon512
sh build.sh
~~~~

The expected output library is `libDragon512Opt.so`. Dragon-768 and Dragon-1024 are built in the sibling `Dragon768` and `Dragon1024` directories with the same `sh build.sh` command.

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
chmod +x testa64.sh
./testa64.sh
~~~~

The provided ARM script uses `sudo` when invoking `ngcc_bench` and when cleaning JSON files. If your ARM test environment does not require elevated privileges, inspect `testa64.sh` and remove `sudo` locally before running it.

The script runs Dragon-512, Dragon-768, and Dragon-1024 for `Reference_Implementation`, `Optimized_Implementation`, and `Additional_Implementation`. It uses `--test hash --mode all`, so ngcc performs correctness, performance, memory, and other enabled hash self-assessment checks.

## KAT Vectors Read by ngcc

The ngcc script reads KAT vectors from these directories through the `--kat` option:

~~~~text
../../Dragon_ARM64/API_CryptHash/Test_Vector/Dragon512
../../Dragon_ARM64/API_CryptHash/Test_Vector/Dragon768
../../Dragon_ARM64/API_CryptHash/Test_Vector/Dragon1024
~~~~

These paths are relative to `ngcc_bench-main/build`, where the script is executed.

## Manual ngcc Example for the performance-optimized Version

The following command runs one performance-optimized Dragon-512 test manually from `ngcc_bench-main/build`: 

~~~~bash
./ngcc_bench \
  --lib ../../Dragon_ARM64/API_CryptHash/Implementations/Optimized_Implementation/Dragon512/libDragon512Opt.so \
  --test hash \
  --mode all \
  --digest-len-bits 512 \
  --kat ../../Dragon_ARM64/API_CryptHash/Test_Vector/Dragon512 \
  --json-out Dragon512opt_A64_report.json
~~~~

For Dragon-768 and Dragon-1024, change the library path, digest length, KAT directory, and output filename accordingly. The full package script still runs all three implementation versions.

## Result Files

Raw JSON result files are stored in:

~~~~text
Result/
~~~~

New runs write `.json.en` and `.json.zh` files in `ngcc_bench-main/build` unless the script or command is changed. Preserve those files as raw evidence for the self-assessment report.
