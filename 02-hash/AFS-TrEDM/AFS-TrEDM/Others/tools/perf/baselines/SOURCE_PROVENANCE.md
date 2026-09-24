# SHA3-512 Baseline Source Provenance

- `xkcp_readable/benchmark_sha3_512_reference_c.c` is the
  `SHA3-512 Reference C (XKCP readable)` live benchmark entry point.
  It wraps official XKCP
  `Standalone/CompactFIPS202/C/Keccak-readable-and-compact.c`.
  Repo copy: `tools/perf/baselines/xkcp_readable/Keccak-readable-and-compact.c`.
  SHA-256: `7d25b518f28b4b9be141495dde205621fdb528e880596ef9507d30ba1b937dc9`.

- `xkcp_more_compact/benchmark_xkcp_compactfips202_sha3_512.c` is the
  `SHA3-512 XKCP CompactFIPS202 (XKCP more-compact)` live benchmark entry point.
  It wraps the distinct official XKCP
  `Standalone/CompactFIPS202/C/Keccak-more-compact.c`.
  Repo copy: `tools/perf/baselines/xkcp_more_compact/Keccak-more-compact.c`.
  SHA-256: `089b4cbd9e9ec314ce9e00514dde4d90678f861b7d754e05e4726eb38cb702a2`.

- `benchmark_openssl_evp_sha3_512.c` is the `SHA3-512 OpenSSL EVP`
  live benchmark entry point. It wraps `tools/baselines/bench_openssl_sha3_512.c`
  and calls `EVP_sha3_512()`.

- `run_sha3_kat.sh` builds all three SHA3-512 baselines and verifies the
  empty-message KAT, the `abc` KAT, and a generated 1MiB message cross-check
  against OpenSSL EVP.

The two XKCP rows intentionally use different official source files and
different built binaries. The OpenSSL row is a deployment-library baseline and
is not an XKCP source. The root-level `benchmark_sha3_512_ref_c.c` and
`benchmark_xkcp_compact_sha3_512.c` files are compatibility entry points; the
live performance runner builds and executes `sha3_512_reference_c` and
`xkcp_compactfips202_sha3_512`.

All three drivers hash fresh input during each benchmark repetition. Current
performance rows are produced by fresh execution of these drivers and do not
read old CSV files.
