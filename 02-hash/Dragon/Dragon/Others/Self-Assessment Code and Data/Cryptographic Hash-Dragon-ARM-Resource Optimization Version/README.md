# Cryptographic Hash-Dragon-ARM-Resource Optimization Version

This package contains the self-assessment code and data materials for the Dragon cryptographic hash family.

## Package Summary

- Algorithm category: Cryptographic Hash.
- Algorithm name: Dragon.
- Target architecture: ARM.
- Named implementation version: Resource Optimization Version.
- Algorithm source code in this package: `Additional_Implementation` style source for the named version.
- Standalone source instances: Dragon-1024, Dragon-512, Dragon-768.

## Directory Layout

~~~~text
Algorithm Source Code/
Self-Assessment Code and Data/
Dependency Information/
~~~~

## Important Note About Self-Assessment Code

The `Self-Assessment Code and Data` directory contains all three implementation versions, not only the named version of this package:

- `Reference_Implementation`: reference implementation, producing `libDragon*ref.so`.
- `Optimized_Implementation`: performance optimization implementation, producing `libDragon*Opt.so`.
- `Additional_Implementation`: resource optimization implementation, producing `libDragon*s.so`.

The ngcc test script in this package runs all three versions for Dragon-512, Dragon-768, and Dragon-1024.

## Where to Start

1. See `Algorithm Source Code/README.md` to build and run the standalone algorithm/KAT programs.
2. See `Self-Assessment Code and Data/README.md` to build `.so` libraries and run ngcc self-assessment tests.
3. See `Dependency Information/DEPENDENCIES.md` for dependency information.
