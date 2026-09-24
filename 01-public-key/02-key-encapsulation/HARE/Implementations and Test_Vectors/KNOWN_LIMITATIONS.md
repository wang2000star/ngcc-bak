# Known limitations

- This package is an implementation and self-evaluation package, not a formal
  whole-KEM constant-time proof.
- The checked-in KAT files and the server runner provide correctness and
  reproducibility gates; users should rerun `SERVER_TEST.md` on the target x86
  and ARM/SVE machines before using new performance numbers in a report.
- ARM GF(2^8), SVE Reed-Muller, and SVE Reed-Solomon deep optimizations are
  not claimed by this source package; the selected ARM/SVE implementation uses
  the components documented in `README.md` and
  `docs/HARE_X86_ARM_OPTIMIZATION_MATRIX.md`.
- DFR and concrete-security evidence are upstream-confirmed inputs; the
  estimator scripts and raw evidence are not bundled here.
- The API_PKC helper hash/XOF code is used for correctness and preliminary
  performance testing, not as a final production cryptographic backend.
- Whole-KEM assembly audit, dudect-style timing smoke tests, and production
  seed-expansion hardening are outside this source package and should be
  handled in the accompanying evaluation evidence.

- The API_PKC-facing `kem_dec()` reports ciphertext verification failure with `-1`, as required by the API adapter used in this package.  The internal FO path still computes and writes the implicit-rejection shared secret.
- `VERBOSE` builds print secret intermediate values and are for local debugging only; do not use `VERBOSE` for performance or security evaluation.
- Key-generation fixed-weight support sampling uses rejection/collision loops inherited from the reference design; no whole-keygen local timing hardening claim is made in this package.
- GF2X temporary buffers can contain secret-dependent intermediate values and are not explicitly zeroized in the default performance build.
