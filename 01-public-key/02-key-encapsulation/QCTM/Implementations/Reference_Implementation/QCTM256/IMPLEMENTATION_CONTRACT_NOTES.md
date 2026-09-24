# QCTM256 compressed GammaPrime implementation notes

This directory is a new implementation variant derived from the eta-from-bits
QCTM256 code path. It is intended to match the official API/KAT interface while
keeping the mathematical private decoding structure compact.

## Serialization contract

- `GammaPrime = g || L_prime`
- `skKEM = GammaPrime || pk_copy || s`
- `pk = psi_T1 || T2`
- `ct = C`
- `ss = 32 bytes`

The API secret key includes `pk_copy` because the official `kem_dec(sk, ct)`
entry point does not pass `pk`. The `pk_copy` is not part of the mathematical
private decoding structure.

The secret key must not serialize transient decoding data:

- no `decode_map`
- no `Hhat_T`
- no expanded public matrix `H`
- no transform matrix `D`
- no row-operation matrix `Q`
- no column permutation `tau`
- no original support `L`

## Fixed QCTM256 lengths

- `PK_BYTES = 595662`
- `GAMMA_BYTES = 43905`
- `S_BYTES = 2375`
- `SECRETKEY_BYTES = 641942`
- `CT_BYTES = 1153`
- `SS_BYTES = 32`

These are enforced by compile-time assertions in `sizes.h`.

## Verified status

Verified locally:

- `make -B roundtrip`
- `make verify-decode-map`
- `make -B api-pkc-kat`
- official API/KAT executable

Current final KAT:

- `Test_Vectors/KAT_KEM_QCTM256.txt`
- line count: 120
- file size: about 24 MB
- SHA256: `05494a6b95b087a2f250db53c8e9d588e0e4b0c1c6a3b3537b8f2cb91936a1c3`

All 10 counts use:

- `PK_Len = 595662`
- `SK_Len = 641942`
- `CT_Len = 1153`
- `SS_Len = 32`
