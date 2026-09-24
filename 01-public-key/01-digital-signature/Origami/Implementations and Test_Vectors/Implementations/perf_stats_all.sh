#!/bin/bash
set -eu

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULT_DIR="${RESULT_DIR:-$BASE_DIR/PerfStats_Results}"
CPU_FREQ_MHZ="${CPU_FREQ_MHZ:-$(cat /proc/cpuinfo 2>/dev/null | awk '/cpu MHz/ {print $4; exit}' || echo 3000.0)}"

declare -A RUNS
RUNS[Origami-128]="10 20 30"
RUNS[Origami-256]="5 10 20"
RUNS[Origami-384]="3 5 10"
RUNS[Origami-512]="2 3 5"

# Mode: "all" (default), "ref", "opt"
IMPL_MODE="${IMPL_MODE:-all}"
case "$IMPL_MODE" in
    ref) IMPLS="Reference_Implementation" ;;
    opt) IMPLS="Optimized_Implementation" ;;
    *)   IMPLS="Reference_Implementation Optimized_Implementation" ;;
esac

mkdir -p "$RESULT_DIR"
echo "cpu_freq_mhz=$CPU_FREQ_MHZ  mode=$IMPL_MODE"
echo ""

for impl in $IMPLS; do
    for inst in Origami-128 Origami-256 Origami-384 Origami-512; do
        dir="$BASE_DIR/$impl/$inst"
        eval "set -- ${RUNS[$inst]}"
        kg_runs="$1"; sn_runs="$2"; vf_runs="$3"
        max_runs="$vf_runs"

        echo "=== $impl/$inst  (kg=$kg_runs sn=$sn_runs vf=$vf_runs) ==="
        (cd "$dir" && make clean bench 2>/dev/null)
        bin="$dir/bench_$inst"

        raw="$RESULT_DIR/${impl}_${inst}_raw.csv"
        echo "run_idx,keygen_us,sign_us,verify_us" > "$raw"

        for ((run=1; run<=max_runs; run++)); do
            out=$("$bin" 1 64 2>/dev/null)
            kg=$(echo "$out" | awk -F, '/^keygen,/ {printf "%d", $3+0.5}')
            sn=$(echo "$out" | awk -F, '/^sign,/   {printf "%d", $3+0.5}')
            vf=$(echo "$out" | awk -F, '/^verify,/ {printf "%d", $3+0.5}')
            echo "$run,$kg,$sn,$vf" >> "$raw"
            printf "  run %2d/%d  kg=%6d  sn=%8d  vf=%8d us\n" "$run" "$max_runs" "$kg" "$sn" "$vf"
        done

        python3 - "$raw" "$kg_runs" "$sn_runs" "$vf_runs" "$CPU_FREQ_MHZ" "$impl" "$inst" << 'PYEOF'
import sys, csv
raw_file = sys.argv[1]
kg_n = int(sys.argv[2]); sn_n = int(sys.argv[3]); vf_n = int(sys.argv[4])
freq = float(sys.argv[5]); impl = sys.argv[6]; inst = sys.argv[7]

rows = []
with open(raw_file) as f:
    for r in csv.DictReader(f):
        rows.append((int(r["keygen_us"]), int(r["sign_us"]), int(r["verify_us"])))

def stats(vals):
    s = sorted(vals)
    n = len(s)
    mean = sum(s)/n
    med = (s[n//2-1]+s[n//2])/2.0 if n%2==0 else s[n//2]
    var = sum((x-mean)**2 for x in s)/(n-1) if n>1 else 0.0
    return mean, med, var**0.5

for tag, vals, n in [("keygen", [r[0] for r in rows[:kg_n]], kg_n),
                     ("sign",   [r[1] for r in rows[:sn_n]], sn_n),
                     ("verify", [r[2] for r in rows[:vf_n]], vf_n)]:
    if n == 0: continue
    mean, med, std = stats(vals)
    m_c = mean * freq / 1e6
    d_c = med  * freq / 1e6
    s_c = std  * freq / 1e6
    print(f"STAT|{impl}|{inst}|{tag}|{n}|{mean:.2f}|{med:.2f}|{std:.2f}|{m_c:.4f}|{d_c:.4f}|{s_c:.4f}")
PYEOF
        echo ""
    done
done

echo "All done. Results under $RESULT_DIR/"
