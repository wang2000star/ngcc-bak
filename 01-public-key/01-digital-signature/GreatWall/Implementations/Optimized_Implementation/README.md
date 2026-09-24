# GreatWall/Pylon Optimized Implementation

This directory contains eight independent x86-optimized instances: `GreatWall128f/s`, `GreatWall192f/s`, `GreatWall256f/s`, and `GreatWall512f/s`.

The suffix `f` means **fast**, and the suffix `s` means **slow**.

Run the following commands under WSL:

```bash
cd /mnt/d/VsCode/AIMer/faest-one-tree-field-full/API_PKC/Implementations/Optimized_Implementation
bash clean_all_instances.sh
bash make_all_instances.sh
bash run_all_kat_sig.sh
bash run_all_bench_sig.sh 100
bash run_all_memory_sig.sh 100
```

Pass instance names to operate on selected instances only:

```bash
bash make_all_instances.sh GreatWall128f GreatWall512s
bash run_all_kat_sig.sh GreatWall128f GreatWall512s
bash run_all_bench_sig.sh 100 GreatWall128f
bash run_all_memory_sig.sh 100 GreatWall128f
```

Benchmark and memory results are written to `benchmark_results.csv` and `memory_results.csv`.
