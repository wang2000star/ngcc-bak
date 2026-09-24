# LOOM-AKE — LoomKEX-128 (AVX2)

AVX2-optimized build. Same NGCC KEX API and KAT output as Reference. Public API: [api.h](api.h).

## Build (this instance)

From `Implementations/Optimized_Implementation` (requires AVX2, BMI2, POPCNT, FMA):

```bash
mkdir -p build && cd build
cmake .. && cmake --build . -j$(nproc)
./bin/KAT_KEX_LoomKEX-128
./bin/test_kex_state_LoomKEX-128
```

KAT always uses ICCS SM3-DRNG (`kem1_kat` / `sig1_kat`), independent of `LOOM_USE_SHAKE`.

See [../../../README.md](../../../README.md) for AVX2 kernel map and verification.
