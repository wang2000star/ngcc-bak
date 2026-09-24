# Stage S6-16B SHA3-512 Anti-Alias Report

Status: PASS.

| Baseline | Source | Source SHA-256 | Binary | Binary SHA-256 | Empty KAT | abc KAT | Upstream |
|---|---|---|---|---|---|---|---|
| SHA3-512 Reference C (XKCP readable) | `tools/perf/baselines/xkcp_readable/Keccak-readable-and-compact.c` | `7d25b518f28b4b9be141495dde205621fdb528e880596ef9507d30ba1b937dc9` | `tools/perf/baselines/sha3_512_reference_c` | `34102a26f9e6e89c16aa82ccccd05725e6cc36fef645846dd7ad3185953d8e31` | PASS | PASS | `official XKCP Standalone/CompactFIPS202/C/Keccak-readable-and-compact.c` |
| SHA3-512 XKCP CompactFIPS202 (XKCP more-compact) | `tools/perf/baselines/xkcp_more_compact/Keccak-more-compact.c` | `089b4cbd9e9ec314ce9e00514dde4d90678f861b7d754e05e4726eb38cb702a2` | `tools/perf/baselines/xkcp_compactfips202_sha3_512` | `41e4404dd2d42394f532b2d7687a14f23f906266a91f2b0fcebd0211ce32e405` | PASS | PASS | `official XKCP Standalone/CompactFIPS202/C/Keccak-more-compact.c` |
| SHA3-512 OpenSSL EVP | `tools/baselines/bench_openssl_sha3_512.c` | `d174033d510b060482007e200f0f31960f30cd66d871d8ac8586b196d3320cf5` | `tools/perf/baselines/openssl_evp_sha3_512` | `9fcd3727b369d2af9ab359a5a305da352cb52e19b98d44bfdc56e09047b0e09a` | PASS | PASS | `OpenSSL EVP_sha3_512` |

Anti-alias checks:

- Reference C and XKCP CompactFIPS202 source paths differ: PASS.
- Reference C and XKCP CompactFIPS202 source SHA-256 values differ: PASS.
- Reference C and XKCP CompactFIPS202 binary SHA-256 values differ: PASS.
- All three SHA3-512 baseline binaries are distinct: PASS.
- OpenSSL EVP source calls `EVP_sha3_512`: PASS.
