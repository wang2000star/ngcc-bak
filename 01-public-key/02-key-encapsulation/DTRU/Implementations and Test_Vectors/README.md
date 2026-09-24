# PKCKEM-DTRU: Implementations and Test Vectors

## Project Layout

```
.
├── Implementations/
│   ├── Reference_Implementation/          # C reference implementation
│   │   ├── DTRU-648/
│   │   ├── DTRU-768/
│   │   ├── DTRU-1024/
│   │   ├── DTRU-1536/
│   │   ├── DTRU-2048/
│   │   ├── DTRU-Light/
│   │   └── DTRU-Prime/
│   ├── Optimized_Implementation/
│   │   ├── performance-optimized/         # AVX2 performance-optimized
│   │   │   ├── DTRU-648/
│   │   │   ├── DTRU-768/
│   │   │   ├── DTRU-1024/
│   │   │   ├── DTRU-1536/
│   │   │   ├── DTRU-2048/
│   │   │   ├── DTRU-Light/
│   │   │   └── DTRU-Prime/
│   │   └── resource-optimized/            # AVX2 resource-optimized
│   │       ├── DTRU-648/
│   │       ├── DTRU-768/
│   │       ├── DTRU-1024/
│   │       ├── DTRU-1536/
│   │       ├── DTRU-2048/
│   │       ├── DTRU-Light/
│   │       └── DTRU-Prime/
│   └── Additional_Implementation/
│       ├── KEM-DTRU-ARM-Optimized/        # ARM Cortex-M4 speed-optimized
│       │   └── crypto_kem/
│       │       ├── dtru-648/m4fspeed/
│       │       ├── dtru-768/m4fspeed/
│       │       ├── dtru-1024/m4fspeed/
│       │       ├── dtru-1536/m4fspeed/
│       │       ├── dtru-2048/m4fspeed/
│       │       ├── dtru-Light/m4fspeed/
│       │       └── dtru-Prime/m4fspeed/
│       ├── KEM-DTRU-ARM-Reference/        # ARM Cortex-M4 reference
│       │   └── crypto_kem/
│       │       ├── dtru-648/ref/
│       │       ├── dtru-768/ref/
│       │       ├── dtru-1024/ref/
│       │       ├── dtru-1536/ref/
│       │       ├── dtru-2048/ref/
│       │       ├── dtru-Light/ref/
│       │       └── dtru-Prime/ref/
│       └── KEM-DTRU-ARM-ResourceOpt/      # ARM Cortex-M4 resource-optimized
│           └── crypto_kem/
│               ├── dtru-648/m4fstack/
│               ├── dtru-768/m4fstack/
│               ├── dtru-1024/m4fstack/
│               ├── dtru-1536/m4fstack/
│               ├── dtru-2048/m4fstack/
│               ├── dtru-Light/m4fstack/
│               └── dtru-Prime/m4fstack/
├── Test_Vectors/                          # Standard KAT vectors (7 instances)
│   ├── KAT_KEM_DTRU-648.txt
│   ├── KAT_KEM_DTRU-768.txt
│   ├── KAT_KEM_DTRU-1024.txt
│   ├── KAT_KEM_DTRU-1536.txt
│   ├── KAT_KEM_DTRU-2048.txt
│   ├── KAT_KEM_DTRU-Light.txt
│   └── KAT_KEM_DTRU-Prime.txt
└── Test_Vectors_PACK_PK/                  # Extreme PK compression KAT vectors (5 instances)
    ├── KAT_KEM_DTRU-648.txt
    ├── KAT_KEM_DTRU-768.txt
    ├── KAT_KEM_DTRU-1024.txt
    ├── KAT_KEM_DTRU-1536.txt
    └── KAT_KEM_DTRU-2048.txt
```

## Public Key Compression

DTRU-648/768/1024/1536/2048 support extreme public-key compression via compile flag `-DPK_PACK_OPT=1`.
