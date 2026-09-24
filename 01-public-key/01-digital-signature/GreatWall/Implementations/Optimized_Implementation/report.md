# Optimized Implementation Performance Report

The benchmark used a 64-byte message and 100 iterations. Times are averages in milliseconds. Memory values are in bytes.

| Instance | PK | SK | Signature | KeyGen ms | Sign ms | Verify ms | Static | Max RSS |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| GreatWall128f | 36 | 36 | 3396 | 0.544 | 1.038 | 1.262 | 120547 | 2359296 |
| GreatWall128s | 36 | 36 | 2758 | 0.595 | 4.592 | 6.873 | 122443 | 7032832 |
| GreatWall192f | 50 | 50 | 8012 | 1.342 | 2.578 | 2.627 | 165575 | 2576384 |
| GreatWall192s | 50 | 50 | 6804 | 1.347 | 12.084 | 18.113 | 166723 | 10903552 |
| GreatWall256f | 66 | 66 | 14260 | 1.881 | 4.268 | 4.132 | 183155 | 7827456 |
| GreatWall256s | 66 | 66 | 12236 | 1.863 | 14.576 | 23.100 | 183859 | 51073024 |
| GreatWall512f | 132 | 132 | 57812 | 17.061 | 80.905 | 74.266 | 351503 | 25968640 |
| GreatWall512s | 132 | 132 | 50012 | 16.796 | 392.832 | 478.593 | 351759 | 210501632 |

The `f` suffix means **fast**, while the `s` suffix means **slow**. Full cycle and throughput data are available in `benchmark_results.csv`.
