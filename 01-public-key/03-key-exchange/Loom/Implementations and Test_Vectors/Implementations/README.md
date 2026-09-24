# LoomKEX Implementations

LOOM authenticated key exchange (Loom-AKE) combines an internal **Weaver** KEM and an internal **Shuttle** signature in a four-pass ICCS-style handshake. The submitted algorithm instances are the KEX wrappers (`LoomKEX-128`, `LoomKEX-256`, `LoomKEX-512`). Only **KEX** Known-Answer Tests (KAT) are required—no standalone `KAT_KEM` or `KAT_SIG` vectors.

## Directory Structure

```
Implementations/
├── Reference_Implementation/          # Portable reference implementation (ISO C99)
│   ├── LoomKEX-128/                   # LOOM_MODE=1, 128-bit classical security
│   ├── LoomKEX-256/                   # LOOM_MODE=3, 256-bit classical security
│   ├── LoomKEX-512/                   # LOOM_MODE=5, 512-bit classical security
│   └── CMakeLists.txt                 # Build configuration for reference
├── Optimized_Implementation/          # AVX2-optimized implementation (x86_64)
│   ├── LoomKEX-128/                   # AVX2 optimized, 128-bit classical security
│   ├── LoomKEX-256/                   # AVX2 optimized, 256-bit classical security
│   ├── LoomKEX-512/                   # AVX2 optimized, 512-bit classical security
│   └── CMakeLists.txt                 # Build configuration for optimized
├── Additional_Implementation/         # Reserved for optional third-tier ports (empty)
│   └── README.md
└── README.md                          # This file
```

Each `LoomKEX-<set>/` folder is self-contained with three sub-trees:

```
LoomKEX-<set>/
├── loom/          # LOOM-AKE protocol core + ICCS KEX adapter
├── kem/           # Weaver KEM sources
└── sig/           # Shuttle signature sources
```

Official reference vectors live at the **repository root**:

```
Test_Vectors/
├── KAT_KEX_LoomKEX-128.txt
├── KAT_KEX_LoomKEX-256.txt
└── KAT_KEX_LoomKEX-512.txt
```

## Building the Implementations

### Reference Implementation (Portable, ISO C99)

Run from the repository root (or prefix paths with `../..` if you are already inside `Implementations/`):

```bash
cd Implementations/Reference_Implementation
mkdir -p build && cd build
cmake ..
cmake --build . -j$(nproc)
cmake --build . --target generate_kat
```

Executables are written to `build/bin/`:

- `KAT_KEX_LoomKEX-128`
- `KAT_KEX_LoomKEX-256`
- `KAT_KEX_LoomKEX-512`

Each run prints `all loop SUCCESS!` and writes `output/KAT_KEX_LoomKEX-<set>.txt` under the **current working directory** (`build/bin/` when using `generate_kat`).

Equivalent using Makefiles:

```bash
make -j$(nproc)
make generate_kat
```

### Optimized Implementation (AVX2)

Requires a 64-bit x86 CPU with AVX2, BMI2, POPCNT, and FMA.

```bash
cd Implementations/Optimized_Implementation
mkdir -p build && cd build
cmake ..
cmake --build . -j$(nproc)
cmake --build . --target generate_kat
```

**Optional CMake flag:**

```bash
cmake -DLOOM_USE_SHAKE=OFF ..
```

When `LOOM_USE_SHAKE=ON` (default), the optimized `kem`/`sig` libraries use internal SHAKE-256 for performance. **`KAT_KEX_*` always uses the ICCS SM3-DRNG path** (`drng.c` + `auxfunc.c` + `symmetric-iccs.c`) and links `kem*_kat` / `sig*_kat`, independent of this flag.

### Verify Test Vectors Match

Paths in this section are **relative to the repository root** (the directory that contains both `Implementations/` and `Test_Vectors/`). Change to that directory first—do not run the loop from inside `build/` or from `Implementations/` alone.

```bash
cd /path/to/LOOM          # repository root; adjust to your clone
# Or, if your shell is already in Implementations/:  cd ..

for SET in 128 256 512; do
  OUT="Implementations/Reference_Implementation/build/bin/output/KAT_KEX_LoomKEX-${SET}.txt"
  REF="Test_Vectors/KAT_KEX_LoomKEX-${SET}.txt"
  if [[ ! -f "$OUT" || ! -f "$REF" ]]; then
    echo "LoomKEX-${SET}: FAIL (missing file — build Reference tier and run generate_kat first)"
    continue
  fi
  if diff -q \
       <(grep -E '^(Count|Seed|PK|SK|M[1-4]|SS|Pass_Num)' "$OUT") \
       <(grep -E '^(Count|Seed|PK|SK|M[1-4]|SS|Pass_Num)' "$REF") \
       >/dev/null 2>&1; then
    echo "LoomKEX-${SET}: PASS (protocol fields match Test_Vectors)"
  else
    echo "LoomKEX-${SET}: FAIL (files differ)"
  fi
done
```

Expected output (only after `generate_kat` has produced all three output files):

```
LoomKEX-128: PASS (protocol fields match Test_Vectors)
LoomKEX-256: PASS (protocol fields match Test_Vectors)
LoomKEX-512: PASS (protocol fields match Test_Vectors)
```

**Note:** KAT state fields (`Init_Sta`, `Pass*_Sta`, …) are serialized as fixed-size LSTA byte strings (not host pointers). Protocol fields (`PK*`, `SK*`, `M1`–`M4`, `SS`, …) must match exactly. If both input files are missing, an unchecked loop would falsely report PASS on empty `grep` output—the existence check above prevents that.

Cross-check Reference vs Optimized (same filtered fields; **also from repository root**):

```bash
cd /path/to/LOOM          # repository root

REF=Implementations/Reference_Implementation/build/bin/output
OPT=Implementations/Optimized_Implementation/build/bin/output

for SET in 128 256 512; do
  RF="${REF}/KAT_KEX_LoomKEX-${SET}.txt"
  OF="${OPT}/KAT_KEX_LoomKEX-${SET}.txt"
  if [[ ! -f "$RF" || ! -f "$OF" ]]; then
    echo "Ref vs Opt ${SET}: FAIL (missing file — run generate_kat in both tiers)"
    continue
  fi
  if diff -q \
    <(grep -E '^(Count|Seed|PK|SK|M[1-4]|SS|Pass_Num)' "$RF") \
    <(grep -E '^(Count|Seed|PK|SK|M[1-4]|SS|Pass_Num)' "$OF") \
    >/dev/null 2>&1; then
    echo "Ref vs Opt ${SET}: PASS"
  else
    echo "Ref vs Opt ${SET}: FAIL"
  fi
done
```

## File Descriptions

### Files Provided by ICCS (SHALL NOT be modified)

| File | Description |
|------|-------------|
| `drng.c` / `drng.h` | Deterministic Random Number Generator (SM3-DRBG) |
| `auxfunc.c` / `auxfunc.h` | Auxiliary cryptographic functions (SM3 hash, pseudoHash, pseudoXOF) |
| `KAT_KEX.c` | Official KAT generation program for multi-pass KEX |

### LoomKEX Algorithm-Specific Files (under `loom/`)

| File | Description |
|------|-------------|
| `KEX_LoomKEX-<set>.{c,h}` | NGCC programming-interface adapter; sets `ALGORITHM_INSTANCE`, party ID strings, and `randombytes()` override |
| `api.h` | Internal LOOM-AKE API (`crypto_loom_*`) |
| `params.h` | LOOM-AKE wire sizes, MAC/nonce lengths, message buffer sizes |
| `kemparams.h` / `sigparams.h` | Weaver / Shuttle compile-time parameters |
| `loom.c` / `loom_loc.h` | Four-pass handshake state machine |
| `state_serialize.c` / `state_serialize.h` | LSTA (Loom State Transfer Archive) pack/unpack for KEX state blobs in KAT output |
| `test_kex_state.c` | Round-trip test for LSTA serialization (build target `test_kex_state`) |
| `prf_mac.c` / `prf_mac.h` | PRF key derivation and MAC computation |
| `symmetric.h` / `symmetric-iccs.c` | Hash/XOF interface using ICCS `auxfunc` (KAT path) |
| `fips202.{c,h}`, `rng.{c,h}`, `symmetric-shake.c` | Optional internal SHAKE path (Optimized performance libs) |
| `CMakeLists.txt` | Per-instance build configuration |

### Weaver KEM Sources (under `kem/`)

| File | Description |
|------|-------------|
| `indcpa.c`, `kem_cpaf.c` | IND-CPA PKE and CCA KEM wrapper (CPAF tag) |
| `ntt.c`, `cbd.c`, `poly*.c`, `msgenc.c`, `reduce.c`, `verify.c` | Core KEM arithmetic |
| `invq_table_d{9,10,11}.h` | Precomputed inverse-mod-q tables |

### Shuttle Signature Sources (under `sig/`)

| File | Description |
|------|-------------|
| `sign.c`, `polyvec.c`, `sampler.c`, `irs.c`, `rounding.c`, … | SHUTTLE signing and verification |
| `SIG_AlgorithmInstance.{c,h}` | Internal SIG adapter (not a separate submitted algorithm) |
| `ntt/<qset>/ntt_ref.{c,h}` | Per-set scalar NTT reference |
| `test/prof.h`, `test/speed.txt`, `test/profiling.txt` | Profiling stubs and measured snapshots |

## Algorithm Parameter Sets

Sizes below come from `loom/params.h` at compile time (`LOOM_MODE` 1 / 3 / 5).

| Instance | LOOM_MODE | Weaver (n, k, q) | Shuttle | Long-term PK (B) | Long-term SK (B) | M1 (B) | M2 (B) | M3 / M4 (B) | Total msgs (B) | SS (B) |
|----------|-----------|------------------|---------|------------------|------------------|--------|--------|-------------|--------------|--------|
| LoomKEX-128 | 1 | (128, 5, 3329) | SHUTTLE-128 | 1264 | 2288 | 792 | 776 | 1235 | 4038 | 16 |
| LoomKEX-256 | 3 | (256, 4, 7681) | SHUTTLE-256 | 1952 | 3680 | 1352 | 1384 | 2485 | 7706 | 32 |
| LoomKEX-512 | 5 | (512, 4, 7681) | SHUTTLE-512 | 3648 | 7104 | 2952 | 3016 | 5101 | 16170 | 64 |

**Message layout (passes 1–4):**

| Pass | Wire message | Payload |
|------|--------------|---------|
| 1 | M1 (`msg_{I,1}`) | SPI fragment, ephemeral Weaver `pk`, initiator nonce `N_I` |
| 2 | M2 (`msg_{R,1}`) | Full SPI, ephemeral Weaver `ct`, responder nonce `N_R` |
| 3 | M3 (`msg_{I,2}`) | Identity, Shuttle signature, PRF-MAC tag |
| 4 | M4 (`msg_{R,2}`) | Identity, Shuttle signature, PRF-MAC tag |

Long-term Shuttle public keys are **not** embedded in M1–M4; peers supply them through the NGCC `kex_*` credential arguments.

**Ephemeral Weaver payload sizes (inside M1 + M2):**

| Instance | `pk_KEM` (B) | `ct_KEM` (B) |
|----------|--------------|--------------|
| LoomKEX-128 | 752 | 736 |
| LoomKEX-256 | 1312 | 1344 |
| LoomKEX-512 | 2880 | 2944 |

## Implementation Details

### Common Core (Both Reference and Optimized)

The LOOM-AKE protocol core lives in `loom/`. Cryptographic primitives are composed from:

- **Weaver KEM** (`kem/`) — ephemeral key transport in passes 1–2
- **Shuttle SIG** (`sig/`) — mutual authentication in passes 3–4
- **PRF/MAC** (`prf_mac.c`) — session keys and confirmation tags

### Reference Implementation

**Purpose:** Portable, platform-independent correctness reference and KAT oracle.

**Characteristics:**

- ISO C99, no architecture-specific intrinsics or assembly in the hot path
- All KAT randomness from ICCS SM3-DRBG via `drng_algorithm`
- Hash/XOF through ICCS `auxfunc` (`symmetric-iccs.c`)
- `KAT_KEX_*` links `kem*_kat` + `sig*_kat` (ICCS only); optional `-DLOOM_USE_SHAKE=ON` applies only to `kem*`/`sig*` performance libs
- Suitable for embedded targets and formal review

### Optimized Implementation (AVX2)

**Purpose:** High-performance x86_64 build with the same NGCC KEX API and bit-exact KAT output.

**Characteristics:**

- AVX2 SIMD for Weaver NTT, matrix expansion, compression, CBD; Shuttle NTT and XOF batching
- `LOOM_AVX2` compile definition; flags: `-O3 -mavx2 -mbmi2 -mpopcnt -mfma`
- KAT executables link `kem*_kat` + `sig*_kat` with ICCS symmetric layer (same bytes as Reference)
- Performance libraries may use internal SHAKE when `LOOM_USE_SHAKE=ON`

**AVX2 kernels by instance (under `kem/avx2/` and `sig/`):**

| Instance | Weaver NTT | Matrix gen | Compress | Shuttle NTT |
|----------|------------|------------|----------|-------------|
| LoomKEX-128 | `ntt3329_avx128.c` | `indcpa_gen_matrix_avx128.c` | `poly_compress9.c` (9-bit pk) | `q15361n256/ntt.S` |
| LoomKEX-256 | `ntt7681_avx.c` | `indcpa_gen_matrix_avx7681.c` | `poly_compress_avx.c` (10-bit pk) | `q61441n512/ntt.S` |
| LoomKEX-512 | `ntt7681_avx.c` | `indcpa_gen_matrix_avx7681.c` | `poly_compress_avx.c` (11-bit pk) | `q59393n1024/ntt.S` |

Shared infrastructure: `kem/keccak4x/` (SHAKE×4), `sig/fips202x4.c`, `sig/symmetric_avx2.c`.

## Randomness and Reproducibility

### SM3-DRBG (KAT path)

All KAT operations use the ICCS-provided SM3-DRBG. Each `KEX_LoomKEX-<set>.c` overrides:

```c
int randombytes(unsigned char *x, unsigned long long xlen) {
    return get_random_number(&drng_algorithm, x, xlen * 8);
}
```

Given the same DRNG seed, Reference and Optimized tiers produce identical protocol fields in the KAT files.

### Party identities in KAT

`KEX_LoomKEX-<set>.c` sets fixed ID strings `"initiator"` and `"responder"` (length ≤ `LOOM_MAX_IDBYTES` = 32) passed to `crypto_loom_initialize_state`.

## Test Vector Verification

KAT files follow the NGCC multi-pass KEX format generated by `KAT_KEX.c`:

- **10 deterministic seeds** per parameter set (`Count = 0 … 9`)
- Fields per count: long-term keys (`PKa`, `PKb`, `SKa`, `SKb`), handshake messages (`M1`–`M4`), shared secret (`SS`), pass metadata

Console success indicator: `[Debug**] all loop SUCCESS!`
