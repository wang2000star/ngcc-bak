# QingLuan v2 Protocol Reference — CROSS-RSDP (faithful transcription)

**Authoritative source:** *CROSS — Codes and Restricted Objects Signature Scheme*,
NIST PQC submission, Version 2 (round 2), spec v2.2 (July 2025).
Local copy: `C:\tmp\cross-spec-r2.pdf` (52 pp). Reference C params: `C:\tmp\cross_params.h`
(public domain, © the CROSS authors — see provenance note at end).

This document transcribes the **R-SDP** variant of CROSS (the variant QingLuan aligns to)
exactly as specified, then records the **adaptations** QingLuan makes (SM3 instead of
SHAKE; direct/"fast"-style `Path`/`Proof`; `H=[V|I]` layout). It is the contract the
implementation in `src/{rsdp,mpc,sign,verify,keygen}.c` must satisfy, and the basis for
the security argument (`security-argument.md`).

> **Why this exists.** The pre-v2 QingLuan protocol was *universally forgeable*: `mpc_commit`
> discarded the secret (`(void)e;`) and the verifier reconstructed the missing syndrome share
> as `s − Σ`, so every check was satisfiable from public data alone. CROSS-RSDP fixes this with
> a genuine proof of knowledge of a **restricted** `e` with `eH^⊤ = s`. See §8.

---

## 1. The R-SDP problem

Let `p` be prime, `g ∈ F_p^*` of multiplicative order `z` (so `z | p−1`), and
`E = ⟨g⟩ = {g^0, g^1, …, g^{z−1}}` the unique order-`z` subgroup of `F_p^*`.

> **R-SDP.** Given `H ∈ F_p^{(n−k)×n}` and `s ∈ F_p^{n−k}`, decide whether there exists
> `e ∈ E^n` with `e H^⊤ = s`. (NP-complete; CROSS uses `p=127, z=7, g=2`.)

Because `F_p^*` is cyclic, `E` is exactly `{x : x^z = 1}`. Restricted-ness of a coordinate
is therefore the algebraic constraint `e_i^z = 1`, equivalently `e_i = g^{η_i}` for some
exponent `η_i ∈ F_z = {0,…,z−1}`.

**CROSS-RSDP base field:** `p = 127`, `z = 7`, `g = 2`,
`E = {1,2,4,8,16,32,64}` (matches `restr.c` / `cross_params.h RESTR_G_TABLE`).

## 2. Symbols

| symbol | meaning |
|---|---|
| `λ` | security parameter (128/192/256 for cat 1/3/5) |
| `n, k` | code length, dimension; `r = n−k` redundancy |
| `t` | number of parallel rounds (Fiat–Shamir repetitions) |
| `w` | weight of the binary second-challenge vector `chall2 ∈ {0,1}^t` |
| `c` | domain constant `c = 2t − 1` |
| `Seed_sk` | `2λ`-bit secret-key seed (the entire `sk`) |
| `Seed_pk` | `2λ`-bit public seed → derives `H` |
| `s` | syndrome `eH^⊤ ∈ F_p^{n−k}`, part of `pk` |
| `Salt` | `2λ`-bit per-signature salt |
| `Seed[i]` | `λ`-bit round seed (round `i`) |
| Hash | `2λ`-bit output (collision resistance `λ`) |

CROSS cat-1 `(n,k)=(127,76)`; balanced `(t,w)=(256,215)`. Note `n` is **small** (the
hardness comes from the restriction `z=7`), unlike the pre-v2 `n=2347`.

## 3. Representations and the restricted group action

- **Exponent form** `η ∈ F_z^n` ↔ **restricted form** `e ∈ E^n` via `e_j = g^{η_j}`.
- **Star action** `⋆`: for `a, b` vectors, `(a ⋆ b)_j = a_j · b_j mod p` (component-wise mult).
  On `E^n`, `⋆` is the group operation; in exponents it is addition mod `z`.
- The transformation **`v`** with `v ⋆ e′ = e`: in exponents `v = η − η′ (mod z)`, then
  `v_j ← g^{v_j}`. Since `e, e′ ∈ E^n` and `E` is a group, `v ∈ E^n`.

## 4. CROSS-ID — the underlying 5-pass Σ-protocol (spec Fig. 2, R-SDP)

Secret `e ∈ E^n`; public `H, s = eH^⊤`.

```
Prover                                              Verifier
 Seed ←$ {0,1}^λ
 (e′, u′) ← CSPRNG(Seed)         # e′ ∈ E^n, u′ ∈ F_p^n
 v ← e ⋆ (e′)^{-1}              # exponents: v = η − η′ mod z
 u ← v ⋆ u′
 s′ ← u H^⊤
 cmt0 ← Hash(s′ | v)
 cmt1 ← Hash(u′ | e′)
                         cmt0, cmt1  ───────────────►
                         ◄───────────  chall1 ←$ F_p^*
 y ← u′ + chall1·e′            # in F_p^n
 digest_y ← Hash(y)
                         digest_y    ───────────────►
                         ◄───────────  chall2 ←$ {0,1}
 if chall2 = 0:  resp ← (y, v)
 if chall2 = 1:  resp ← Seed
                         resp        ───────────────►
                                       if chall2 = 0:
                                         y′ ← v ⋆ y
                                         s′ ← y′H^⊤ − chall1·s
                                         accept iff Hash(y)=digest_y
                                                AND Hash(s′|v)=cmt0
                                                AND v ∈ E^n
                                       if chall2 = 1:
                                         (e′,u′) ← CSPRNG(Seed)
                                         y ← u′ + chall1·e′
                                         accept iff Hash(y)=digest_y
                                                AND Hash(u′|e′)=cmt1
```

**Key identity:** `v ⋆ y = v ⋆ u′ + chall1·(v ⋆ e′) = u + chall1·e`, so
`(v⋆y)H^⊤ = uH^⊤ + chall1·eH^⊤ = s′ + chall1·s`, i.e. `s′ = (v⋆y)H^⊤ − chall1·s`.

**Soundness error per round** `p / (2(p−1)) ≈ 1/2`. Reduced to `2^{−λ}` by `t`
fixed-weight repetitions (see §6 forgery analysis in the spec, §3.2).

## 5. KeyGen (spec Algorithm 1, R-SDP)

```
1. Seed_sk ←$ {0,1}^{2λ}
2. (Seed_e, Seed_pk) ← CSPRNG(Seed_sk | 3t+1)          # each 2λ bits
3. V ← CSPRNG–F_p^{(n−k)×k}(Seed_pk | 3t+2);  H ← [V | I_{n−k}]
4. η ← CSPRNG–F_z^n(Seed_e | 3t+3);  e_j ← g^{η_j}      # e ∈ E^n
5. s ← e H^⊤
6. return sk = Seed_sk,  pk = (Seed_pk, s)
```

`H = [V | I_{n−k}]`: the **identity is on the right** (last `n−k` columns). With
`e = (e_A ‖ e_B)`, `e_A ∈ F_p^k`, `e_B ∈ F_p^{n−k}`: `s = V·e_A^⊤ + e_B`.

Sizes: `|sk| = 2λ` bits; `|pk| = 2λ + ⌈(n−k)·⌈log₂p⌉/8⌉·8` bits.

## 6. Sign (spec Algorithm 2, R-SDP)

```
 1. (η, H) ← ExpandSK(Seed_sk)                          # η ∈ F_z^n  (= secret exponents)
 2. Seed ←$ {0,1}^λ;  Salt ←$ {0,1}^{2λ}
 3. (Seed[1..t]) ← SeedLeaves(Seed | Salt)
 4. for i in 1..t:
 5.    (η′[i], u′[i]) ← CSPRNG–F_z^n × F_p^n (Seed[i] | Salt | i+c)
       v[i] ← η − η′[i]   (mod z)                        # exponent subtraction
 6.    v_E[i]_j ← g^{v[i]_j}                              # v_E ∈ E^n
 7.    e′_E[i]_j ← g^{η′[i]_j}                            # e′ in E^n (needed for u,y)
 8.    u[i] ← v_E[i] ⋆ u′[i]
 9.    s′[i] ← u[i] H^⊤
10.    cmt0[i] ← Hash(s′[i] | v[i] | Salt | i+c)         # v[i] = exponents (packed)
       cmt1[i] ← Hash(Seed[i] | Salt | i+c)
11. digest_cmt0 ← TreeRoot(cmt0[1..t])                   # QingLuan: Hash(cmt0[1]|…|cmt0[t])
12. digest_cmt1 ← Hash(cmt1[1..t])
13. digest_cmt  ← Hash(digest_cmt0 | digest_cmt1)
14. digest_Msg  ← Hash(Msg)                             # QingLuan: Hash(DOMAIN_MSG | Salt | pk_hash | Msg)
15. digest_chall1 ← Hash(digest_Msg | digest_cmt | Salt)
16. chall1 ← CSPRNG–(F_p^*)^t (digest_chall1 | t+c)
17. for i in 1..t:  y[i] ← u′[i] + chall1[i]·e′_E[i]     # in F_p^n
21. digest_chall2 ← Hash(y[1..t] | digest_chall1)
22. chall2 ← CSPRNG–B(t,w) (digest_chall2 | t+c+1)       # weight-w binary string
23. Proof ← TreeProof(cmt0[1..t] | chall2)               # QingLuan: {cmt0[i] : chall2[i]=1}
24. Path  ← SeedPath(Seed | Salt | chall2)               # QingLuan: {Seed[i] : chall2[i]=1}
25. for i in 1..t with chall2[i]=0:  resp0[i] ← (y[i], v[i]);  resp1[i] ← cmt1[i]
28. Sgn ← (Salt, digest_cmt, digest_chall2, Path, Proof, resp)
```

**`chall2[i]` convention:** `1` ⇒ reveal `Seed[i]` (cmt1 branch — proves `e′` restricted),
`0` ⇒ reveal `(y[i], v[i], cmt1[i])` (cmt0 branch — proves syndrome). Exactly `w` rounds
are type-1.

## 7. Verify (spec Algorithm 3, R-SDP)

```
 1. V ← CSPRNG–F_p^{(n−k)×k}(Seed_pk | 3t+2);  H ← [V | I_{n−k}]
 4. digest_Msg ← Hash(Msg)                               # QingLuan: Hash(DOMAIN_MSG | Salt | pk_hash | Msg)
 5. digest_chall1 ← Hash(digest_Msg | digest_cmt | Salt)
 6. chall1 ← CSPRNG–(F_p^*)^t (digest_chall1 | t+c)
 7. chall2 ← CSPRNG–B(t,w) (digest_chall2 | t+c+1)
 8. (Seed[i] : chall2[i]=1) ← RebuildLeaves(Path | chall2 | Salt)
 9. for i in 1..t:
10.    if chall2[i] = 1:
11.       cmt1[i] ← Hash(Seed[i] | Salt | i+c)
12.       (η′[i], u′[i]) ← CSPRNG–F_z^n × F_p^n (Seed[i] | Salt | i+c)
13.       e′_E[i]_j ← g^{η′[i]_j}
14.       y[i] ← u′[i] + chall1[i]·e′_E[i]
          # cmt0[i] comes from Proof
15.    if chall2[i] = 0:
16.       cmt1[i] ← resp1[i]
17.       (y[i], v[i]) ← resp0[i];   CHECK v[i] ∈ F_z^n     # restricted-ness check!
18.       v_E[i]_j ← g^{v[i]_j}
19.       y′[i] ← v_E[i] ⋆ y[i]
20.       s′[i] ← y′[i] H^⊤ − chall1[i]·s
21.       cmt0[i] ← Hash(s′[i] | v[i] | Salt | i+c)
22. digest_cmt0 ← RecomputeRoot(cmt0 | Proof | chall2)   # QingLuan: Hash over t cmt0 (recomp + Proof)
23. digest_cmt1 ← Hash(cmt1[1..t])
24. digest_cmt′  ← Hash(digest_cmt0 | digest_cmt1)
25. digest_chall2′ ← Hash(y[1..t] | digest_chall1)
26. accept iff digest_cmt = digest_cmt′ AND digest_chall2 = digest_chall2′
```

The line-17 check `v[i] ∈ F_z^n` (every exponent `< z`) is what forces the prover's
`v` to be genuinely restricted; combined with line 16–17 of the cmt1 branch (where `e′`
is reconstructed from a seed and is restricted by construction), it pins down a restricted
witness. **This check, and the secret-dependent `v = η − η′`, are exactly what the pre-v2
code lacked.**

## 8. Why this kills the universal forgery

A forger with only `pk = (Seed_pk, s)` cannot produce a transcript that passes both
challenge branches for the same `cmt0,cmt1` unless they know a restricted `e` with
`eH^⊤=s`. Formally (special soundness): from two accepting transcripts that share
`(cmt0,cmt1,chall1)` but differ in `chall2`:
- `chall2=1` reveals `Seed ⇒ (e′ restricted, u′)` with `y = u′ + chall1·e′`.
- `chall2=0` reveals `(y, v)` with `v` restricted and `(v⋆y)H^⊤ = s′ + chall1·s`.

Then `e := v ⋆ e′ ∈ E^n` (product of restricted = restricted) and
`eH^⊤ = (v⋆e′)H^⊤`; using `v⋆y = u + chall1·e` and `y=u′+chall1 e′` one extracts a
restricted solution to `eH^⊤=s`. Knowledge of such `e` is R-SDP-hard ⇒ no PPT forger.
Per-round cheating probability `≈ p/2(p−1)`; `t` fixed-weight rounds drive total
forgery probability below `2^{−λ}` (spec §3.2, accounting for the fixed-weight attack).

## 9. Auxiliary primitives (spec §2.3, §5)

- **CSPRNG–F_z:** rejection-sample `⌈log₂z⌉`-bit ints, accept `< z`. (`z=7` ⇒ 3 bits.)
- **CSPRNG–F_p:** rejection-sample `⌈log₂p⌉`-bit ints, accept `< p`. (`p=127` ⇒ 7 bits.)
- **CSPRNG–(F_p^*)^t:** sample in `{0,…,p−2}`, output `+1` ⇒ `{1,…,p−1}`.
- **CSPRNG–B(t,w):** Fisher–Yates shuffle of `1^w 0^{t−w}`; shuffle indices by rejection
  sampling. Yields a uniform weight-`w` binary string.
- **ExpandSK(Seed_sk):** KeyGen steps 2–4 without `s`; returns `(η, H)`.
- **Packing (R-SDP, little-endian bit-packing):** `s`,`y`: `⌈n·7/8⌉` resp `⌈(n−k)·7/8⌉`
  bytes (7 bits/elt); `v`: `⌈n·3/8⌉` bytes (3 bits/elt). Pad with 0 to byte boundary and
  **check padding on unpack**.
- **Domain separation (spec):** a 16-bit LE integer is appended to each Hash/CSPRNG input;
  MSB=1 ⇒ Hash, MSB=0 ⇒ CSPRNG; low 15 bits separate instances.

## 10. QingLuan adaptations vs. the spec (and their justification)

1. **Hash/CSPRNG = SM3, not SHAKE.** QingLuan is an SM3-based scheme (GB/T 32905). We use
   the pipe-widened SM3 hash (`hash.h`, `2λ`-bit output) for `Hash` and the SM3
   counter-mode XOF (`xof_*`) for `CSPRNG`. Domain separation uses QingLuan's existing
   1-byte `DOMAIN_*` tags plus the per-round little-endian `i+c` constant, instead of the
   15-bit SHAKE scheme. *Consequence:* the byte stream differs from CROSS, so **official
   CROSS KATs will not match** — only the protocol structure and security argument are
   shared. Byte-exact CROSS-KAT validation is a separate follow-up requiring `CROSS.c`.
2. **`Path`/`Proof` use the "fast"-style direct form.** We send the `w` revealed seeds
   `{Seed[i] : chall2[i]=1}` and the `w` commitments `{cmt0[i] : chall2[i]=1}` directly
   (this is exactly the fast-version behaviour the spec describes — "`Path` consists of
   exactly `w` leaves"). Round seeds are generated as **independent** per-index expansions
   `Seed[i] = CSPRNG(Seed | Salt | i)` so the unrevealed `t−w` seeds remain hidden without
   a GGM tree. `TreeRoot`/`RecomputeRoot` collapse to `digest_cmt0 = Hash(cmt0[1]|…|cmt0[t])`.
   Seed-tree / Merkle-tree compression (smaller signatures for `w≈t`) is a future
   optimization; it changes only signature *size*, never soundness.
3. **`H = [V | I_{n−k}]`** (identity on the right), per the spec — replacing the pre-v2
   `[I | C]` layout.
4. **Commitment input order** is fixed and identical on signer and verifier:
   `cmt0 = Hash(DOMAIN_COMMIT | s′ | v_exp | Salt | i+c)`,
   `cmt1 = Hash(DOMAIN_COMMIT | Seed[i] | Salt | i+c)`, all field vectors bit-packed. `v` is
   hashed in **exponent (F_z) packed** form (what is transmitted and range-checked).
5. **Salted, pk-bound message digest** `digest_Msg = Hash(DOMAIN_MSG | Salt | pk_hash | Msg)`,
   `pk_hash = Hash(Seed_pk | pack(s))` — strengthening over the spec's bare `Hash(Msg)`:
   - the per-signature `Salt` is the design's randomizer `r` and makes message binding rely
     on (multi-target) **eTCR / 2nd-preimage** rather than plain collision resistance. This is
     **mandatory** for QingLuan because `H_w` is multi-pipe SM3, whose collision resistance is
     capped at ~`2^128` by Joux *regardless of width*; an unsalted `Hash(Msg)` would let a
     `~2^128` message collision transfer a signature and cap EUF-CMA at `2^128`, breaking
     the 256/384/512 levels. CROSS escapes this only because SHAKE (a sponge) has full
     `2^λ` collision resistance at its `2λ`-bit output. See `security-argument.md` §3.
   - `pk_hash` adds BUFF-style public-key binding (message–key binding / exclusive ownership).

## 11. Toy parameters for TDD (`QL_TOY`)

Structurally valid, tiny for speed (NOT secure): `p=127, z=7, g=2`, `n=12, k=6` (`r=6`),
`t=8`, `w=5`, `c=2t−1=15`, `λ=128`, `Seed=16 B`, `Salt=32 B`, Hash=32 B. Per-round
soundness `≈1/2`; `t=8` is enough to exercise both `chall2` branches in tests, not for
security.

## 12. Provenance / license

The CROSS reference materials in `C:\tmp` (`cross-spec-r2.pdf`, `cross_params.h`, …) are the
authors' NIST submission, placed by them **in the public domain** (see header of
`cross_params.h`). QingLuan re-implements the *protocol* on an independent SM3 code base; no
CROSS source is copied. Attribution to the CROSS authors (Barenghi, Gianvecchio, Karl,
Pelosi, Schupp; Baldi, Bitzer, Pavoni, Santini, Wachter-Zeh, Weger) is retained here and in
`security-argument.md`.
