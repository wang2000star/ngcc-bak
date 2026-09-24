# HARE Additional ARM/SVE Implementation

Additional ARM/SVE implementation for the active KR line:

```text
HARE-128/256/384/512 KR ARM/SVE
```

The ARM/SVE line uses public-length SVE vector utilities, dense GF2X with public-parameter Toom-3/Karatsuba, NEON PMULL base carry-less multiplication when enabled, SVE-assisted cyclic reduction, conservative RM decoding, and erasure-aware RS with static generator constants.
