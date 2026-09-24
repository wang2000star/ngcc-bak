# Wish Hash Function

Submission package for the **Wish** cryptographic hash family in response to NICCS call for next-generation commercial cryptographic hash algorithms, covering the 512-bit instance **Wish512** and the 1024-bit instance **Wish1024**.

## Repository structure

```
.
├── Implementations/                   Reference, optimized, and additional C implementations
├── Self_Assessment/                   Performance self-assessment (official benchmark tool + data + reports)
├── Test_Vector/                       Known-Answer-Test (KAT) vectors for both instances
├── Intellectual_Property_Statements/  Signed IP statements (Chinese + English)
├── Wish_Specifications_V1.pdf         Detailed specification of the Wish hash function
├── Basic_Algorithm_Information.pdf    Algorithm name and author information
└── Dependency_Information.txt         Build toolchain and required hardware features
```

Each top-level folder is detailed below.

## Wish_Specifications_V1.pdf

The complete algorithm text for the Wish hash function. It includes:

- Algorithm description
- Design rationale
- Security claims and analysis
- Performance evaluation
- Features

## Implementations/

The folder contain three types of implementations in C.
See `Implementations/README.md` for build instructions, `make` targets, and
compiler flags.

```
Implementations/
├── Reference_Implementation/         portable C99, source of the KAT vectors, per instance
│   ├── Wish512_reference/
│   └── Wish1024_reference/
├── Optimized_Implementation/         optimized for software performance, per instance and per architecture
│   ├── Wish512_x86_performance_optimized/
│   ├── Wish1024_x86_performance_optimized/
│   ├── Wish512_arm_performance_optimized/
│   └── Wish1024_arm_performance_optimized/
├── Additional_Implementation/        optimized for memory performance, per instance and per architecture
│   ├── Wish512_x86_resource_optimized/
│   ├── Wish1024_x86_resource_optimized/
│   ├── Wish512_arm_resource_optimized/
│   └── Wish1024_arm_resource_optimized/
└── README.md
```

Every implementation tree shares the same source layout:

```
<tree>/
├── CryptHash_AlgorithmInstance.c/.h  programming-interface instance (provided by NICCS)
├── drng.c/.h                         deterministic RNG (KAT input generation, provided by NICCS)
├── wish.c/.h                         core Wish implementation
├── KAT_CryptHash.c                   KAT driver (creates output/ at runtime, provided by NICCS)
└── Makefile
```

## Self_Assessment/

Performance evaluation using the `ngcc_bench` harness. See
`Self_Assessment/README.md` for build and run instructions.

```
Self_Assessment/
├── ngcc_bench/      official benchmark tool (from github.com/openHiTLS/ngcc_bench)
├── Data/
│   ├── x86/         x86-64 .so libraries + testwish.sh
│   └── arm/         AArch64 .so libraries + testwish.sh
├── Reports/
│   ├── x86/         generated x86-64 JSON reports (.json.en / .json.zh)
│   └── arm/         generated AArch64 JSON reports (.json.en / .json.zh)
└── README.md
```

## Test_Vector/

KAT vectors consumed by the benchmark harness, one folder per instance.

```
Test_Vector/
├── Wish512/         KAT_2_12, KAT_2_23, KAT_2_33, KAT_Loop
└── Wish1024/        KAT_2_12, KAT_2_23, KAT_2_33, KAT_Loop
```

## Intellectual_Property_Statements/

Signed intellectual-property statements from each submitter, in both languages.

```
Intellectual_Property_Statements/
├── 中文/            Chinese statements (PDF)
└── English/         English statements (PDF)
```
