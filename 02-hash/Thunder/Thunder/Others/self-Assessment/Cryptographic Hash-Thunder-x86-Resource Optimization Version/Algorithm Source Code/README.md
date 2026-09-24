# Algorithm Source Code

This directory contains the standalone Thunder algorithm source code for the named package version.

## Contents

Included instance directories: Thunder-1024, Thunder-512, Thunder-768.

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
cd Thunder-512
chmod +x run_kat.sh
./run_kat.sh
~~~~

The script removes any previous local `kat` executable, rebuilds it with GCC, and runs it.

## Run All Included Instances

From `Algorithm Source Code`, run:

~~~~bash
for d in Thunder-*; do
  if [ -f "$d/run_kat.sh" ]; then
    (cd "$d" && chmod +x run_kat.sh && ./run_kat.sh)
  fi
done
~~~~

## Test Vector Location

Standalone KAT output files may be generated inside each instance directory, usually under an `output` directory or by the local `kat` executable.

The KAT vectors used by ngcc self-assessment are stored separately under:

~~~~text
../Self-Assessment Code and Data/Thunder_X86/API_CryptHash/Test_Vector/Thunder512
../Self-Assessment Code and Data/Thunder_X86/API_CryptHash/Test_Vector/Thunder768
../Self-Assessment Code and Data/Thunder_X86/API_CryptHash/Test_Vector/Thunder1024
~~~~

Those ngcc KAT directories are the paths passed to `ngcc_bench` through the `--kat` option.
