# Neulaser Reference Implementation Performance Evaluation Package

This directory is organized according to Section 1.4, Material Preparation, of
the x86 architecture implementation self-assessment guideline.

| Required material | Location |
|---|---|
| Algorithm source code | `Algorithm_Source_Code/` |
| Self-assessment code and data | `Self_Assessment_Code_and_Data/` |
| Self-assessment report | `Self_Assessment_Report.pdf` |
| Dependency information | `Dependency_Information.md` |

## Reproduce the Performance Test

From an MSYS2 or Linux shell:

```sh
cd "performance evaluation/Reference_Implementation/Self_Assessment_Code_and_Data"
./run_performance.sh
```

The script selects `mingw32-make` when it is available, otherwise it uses
`make`.  It rebuilds the benchmark binaries and writes raw benchmark output to
`performance_results_raw.txt`.  The submitted reference table is also recorded
in `performance_results_reference.csv`.
