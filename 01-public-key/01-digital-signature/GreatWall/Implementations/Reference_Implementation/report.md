# Reference Implementation Performance Report

The benchmark used a 64-byte message and 100 iterations. Times are averages in milliseconds. Memory values are in bytes.

| Instance | PK | SK | Signature | KeyGen ms | Sign ms | Verify ms | Static | Max RSS |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| GreatWall128f | 36 | 36 | 3396 | 1.215 | 27.973 | 19.568 | 120547 | 2359296 |
| GreatWall128s | 36 | 36 | 2758 | 1.268 | 111.114 | 89.599 | 122443 | 7032832 |
| GreatWall192f | 50 | 50 | 8012 | 3.147 | 90.280 | 57.219 | 165575 | 2576384 |
| GreatWall192s | 50 | 50 | 6804 | 3.112 | 304.655 | 266.985 | 166723 | 10903552 |
| GreatWall256f | 66 | 66 | 14260 | 5.045 | 208.265 | 129.961 | 183155 | 7827456 |
| GreatWall256s | 66 | 66 | 12236 | 5.013 | 565.605 | 480.228 | 183859 | 51073024 |
| GreatWall512f | 132 | 132 | 57812 | 19.786 | 2424.320 | 1466.726 | 351503 | 25968640 |
| GreatWall512s | 132 | 132 | 50012 | 19.993 | 6087.004 | 5156.342 | 351759 | 210501632 |

The reference implementation is much slower in signing and verification because it uses portable scalar code. Full cycle and throughput data are available in `benchmark_results.csv`.

The suffix `f` means **fast**, and the suffix `s` means **slow**.
