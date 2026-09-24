# Self-Evaluation Results Directory

This directory contains the packaged server self-evaluation report:

```text
HARE_kr_only_submission_server_test_report.md
```

Fresh benchmark runs may also create timestamped output directories here.

Running the benchmark harness creates a timestamped directory named `bench_<UTC timestamp>` containing:

```text
benchmark_<init>x<repeat>_summary.csv
*.out
*.time
*.size
*.raw_samples.csv
environment.txt
build_info.txt
run.log
summary.txt
```

The script also regenerates convenience pointers such as `latest_benchmark_dir.txt`, `latest_reference_benchmark_dir.txt`, and `latest_optimized_benchmark_dir.txt` when applicable. These pointer files are not required for build, CTest, KAT generation, or KAT replay.
