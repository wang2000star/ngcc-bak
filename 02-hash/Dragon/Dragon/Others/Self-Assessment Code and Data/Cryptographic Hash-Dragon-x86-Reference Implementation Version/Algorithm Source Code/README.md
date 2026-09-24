# Algorithm Source Code

This directory contains the standalone Dragon algorithm source code for the named package version.

## Contents

Included instance directories: Dragon-1024, Dragon-512, Dragon-768, Dragon-XOF-256, Dragon-XOF-384, Dragon-XOF-512.

Each instance directory contains the files needed to build and run the standalone KAT generator, usually including:

~~~~text
CryptHash_AlgorithmInstance.c
CryptHash_AlgorithmInstance.h
KAT_CryptHash.c
drng.c
drng.h
run_kat.sh
~~~~

The standalone KAT program is independent of ngcc. It is used to generate or verify the known-answer test files for the algorithm source.

## Run One Algorithm Instance

From this `Algorithm Source Code` directory, enter an instance directory and run `run_kat.sh`:

~~~~bash
cd Dragon-512
chmod +x run_kat.sh
./run_kat.sh
~~~~

The script removes any previous local `kat` executable, rebuilds it with GCC, and runs it.

## Run All Included Instances

From `Algorithm Source Code`, run:

~~~~bash
for d in Dragon-*; do
  if [ -f "$d/run_kat.sh" ]; then
    (cd "$d" && chmod +x run_kat.sh && ./run_kat.sh)
  fi
done
~~~~

## Test Vector Location

Standalone KAT output files may be generated inside each instance directory, usually under an `output` directory or by the local `kat` executable.

The KAT vectors used by ngcc self-assessment are stored separately under:

~~~~text
../Self-Assessment Code and Data/Dragon_X86/API_CryptHash/Test_Vector/Dragon512
../Self-Assessment Code and Data/Dragon_X86/API_CryptHash/Test_Vector/Dragon768
../Self-Assessment Code and Data/Dragon_X86/API_CryptHash/Test_Vector/Dragon1024
~~~~

Those ngcc KAT directories are the paths passed to `ngcc_bench` through the `--kat` option.
