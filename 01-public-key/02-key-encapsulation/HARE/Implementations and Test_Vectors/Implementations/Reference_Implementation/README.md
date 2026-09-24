# HARE Reference Implementation

Portable ISO C99 implementation for the active KR line:

```text
HARE-128/256/384/512 KR
```

The Reference line avoids platform-specific SIMD and intrinsic headers. It uses the bundled API_PKC helper source for deterministic KAT generation and initial self-evaluation. Default compilation follows the package Reference profile: `-std=c99 -Wpedantic -Wall -Wextra -O2`.

The active KR parameters and expanded API sizes are recorded in `../../PARAMETER_MANIFEST.tsv`.
