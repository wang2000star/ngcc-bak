# MAMBA-Frost-CC-384 reference API_PKC KEM instance

This directory wraps the existing Frost-CC-384 reference implementation under the official API_PKC KEM interface (KEM_AlgorithmInstance.h/.c). It does not change Frost-CC parameters, key formats, ciphertext formats, shared-secret formats, FO/implicit-rejection logic, or RNG call semantics.

## Parameters

| field | bytes |
|---|---:|
| public key | 37628 |
| secret key | 43492 |
| ciphertext | 25204 |
| shared secret | 48 |

The sizes come from Frost-CC/src/api_frostcc384.h and are checked by params.h against the API_PKC macros.

## API mapping

| API_PKC function | Frost-CC core function |
|---|---|
| kem_keygen | crypto_kem_keypair_FrostCC384 |
| kem_enc | crypto_kem_enc_FrostCC384 |
| kem_dec | crypto_kem_dec_FrostCC384 |

## Source path

- Frost-CC/src/frostcc384.c
- Frost-CC/src/kem.c
- Frost-CC/src/noise.c
- Frost-CC/src/util.c
- `Frost-CC/src/frost_macrify_reference.c`

## Commands

`sh
make
make check
make kat-generate
make kat-repro
make kat-install
make clean
`

Reference builds use `_REFERENCE_`, portable scalar arithmetic, and `common/aes/aes_c.c`.

KAT mode uses the official API_PKC DRNG through `randombytes_adapter.c`. Frost-CC `shake128`/`shake256` call sites are routed by `common/sha3/fips202.c` to `pseudoXOF()` from the official `auxfunc.c`.
