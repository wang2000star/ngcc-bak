#!/bin/sh
# Experiment A: x86 single-core performance of the WITHIN-PERMUTATION AVX2 build.
# Reports S1..S8 (32 B .. 64 KiB, per 1-2 guideline) plus two long-message points
# (256 KiB, 1 MiB) for the asymptotic single-thread rate r1, for QSH-512/768/1024.
#
#   sh run_perf_x86.sh [cpu_GHz] [repeats]
#     cpu_GHz : nominal/sustained core frequency, used only to derive the
#               cyc/byte column (MB/s is measured directly). e.g. 3.6
#               If omitted, the cyc/byte column is left blank.
#     repeats : how many times to repeat each variant (default 3); take the
#               best (highest MB/s) row per size as your reported figure.
#
# Output: SelfAssessment/results/perf_x86_withinperm.csv  (+ printed)
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GHZ="${1:-0}"
REP="${2:-3}"
SRC="$ROOT/Implementations/Optimized_Implementation_WithinPerm/QSH-512"   # dispatches all variants
OUT="$ROOT/SelfAssessment/results"; mkdir -p "$OUT"
CSV="$OUT/perf_x86_withinperm.csv"

echo "building self_assess (AVX2 within-permutation)..."
gcc -O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 \
    -I"$SRC" "$ROOT/SelfAssessment/self_assess.c" "$SRC/CryptHash_AlgorithmInstance.c" \
    -o "$OUT/self_assess_x86"

# pin to one core if possible (Linux). macOS has no taskset -> ignored.
PIN=""; command -v taskset >/dev/null 2>&1 && PIN="taskset -c 0"

echo "# QSH within-permutation, AVX2, single core" > "$CSV"
echo "# CPU: $(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^ //')" >> "$CSV"
echo "# cyc/byte derived with GHz=$GHZ (0 = blank); MB/s measured directly" >> "$CSV"
echo "run,variant,size_bytes,iters,avg_ns,throughput_MBps,cyc_per_byte" >> "$CSV"

for v in 512 768 1024; do
    r=1
    while [ "$r" -le "$REP" ]; do
        $PIN "$OUT/self_assess_x86" "$v" "$GHZ" | tail -n +2 | sed "s/^/$r,/" >> "$CSV"
        r=$((r+1))
    done
done

echo "DONE -> $CSV"
echo "(S1-S8 = sizes 32..65536; 262144 & 1048576 give the long-message r1.)"
echo "Tip: take the BEST throughput_MBps across the $REP runs per (variant,size)."
column -t -s, "$CSV" 2>/dev/null | sed -n '1,40p' || cat "$CSV"
