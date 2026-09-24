#!/usr/bin/env bash
# Optional perf-based component hotspot profiler for HARE benchmark binaries.
set -u -o pipefail

if [ "$#" -lt 4 ]; then
  echo "usage: $0 <build_dir> <out_dir> <label> <bench1> [bench2 ...]" >&2
  exit 2
fi

BUILD_DIR=$1
OUT_DIR=$2
LABEL=$3
shift 3
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
CORE=${HARE_CPU_CORE:-0}
INSTANCES=${HARE_COMPONENT_PROFILE_INSTANCES:-1}
REPEATS=${HARE_COMPONENT_PROFILE_REPEATS:-20}
WARMUP=${HARE_COMPONENT_PROFILE_WARMUP_REPEATS:-2}
FREQ=${HARE_COMPONENT_PROFILE_FREQ:-97}
REQUIRE=${REQUIRE_COMPONENT_PROFILE:-0}

mkdir -p "$OUT_DIR"
STATUS="$OUT_DIR/component_profile_status.txt"
: > "$STATUS"
{
  echo "label=$LABEL"
  echo "build_dir=$BUILD_DIR"
  echo "instances=$INSTANCES"
  echo "repeats=$REPEATS"
  echo "warmup=$WARMUP"
  echo "freq=$FREQ"
} >> "$STATUS"

if ! command -v perf >/dev/null 2>&1; then
  echo "status=UNAVAILABLE_PERF_NOT_FOUND" | tee -a "$STATUS"
  [ "$REQUIRE" = 1 ] && exit 1 || exit 0
fi
if ! command -v taskset >/dev/null 2>&1; then
  echo "status=UNAVAILABLE_TASKSET_NOT_FOUND" | tee -a "$STATUS"
  [ "$REQUIRE" = 1 ] && exit 1 || exit 0
fi

reports=()
rc=0
for bench in "$@"; do
  if [ ! -x "$bench" ]; then
    echo "missing benchmark executable: $bench" | tee -a "$STATUS"
    rc=1
    continue
  fi
  base=$(basename "$bench")
  data="$OUT_DIR/perf_${LABEL}_${base}.data"
  log="$OUT_DIR/perf_record_${LABEL}_${base}.log"
  report="$OUT_DIR/perf_report_${LABEL}_${base}.txt"
  echo "profile $base" | tee -a "$STATUS"
  perf record -F "$FREQ" -g -o "$data" -- \
    taskset -c "$CORE" env \
      HARE_BENCH_INSTANCES="$INSTANCES" \
      HARE_BENCH_REPEATS="$REPEATS" \
      HARE_BENCH_WARMUP_REPEATS="$WARMUP" \
      "$bench" > "$log" 2>&1
  rec_rc=$?
  if [ "$rec_rc" -ne 0 ]; then
    echo "perf_record_${base}=FAIL:$rec_rc" | tee -a "$STATUS"
    rc=1
    continue
  fi
  perf report --stdio --no-children --percent-limit 0 --sort=symbol,dso -i "$data" > "$report" 2>> "$log"
  rep_rc=$?
  if [ "$rep_rc" -ne 0 ]; then
    echo "perf_report_${base}=FAIL:$rep_rc" | tee -a "$STATUS"
    rc=1
    continue
  fi
  reports+=("$report")
done

if [ "${#reports[@]}" -eq 0 ]; then
  echo "status=NO_REPORTS" | tee -a "$STATUS"
  [ "$REQUIRE" = 1 ] && exit 1 || exit 0
fi

python3 "$ROOT/tools/profiling/profile_components.py" \
  --csv "$OUT_DIR/component_hotspots.csv" \
  --markdown "$OUT_DIR/component_hotspot_heatmap.md" \
  --symbols "$OUT_DIR/component_hotspot_symbols.csv" \
  "${reports[@]}" >> "$STATUS" 2>&1
parse_rc=$?
if [ "$parse_rc" -ne 0 ]; then
  echo "status=PARSE_FAIL:$parse_rc" | tee -a "$STATUS"
  exit 1
fi

if [ "$rc" -ne 0 ]; then
  echo "status=PARTIAL_FAIL" | tee -a "$STATUS"
  [ "$REQUIRE" = 1 ] && exit 1 || exit 0
fi

echo "status=PASS" | tee -a "$STATUS"
exit 0
