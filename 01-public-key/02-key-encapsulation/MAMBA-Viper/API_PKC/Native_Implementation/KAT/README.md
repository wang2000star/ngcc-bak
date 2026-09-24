# Viper KEM Known Answer Tests (KAT)

This directory contains the KAT (Known Answer Test) values for all Viper KEM parameter sets, following the format of API_PKC provided by NGCC.

## Directory Structure

```
KAT/
├── Viper128/
│   ├── PQCkemKAT_1344.req
│   └── PQCkemKAT_1344.rsp
├── Viper192/
│   ├── PQCkemKAT_2080.req
│   └── PQCkemKAT_2080.rsp
├── Viper256/
│   ├── PQCkemKAT_2784.req
│   └── PQCkemKAT_2784.rsp
├── Viper384/
│   ├── PQCkemKAT_5152.req
│   └── PQCkemKAT_5152.rsp
└── Viper512/
    ├── PQCkemKAT_6656.req
    └── PQCkemKAT_6656.rsp
```

## File Naming Convention

Files are named according to the combined byte length of the public key and ciphertext (`pk + ct`):

| Parameter Set | PUBLICKEYBYTES | CIPHERTEXTBYTES | pk + ct | Filename |
|---------------|----------------|-----------------|---------|----------|
| Viper128 | 608 | 736 | 1344 | `PQCkemKAT_1344` |
| Viper192 | 992 | 1088 | 2080 | `PQCkemKAT_2080` |
| Viper256 | 1312 | 1472 | 2784 | `PQCkemKAT_2784` |
| Viper384 | 2496 | 2656 | 5152 | `PQCkemKAT_5152` |
| Viper512 | 3200 | 3456 | 6656 | `PQCkemKAT_6656` |

## File Format

- **Request files (`.req`)**: Contain the random seeds used for the test vectors.
- **Response files (`.rsp`)**: Contain the corresponding public key, secret key, ciphertext, and shared secret.

Each file contains 100 test vectors (count = 0 to 99).

## Generating KAT Files

To generate KAT files for all parameter sets, run the provided script from the repository root:

```bash
bash scripts/generate_kat.sh
```

Or manually build for each parameter set in the Reference Implementation directory:

```bash
cd Reference_Implementation_KEM
make clean && make LEVEL=128 kat
make clean && make LEVEL=192 kat
make clean && make LEVEL=256 kat
make clean && make LEVEL=384 kat
make clean && make LEVEL=512 kat
```

The generated `PQCkemKAT_{pk+ct}.req` and `PQCkemKAT_{pk+ct}.rsp` files will be created in the current directory. Copy them to the corresponding `KAT/Viper{LEVEL}/` subdirectories.

## Notes

- The KAT harness (`test/viper_kat_kem.c`) has been updated to automatically name files based on `CRYPTO_PUBLICKEYBYTES + CRYPTO_CIPHERTEXTBYTES`.
- The `Makefile` has been updated to clean files matching `PQCkemKAT_*.req` and `PQCkemKAT_*.rsp`.
- Both Reference Implementation and AVX Implementation KAT harnesses have been updated.
