# Stage16 SHA3-512 Baseline Source Provenance

Generated from current Stage16 strict-cleanup audit inputs.

| Row label | Driver source path | Upstream source path | Source path | Source SHA-256 | Binary path | Binary SHA-256 | Official source? | KAT status | Fresh benchmark status |
|---|---|---|---|---|---|---|---|---|---|
| SHA3-512 Reference C (XKCP readable) | `tools/perf/baselines/xkcp_readable/benchmark_sha3_512_reference_c.c` | `official XKCP Standalone/CompactFIPS202/C/Keccak-readable-and-compact.c` | `tools/perf/baselines/xkcp_readable/Keccak-readable-and-compact.c` | `7d25b518f28b4b9be141495dde205621fdb528e880596ef9507d30ba1b937dc9` | `tools/perf/baselines/sha3_512_reference_c` | `34102a26f9e6e89c16aa82ccccd05725e6cc36fef645846dd7ad3185953d8e31` | yes | PASS | PASS |
| SHA3-512 XKCP CompactFIPS202 (XKCP more-compact) | `tools/perf/baselines/xkcp_more_compact/benchmark_xkcp_compactfips202_sha3_512.c` | `official XKCP Standalone/CompactFIPS202/C/Keccak-more-compact.c` | `tools/perf/baselines/xkcp_more_compact/Keccak-more-compact.c` | `089b4cbd9e9ec314ce9e00514dde4d90678f861b7d754e05e4726eb38cb702a2` | `tools/perf/baselines/xkcp_compactfips202_sha3_512` | `41e4404dd2d42394f532b2d7687a14f23f906266a91f2b0fcebd0211ce32e405` | yes | PASS | PASS |
| SHA3-512 OpenSSL EVP | `tools/perf/baselines/benchmark_openssl_evp_sha3_512.c` | `OpenSSL EVP_sha3_512` | `tools/baselines/bench_openssl_sha3_512.c` | `d174033d510b060482007e200f0f31960f30cd66d871d8ac8586b196d3320cf5` | `tools/perf/baselines/openssl_evp_sha3_512` | `9fcd3727b369d2af9ab359a5a305da352cb52e19b98d44bfdc56e09047b0e09a` | yes | PASS | PASS |

Anti-alias summary:

- Reference C and XKCP CompactFIPS202 use different official source paths.
- Reference C and XKCP CompactFIPS202 source SHA-256 values differ.
- Reference C and XKCP CompactFIPS202 binary SHA-256 values differ.
- OpenSSL EVP baseline wraps `EVP_sha3_512()` and does not use local Keccak code.
- Fresh benchmark status is read from `docs/perf/live/latest/live_perf_raw.csv`.
