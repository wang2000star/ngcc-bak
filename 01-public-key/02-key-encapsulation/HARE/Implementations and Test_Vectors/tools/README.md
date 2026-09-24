# HARE tools

The `tools/` directory contains support code for reproducible generation,
package gates, and server validation.  These tools are not part of the KEM
runtime API.

```text
gates/        hard checks used before or during validation
generators/   deterministic generators for checked-in public artifacts
server/       x86/ARM fresh-server validation runner
arm_sve/      ARM feature probe helper
```

## Gates

```text
gates/check_manifest.sh
  Verifies the exact source file set and SHA-256 hashes recorded in MANIFEST.tsv.

gates/check_generated_artifacts.sh
  Regenerates public derived artifacts in check mode and verifies that the
  committed files match.

gates/check_parameter_manifest.py
  Verifies parameter formulas, API sizes, primitive-prime n values, and instance
  directory coverage.

gates/audit_gf2x_instructions.py
  Hard objdump gate for x86 PCLMUL and ARM PMULL expectations.

gates/check_benchmark_matches.py
  Requires complete decapsulation match counts in benchmark logs.
```

## Generators

```text
generators/create_manifest.py
  Creates or checks MANIFEST.tsv and MANIFEST.sha256.

generators/generate_kr_syndrome_table.py
  Generates the public KR [51,41] radius-2 syndrome-leader table.

generators/generate_rs_generator_constants.py
  Generates public RS generator polynomials for all implemented parameter sets.

generators/generate_instance_readmes.py
  Generates per-instance README files from api.h and parameters.h.
```

The KR and RS generators produce compile-time public constants.  They are not
executed in KEM operation or benchmark timing.

## Server runner

```text
server/run_server_validation.sh
```

This is the single server-side validation runner used by `SERVER_TEST.md` for
both x86 and ARM/SVE.

## Optional profiling

```text
profiling/run_component_hotspots.sh
  Optional Linux perf-based component profiler for benchmark binaries.

profiling/profile_components.py
  Aggregates perf symbols into HARE components and emits CSV/Markdown heatmaps.
```

Profiling is controlled by `RUN_COMPONENT_PROFILE=1` in `tools/server/run_server_validation.sh`. It is an optional analysis aid and is not part of the KEM runtime path.
