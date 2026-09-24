Thunder ARM Implementations
==========================

This directory contains the ARM implementations of the Thunder hash family.
The implementations are organized into three implementation classes:

- Reference_Implementation: portable reference implementations.
- Optimized_Implementation: performance-optimized ARM implementations.
- Additional_Implementation: resource-optimized ARM implementations.

Directory Layout
----------------

Implementations/
  README.txt
    This file. It describes the implementation directory structure and the
    purpose of the files included in each implementation package.

  Reference_Implementation/
    Reference implementations of the Thunder hash family. This directory
    includes the three fixed-output hash instances and three XOF instances.

    Thunder-512/
      Reference implementation of Thunder-512.

    Thunder-768/
      Reference implementation of Thunder-768.

    Thunder-1024/
      Reference implementation of Thunder-1024.

    Thunder-XOF-256/
      Reference implementation of Thunder-XOF-256. The configured hash output
      length for this submitted XOF test instance is 1280 bits.

    Thunder-XOF-384/
      Reference implementation of Thunder-XOF-384. The configured hash output
      length for this submitted XOF test instance is 1152 bits.

    Thunder-XOF-512/
      Reference implementation of Thunder-XOF-512. The configured hash output
      length for this submitted XOF test instance is 1024 bits.

  Optimized_Implementation/
    Performance-optimized ARM implementations of the fixed-output Thunder hash
    instances.

    Thunder-512/
      Performance-optimized implementation of Thunder-512.

    Thunder-768/
      Performance-optimized implementation of Thunder-768.

    Thunder-1024/
      Performance-optimized implementation of Thunder-1024.

  Additional_Implementation/
    Resource-optimized ARM implementations of the fixed-output Thunder hash
    instances.

    Thunder-512/
      Resource-optimized implementation of Thunder-512.

    Thunder-768/
      Resource-optimized implementation of Thunder-768.

    Thunder-1024/
      Resource-optimized implementation of Thunder-1024.

Files in Each Instance Directory
--------------------------------

Each Thunder instance directory contains the files listed below.

CryptHash_AlgorithmInstance.c
  Source file implementing the submitted Thunder hash or XOF instance through
  the required CryptHash interface.

CryptHash_AlgorithmInstance.h
  Header file defining the algorithm instance name, digest/output length, basic
  types, constants, and the CryptHash function prototype.

drng.c
  Source file of the deterministic random number generator used by the KAT
  generator.

drng.h
  Header file for the deterministic random number generator.

KAT_CryptHash.c
  Test-vector generation program for the CryptHash interface.

run_kat.sh
  Shell script that compiles and runs the KAT generator for the corresponding
  instance.

kat
  Generated KAT executable, when present.

output/
  Directory containing the generated known-answer test vector files.

  KAT_2_12_*.txt
    Known-answer test vectors for the 2.12 test set.

  KAT_2_23_*.txt
    Known-answer test vectors for the 2.23 test set.

  KAT_2_33_*.txt
    Known-answer test vectors for the 2.33 test set.

  KAT_Loop_*.txt
    Known-answer test vectors for the loop test set.

Build and Test
--------------

To generate the KAT executable and test vectors for one instance, enter the
corresponding instance directory and run:

  sh run_kat.sh

The generated output files are written to the local output/ directory.
