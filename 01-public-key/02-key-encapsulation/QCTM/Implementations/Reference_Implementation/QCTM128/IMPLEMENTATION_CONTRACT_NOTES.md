# QCTM128 compressed-Gamma implementation notes

This directory is an independent QCTM128 implementation experiment based on
`QCTM128_contract_v01`.

## Object lengths

This version serializes the mathematical private decoding structure using the
formula-level compressed representation:

```text
GammaPrime = g || L_prime
skKEM = GammaPrime || pk_copy || s
```

For QCTM128:

```text
m = 18
n = 10070
ell = 19
t0 = 15
t = 285
u = m*(t-1)+1 = 5113
r0 = 2
right_width = n-u+r0 = 4959
psi_T1_rows = (u-r0)/ell = 269
T2_rows = 2

PK_BYTES = 167987
GAMMA_BYTES = ceil(((n+t)*m)/8) = 23299
S_BYTES = ceil(n/8) = 1259
API_SK_BYTES = GAMMA_BYTES + PK_BYTES + S_BYTES = 192545
CT_BYTES = 640
SS_BYTES = 32
```

`sizes.h` contains compile-time assertions for these QCTM128 constants.

## GammaPrime serialization

`GammaPrime` stores:

```text
g_0, ..., g_{t-1}, L_prime[0], ..., L_prime[n-1]
```

The monic coefficient of `x^t` is not serialized. `eta` is not serialized.
During decapsulation, `eta` is recovered as:

```text
eta = inverse(g_{t-1})
```

Field elements are written as their polynomial coefficients
`u_0, ..., u_{m-1}` and packed into bytes with MSB-first bit positions inside
the compressed `GammaPrime` stream.

## Decapsulation path

`kem_dec(sk, ct)` depends only on the provided `sk` and `ct`. The API adapter no
longer caches `last_pk`, `last_sk`, or a prior key-generation state.

Decapsulation parses:

```text
GammaPrime || pk_copy || s
```

It uses `pk_copy` to rebuild the public matrix information needed by the
decoder. The secret key does not store:

```text
decode_map, Hhat_T, H, D, Q, tau, expanded T1, original L
```

The decode map is rebuilt transiently from `GammaPrime` and `pk_copy`.

## Verified commands

Run from this directory:

```text
make -B roundtrip
make verify-decode-map
make -B api-pkc-kat
./QCTM128_API_PKC_KAT
```

Observed results:

```text
roundtrip: keypair=ok enc=ok dec=ok ss=ok
verify-decode-map: keypair=ok enc=ok dec=ok ss=ok
```

Official API/KAT output:

```text
Test_Vectors/KAT_KEM_QCTM128.txt
lines: 120
Counts: 0..9
PK_Len: 167987
SK_Len: 192545
CT_Len: 640
SS_Len: 32
SHA256: c424c84ffc28a3284175c6f910ee48478c010657f336f91ca9c16e0ca957d86f
```
