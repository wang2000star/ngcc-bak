# LOOM-AKE — LoomKEX-512 (AVX2)

AVX2-optimized build. Same NGCC KEX API and KAT output as Reference. Public API: [api.h](api.h).

## Build (this instance)

From `Implementations/Optimized_Implementation` (requires AVX2, BMI2, POPCNT, FMA):

```bash
mkdir -p build && cd build
cmake .. && cmake --build . -j$(nproc)
./bin/KAT_KEX_LoomKEX-512
./bin/test_kex_state_LoomKEX-512
```

KAT always uses ICCS SM3-DRNG (`kem5_kat` / `sig5_kat`), independent of `LOOM_USE_SHAKE`.

See [../../../README.md](../../../README.md) for AVX2 kernel map and verification.
