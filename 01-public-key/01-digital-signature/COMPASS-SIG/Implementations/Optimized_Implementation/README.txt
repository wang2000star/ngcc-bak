Optimized Implementation of COMPASS-SIG
========================================

This directory contains the optimized implementation for 64-bit PC processors.

Directory Structure
-------------------
\Optimized_Implementation
  \COMPASS-SIG-128          128-bit classical / 80-bit quantum security
  \COMPASS-SIG-256          256-bit classical / 128-bit quantum security
  \COMPASS-SIG-384          384-bit classical / 192-bit quantum security
  \COMPASS-SIG-512          512-bit classical / 256-bit quantum security

Each instance folder contains a complete, self-contained buildable
implementation. See the README.txt inside each folder for detailed
file descriptions.

Build & Generate KAT
--------------------
  cd COMPASS-SIG-<N>
  make kat                Build KAT generation program
  ./test/test_kat<N>      Run KAT generation (output saved to ./output/)

Notes
-----
- Uses the official ICCS auxiliary functions (pseudoXOF, pseudohash, sm3hash).
- Uses the official ICCS deterministic random number generator (DRNG).
- The cryptographic hash and XOF functions comply with the NGCC submission
  requirements by using only the provided auxfunc API.
- ISO C (C99), no platform-specific intrinsics required.
