# Dragon Self-Assessment Code and Data

This directory contains the final self-assessment code and data packages for the Dragon cryptographic hash family. The package names follow the required material naming style:

~~~~text
Cryptographic Hash-Dragon-<Architecture>-<Implementation Version>
~~~~

Each package contains:

- `Algorithm Source Code`: standalone Dragon algorithm source code and KAT generation programs.
- `Self-Assessment Code and Data`: ngcc benchmark code, Dragon API shared-library wrappers for all three implementation versions, KAT vectors read by ngcc, and raw JSON results.
- `Dependency Information`: dependency declaration. Dragon is self-contained and does not use third-party cryptographic libraries.

Although the six packages are separated by architecture and implementation version for submission naming, the `Self-Assessment Code and Data` directory in each package intentionally contains all three Dragon implementation versions:

- `Reference_Implementation`
- `Optimized_Implementation`
- `Additional_Implementation`

This lets a reviewer rebuild and rerun the complete reference, performance-optimized, and resource-optimized benchmark set from any package.
