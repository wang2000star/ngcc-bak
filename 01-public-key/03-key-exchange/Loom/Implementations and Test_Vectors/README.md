# LOOM-AKE

Authenticated key exchange (LoomKEX) combining internal **Weaver** KEM and **Shuttle** signature in a four-pass ICCS-style handshake.

Submitted algorithm instances: `LoomKEX-128`, `LoomKEX-256`, `LoomKEX-512`.

## Repository layout

```
loom-ake/
├── Implementations/
│   ├── Reference_Implementation/    # Portable ISO C99 reference
│   ├── Optimized_Implementation/    # AVX2-optimized (x86_64)
│   ├── Additional_Implementation/   # Reserved (no third tier yet)
│   └── README.md                    # Directory map and file descriptions
└── Test_Vectors/
    ├── KAT_KEX_LoomKEX-128.txt
    ├── KAT_KEX_LoomKEX-256.txt
    └── KAT_KEX_LoomKEX-512.txt
```

See [Implementations/README.md](Implementations/README.md) for build instructions, parameter tables, and per-file descriptions.

## Quick build

```bash
# Reference (portable)
cd Implementations/Reference_Implementation
mkdir -p build && cd build && cmake .. && cmake --build . -j$(nproc)
cmake --build . --target generate_kat

# Optimized (AVX2; requires -mavx2 -mbmi2 -mpopcnt -mfma)
cd Implementations/Optimized_Implementation
mkdir -p build && cd build && cmake .. && cmake --build . -j$(nproc)
cmake --build . --target generate_kat
```

KAT executables: `build/bin/KAT_KEX_LoomKEX-{128,256,512}`. Success: `[Debug**] all loop SUCCESS!`

## Parameter sets

| Instance | LOOM_MODE | Weaver (n, k, q) | Shuttle | SS (B) |
|----------|-----------|------------------|---------|--------|
| LoomKEX-128 | 1 | (128, 5, 3329) | SHUTTLE-128 | 16 |
| LoomKEX-256 | 3 | (256, 4, 7681) | SHUTTLE-256 | 32 |
| LoomKEX-512 | 5 | (512, 4, 7681) | SHUTTLE-512 | 64 |

Full wire sizes and message layout: [Implementations/README.md](Implementations/README.md).

## API

NGCC KEX adapter: `loom/KEX_LoomKEX-<set>.{c,h}` per instance. Internal protocol API: `loom/api.h` (`crypto_loom_*`).
