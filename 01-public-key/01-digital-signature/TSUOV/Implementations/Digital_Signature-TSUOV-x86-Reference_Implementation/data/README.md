# Self-Assessment Input Data

This directory documents the reproducible inputs used by the digital-signature
self-assessment harness (NGCC x86 guideline section 3.4).

## 1. Known-Answer Test (KAT) vectors

Full KAT vectors for all three security levels are stored under `kat/` and
mirrored in `API_PKC/Test_Vector/`:

| Security level | Public key (B) | Private key (B) | Signature (B) |
|--------------|---------------:|----------------:|----------------:|
| TSUOV_128    | 779            | 32              | 896             |
| TSUOV_256    | 2,170          | 64              | 2,412           |
| TSUOV_512    | 21,319         | 128             | 2,939           |

These match `CRYPTO_PUBLICKEYBYTES` / `CRYPTO_SECRETKEYBYTES` / `CRYPTO_BYTES` in each
parameter set's `tsuov_params.h`.

KAT files (10 vector sets each): `kat/KAT_SIG_TSUOV_{128,256,512}.txt`.
Use the underscore form only; older hyphen-named copies had incorrect `PK_Len` values. `Seed / PK / SK / M / Sn` fields. Vectors are produced by
the official KAT tool (`KAT_SIG.c`) with deterministic DRNG seeding; each
signature is self-verified at generation time.

## 2. Performance and resource test inputs

Performance and resource tests do not rely on external files. Inputs are
generated inside `bench/sig_bench.c`:

- **DRNG seed** (48 bytes): `seed[i] = 0xA5 XOR (i*7 + 1) (mod 256)`, re-injected
  before each keygen / performance loop via `drng_seed()`.
- **Message** (64 bytes, guideline section 3.4.1): `m[i] = i (mod 256)`.
- **Iterations**: default 1000 (minimum 100 per guideline section 3.3); override
  with `ngcc_bench -t <N>` or `run_self_assessment.sh <N>`.

## 3. Notes

- Randomness follows the submission DRNG (`drng.c/.h`) as required by the
  programming-interface specification.
- Fixed seeds and messages are for reproducible self-assessment only; they do not
  represent deployment randomness requirements.
