AFS-TrEDM Submission Package README
===================================

Package scope
-------------
This package contains the electronic submission files for the AFS-TrEDM-S6 hash
family, together with retained build/test scripts and support tools used to
reproduce correctness, known-answer-test (KAT), and performance checks.

The PDF materials are placed directly in the project root.  The English PDF
filenames below are reserved for the final submission; add the real signed or
exported PDF files with these exact names before final delivery.  No dummy PDF
placeholders are included.

Root files
----------
  README.txt
    This file.  It describes the package layout and gives brief descriptions of
    the submitted files and retained reproducibility files.

  Basic Algorithm Information_en.pdf
    English signed/scanned algorithm basic information PDF.

  Basic Algorithm Information_cn.pdf
    Chinese signed/scanned algorithm basic information PDF.

  AFS-TrEDM-S6_Specification_en.pdf
    English algorithm text PDF for AFS-TrEDM-S6.

  AFS-TrEDM-S6_Specification_cn.pdf
    Chinese algorithm text PDF for AFS-TrEDM-S6.

  Intellectual Property Statements_en.pdf
    English signed/scanned intellectual property statement PDF.

  Intellectual Property Statements_cn.pdf
    Chinese signed/scanned intellectual property statement PDF.

  BUILD_AND_TEST_COMMANDS_EN.txt
    English build, quick-test, correctness-regression, KAT, performance, and
    final-validation command summary.

  BUILD_AND_TEST_COMMANDS_CN.txt
    Chinese build, quick-test, correctness-regression, KAT, performance, and
    final-validation command summary.

API_CryptHash compliance notes
------------------------------
  The reference and optimized instance directories expose the ICCS CryptHash()
  programming interface:
    int CryptHash(int digest_len_bits,
                  const unsigned char *msg,
                  unsigned long long msg_len_bits,
                  unsigned char *digest);

  KAT_CryptHash.c, drng.c, and drng.h in the submitted instance directories are
  kept byte-identical to the corresponding helper files from API_CryptHash.zip.
  Submitter-written C sources include function-level comments describing the
  role of each function.

Core submission directories
---------------------------
  Implementations/
    README.txt
      Authoritative implementation directory README with the file directory and
      brief file descriptions.
    Reference_Implementation/
      Portable ISO C reference implementations for AFS-TrEDM-512,
      AFS-TrEDM-768, and AFS-TrEDM-1024.
      The S6 constant-regeneration and algebra-check Python scripts named in
      the algorithm specification are provided in the project-level tools/
      directory.
    Optimized_Implementation/
      Optimized 64-bit PC implementations, shared opt64/S6/dispatch sources,
      and explicit AVX2 targets.
    Additional_Implementation/
      Optional Batch_Multibuffer implementation for throughput-oriented
      software evaluation.

  Test_Vectors/
    README.txt
      Test-vector file descriptions.
    KAT_2_12_AFS-TrEDM-512.txt
    KAT_2_12_AFS-TrEDM-768.txt
    KAT_2_12_AFS-TrEDM-1024.txt
      Known-answer digests for messages with lengths from 0 to 2^12 bits.
    KAT_2_23_AFS-TrEDM-512.txt
    KAT_2_23_AFS-TrEDM-768.txt
    KAT_2_23_AFS-TrEDM-1024.txt
      Known-answer digests for 2^23-bit messages.
    KAT_2_33_AFS-TrEDM-512.txt
    KAT_2_33_AFS-TrEDM-768.txt
    KAT_2_33_AFS-TrEDM-1024.txt
      Known-answer digests for 2^33-bit messages.
    KAT_Loop_AFS-TrEDM-512.txt
    KAT_Loop_AFS-TrEDM-768.txt
    KAT_Loop_AFS-TrEDM-1024.txt
      Loop-test vectors for 2^13-bit messages.

Retained reproducibility directories
------------------------------------
  scripts/
    README.txt
      Describes the retained shell scripts.
    ci_correctness_s6.sh
      Full correctness regression driver.
    generate_s6_kat.sh
      Regenerates the submitted flat Test_Vectors/KAT_*_AFS-TrEDM-*.txt files.
    verify_s6_kat.sh
      Verifies KAT package structure and cross-checks implementations.
    run_full_kat_s6.sh
      Convenience all-KAT regeneration script for every submitted instance.
    run_live_perf_tables_s6.sh
      Live performance table runner wrapper.
    final_validation_s6.sh
      Final package validation script.  It checks script syntax, absence of
      generated build artifacts, flat KAT structure, specification utility
      scripts, performance-report metadata, SHA3 baseline source checksums,
      quick correctness regression, and quick KAT verification.

  tools/
    README.txt
      Describes retained validation and performance support tools.
    gen_s6_iv.py
      Re-derives the three S6 IV constant sets from the documented FNV-1a64 +
      SplitMix64 domain strings.
    check_round_constants.py
      Regenerates the public RC32(round,lane) SplitMix64 schedule and checks
      non-zero/no-duplicate constants for the 12/20/24-round profiles.
    check_s6_algebra.py
      Performs lightweight GF(32), Cauchy MDS, pi_AFS, and mu algebra checks.
    compare_ref_opt_s6.py
      Reference/optimized output comparison helper.
    scan_submission_artifacts.py
      Submission-tree scan helper.
    verify_s6_kat_package.py
      Verifies the flat AFS-TrEDM-S6 Test_Vectors package.
    verify_kat_2_12.py
      Verifies 0..2^12-bit KAT file structure and digest counts.
    verify_kat_structure.py
      Verifies top-level KAT naming and structural conventions.
    verify_kat_long_structure.py
      Verifies long-message KAT structure.
    verify_s6_perf_report.py
      Checks consistency between the performance report and live performance
      output.
    update_s6_performance_report.py
      Helper for updating performance-report tables from measured data.
    perf/
      Live performance measurement, metadata, and baseline helper tools.
    baselines/
      Baseline support data used by retained validation tools.

  docs/
    README.txt
      Describes the retained documentation needed by build/test scripts and
      performance validation.
    perf/
      Current performance report, CSV data, live/latest output, and metadata
      used by performance validation tools.
    sha3_baselines/
      SHA3-512 baseline source provenance, KAT/anti-alias reports, and source
      manifest for the external baseline code used by live performance testing.

Common commands
---------------
  Build and quick-test all submitted instances:

    for b in 512 768 1024; do
      make -C Implementations/Reference_Implementation/AFS-TrEDM-$b clean all
      make -C Implementations/Reference_Implementation/AFS-TrEDM-$b run-quick
      make -C Implementations/Optimized_Implementation/AFS-TrEDM-$b clean all \
        quick_test_avx2 hash_cli_avx2 benchmark_avx2
      make -C Implementations/Optimized_Implementation/AFS-TrEDM-$b run-quick
      ./Implementations/Optimized_Implementation/AFS-TrEDM-$b/quick_test_avx2
    done

  Run the final validation script:

    bash scripts/final_validation_s6.sh "$(pwd)"

See BUILD_AND_TEST_COMMANDS.txt and BUILD_AND_TEST_COMMANDS_CN.txt for the full
command set.
