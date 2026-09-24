# SHA3-512 XKCP CompactFIPS202 (XKCP more-compact)

This baseline wraps the official XKCP source:

`XKCP-master/Standalone/CompactFIPS202/C/Keccak-more-compact.c`

The upstream file is copied unchanged as `Keccak-more-compact.c`.
The wrapper `benchmark_xkcp_compactfips202_sha3_512.c` adds benchmark and KAT
CLI metadata without modifying the official source. This backend is distinct
from the SHA3-512 Reference C readable source.
