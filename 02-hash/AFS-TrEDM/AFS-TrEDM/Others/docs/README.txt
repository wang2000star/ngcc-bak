AFS-TrEDM docs README
====================

This directory keeps only the documentation needed by retained build/test
scripts and performance validation.  Historical review notes, randomness working
logs, large evidence archives, cleanup task files, and old staging command
directories are not included.

Subdirectories:
  perf/
    Current performance report, CSV data, live/latest output, and metadata used
    by tools/perf/check_live_metadata.py and tools/verify_s6_perf_report.py.

  sha3_baselines/
    SHA3-512 baseline source provenance, KAT/anti-alias reports, and source
    manifest for the external baseline code used by live performance testing.
