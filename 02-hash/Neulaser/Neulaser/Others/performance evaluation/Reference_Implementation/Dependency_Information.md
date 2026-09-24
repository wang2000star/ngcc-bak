# Dependency Information

This package is the reference implementation self-assessment material for
`Neulaser-512`, `Neulaser-768`, and `Neulaser-1024`.

## Third-party Cryptographic Libraries

None.  The implementation uses only ISO C99 source files and standard C
library headers.  No external cryptographic library is required.

## Build Dependencies

| Item | Version used in the reported test |
|---|---|
| Compiler | GCC 15.2.0, target `x86_64-w64-mingw32` |
| Build tool | `mingw32-make` / GNU Make 4.4.1 |
| Runtime | MSYS2 runtime 3.6.9 |
| Language standard | ISO C99 |
| Compile flags | `gcc -std=c99 -Wpedantic -Wall -Wextra -O2` |

The x86 self-assessment guideline recommends Linux and GCC 8.5.0 or later.
The reported measurement was performed in the documented Windows/MSYS2
environment used for this submission; the source package and commands are
kept reproducible for re-testing on a Linux x86-64 platform.
