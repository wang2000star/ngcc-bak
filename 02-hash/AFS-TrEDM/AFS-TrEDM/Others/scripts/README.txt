AFS-TrEDM scripts README
=======================

This directory contains reproducibility scripts for building, testing,
regenerating test vectors, producing performance tables, and validating the
cleaned submission package.

Files:
  ci_correctness_s6.sh
    Full correctness regression driver.  Builds Reference, Optimized opt64,
    dispatch, AVX2 when available, batch fallback, and Batch16 AVX512 when
    available.  Logs are written outside the submission tree by default.

  generate_s6_kat.sh
    Regenerates the submitted flat Test_Vectors/KAT_*_AFS-TrEDM-*.txt files
    from the byte-identical ICCS KAT_CryptHash.c helpers in the reference
    implementation directories.  Because the ICCS helper generates all required
    KAT categories in one run, any MODE value is treated as full.

  verify_s6_kat.sh
    Verifies the flat Test_Vectors package structure, rebuilds command-line
    hash utilities, compares Reference and Optimized outputs, and exercises
    batch quick tests.

  run_full_kat_s6.sh
    Convenience script for regenerating all four required KAT categories for
    every submitted instance into the flat Test_Vectors directory.

  run_live_perf_tables_s6.sh
    Wrapper around tools/perf/live_perf_table.py.  Builds fresh benchmark
    binaries, measures AFS-TrEDM-S6 and optional SHA3-512 baselines, writes
    docs/perf/live/latest, and prints the four terminal performance tables.

  final_validation_s6.sh
    Final package validation script.  It checks shell syntax, forbidden
    generated artifacts, flat KAT package structure, the S6 specification
    utility scripts, performance metadata, SHA3 baseline source checksums,
    quick correctness regression, and quick KAT verification.  Run it from the
    project root as:

      bash scripts/final_validation_s6.sh "$(pwd)"
