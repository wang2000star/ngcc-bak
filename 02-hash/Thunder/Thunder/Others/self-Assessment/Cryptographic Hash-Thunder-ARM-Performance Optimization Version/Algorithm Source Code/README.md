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

## Run One Algorithm Instance

From this `Algorithm Source Code` directory, enter an instance directory and run `run_kat.sh`:

~~~~bash
cd Thunder-512
chmod +x run_kat.sh
./run_kat.sh
~~~~

## Run All Included Instances

~~~~bash
for d in Thunder-*; do
  if [ -f "$d/run_kat.sh" ]; then
    (cd "$d" && chmod +x run_kat.sh && ./run_kat.sh)
  fi
done
~~~~

## Test Vector Location

Standalone KAT output may be generated inside each instance directory. The KAT vectors used by ngcc are stored separately under:

~~~~text
../Self-Assessment Code and Data/Thunder_ARM64/API_CryptHash/Test_Vector/Thunder512
../Self-Assessment Code and Data/Thunder_ARM64/API_CryptHash/Test_Vector/Thunder768
../Self-Assessment Code and Data/Thunder_ARM64/API_CryptHash/Test_Vector/Thunder1024
~~~~
