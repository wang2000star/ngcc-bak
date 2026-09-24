AFS-TrEDM tools README
=====================

This directory contains package-level support tools used by the build/test
scripts, KAT validation, performance-report validation, and the S6 specification
utility checks.  Generated binaries, pycache directories, historical cleanup
tools, and randomness working tools are not included.

Specification utility scripts:
  gen_s6_iv.py
    Re-derives the three S6 IV constant sets from the documented FNV-1a64 +
    SplitMix64 domain strings.  It is self-contained and does not use relative
    file paths.

  check_round_constants.py
    Regenerates the public RC32(round,lane) SplitMix64 schedule for the
    12/20/24-round S6 profiles and checks that constants are non-zero and
    collision-free within each profile.  It is self-contained and does not use
    relative file paths.

  check_s6_algebra.py
    Performs lightweight algebra sanity checks for GF(32), the Cauchy MDS
    matrix, pi_AFS, and the per-lane mu diffusion.  It is self-contained and
    does not use relative file paths.

Validation and support tools:
  compare_ref_opt_s6.py
    Compares Reference and Optimized hash_cli outputs for selected and random
    message lengths.

  scan_submission_artifacts.py
    Non-blocking scan for generated binaries, object files, stale KAT files,
    and archive files inside the active submission tree.

  verify_s6_kat_package.py
    Verifies the submitted flat Test_Vectors layout, required KAT files,
    record counts, digest counts, digest lengths, and SHA-256 values.

  verify_kat_structure.py
    Lightweight structural checker for all flat Test_Vectors/KAT_*.txt files.

  verify_kat_long_structure.py
    Lightweight structural checker for long KAT_2_23, KAT_2_33, and KAT_Loop
    files.

  verify_kat_2_12.py
    Sampled or full recomputation checker for KAT_2_12 files using the
    Reference hash_cli.

  verify_s6_perf_report.py
    Verifies docs/perf performance report CSV/Markdown and live performance
    output consistency.

  update_s6_performance_report.py
    Utility for updating the performance report from live output data.

Subdirectories:
  perf/
    Live performance runner, parser, renderer, metadata checker, and SHA3-512
    baseline source/Makefile files.

  baselines/
    Shared source file used by the OpenSSL SHA3-512 baseline benchmark.

Typical project-root invocations:
  python3 tools/gen_s6_iv.py
  python3 tools/check_round_constants.py
  python3 tools/check_s6_algebra.py
  PYTHONDONTWRITEBYTECODE=1 python3 tools/perf/check_live_metadata.py --root "$(pwd)" --live-dir docs/perf/live/latest
