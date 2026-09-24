# ATLAS — A Lattice-Based Digital Signature Scheme

This repository contains the submission package for **ATLAS**, a digital signature scheme based on the Module Learning With Rounding (MLWR) problem.

## Repository Contents

```
.
├── README                                                       # This file
├── basic_information.pdf                                        # Basic algorithm information
├── atlas.pdf                                                     # Main algorithm specification
├── Implementation/                                                # Reference and optimized implementation codes
├── Test_Vectors/                                                  # Known Answer Test (KAT) vectors
└── Supporting_Documentation/
    ├── ip_statements_submitters.pdf                               # IP statements (submitters)
    └── ip_statements_implementation_owners.pdf                    # IP statements (implementation owners)
```

## File and Directory Descriptions

| Path | Description |
|---|---|
| `./README` | This file. |
| `./basic_information.pdf` | Basic algorithm information. |
| `./atlas.pdf` | Main algorithm specification. |
| `./Implementation/` | Implementation codes (reference and optimized). |
| `./Test_Vectors/` | Test vectors. |
| `./Supporting_Documentation/ip_statements_submitters.pdf` | Intellectual property statements from the submitters. |
| `./Supporting_Documentation/ip_statements_implementation_owners.pdf` | Intellectual property statements from the implementation owners. |

## Implementation

The `Implementation/` directory contains both the reference and AVX2-optimized implementations of ATLAS, organized by security level (128, 192, 256, and 512 bits). See the `README` within the `Implementation/` directory for build instructions and further details.

## Test Vectors

The `Test_Vectors/` directory contains the Known Answer Test (KAT) files used to verify the correctness of the implementations across all supported security levels.

## Documentation

- **`basic_information.pdf`** provides a high-level overview of the algorithm and submission.
- **`atlas.pdf`** contains the complete algorithm specification, including design rationale, security analysis, and parameter selection.
- **`Supporting_Documentation/`** contains the required intellectual property statements from both the submitters and implementation owners.

