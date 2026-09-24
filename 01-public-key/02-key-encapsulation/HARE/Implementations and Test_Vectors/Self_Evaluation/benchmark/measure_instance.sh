#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: Self_Evaluation/benchmark/measure_instance.sh <build_dir> [instance-safe-name|all|reference|optimized|reference-kr|optimized-kr] [instances] [repeats]

Examples:
  Self_Evaluation/benchmark/measure_instance.sh build all 10 100
  Self_Evaluation/benchmark/measure_instance.sh build reference 10 100
  Self_Evaluation/benchmark/measure_instance.sh build optimized 10 100
  Self_Evaluation/benchmark/measure_instance.sh build reference-kr 10 100
  Self_Evaluation/benchmark/measure_instance.sh build optimized-kr 10 100
  Self_Evaluation/benchmark/measure_instance.sh build HARE_512_kr_x86 3 5

The official-style count model is 10 deterministic initializations x 100 repeats.
For container smoke validation, pass smaller values such as 1 2 or 3 5.
Optional environment variables:
  HARE_CPU_CORE=<logical-core>             pin benchmark process with taskset when available
  HARE_BENCH_WARMUP_REPEATS=<count>       per-instance warm-up repeats before timed samples, default 1
USAGE
}

if [[ $# -lt 1 || $# -gt 4 ]]; then
  usage
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$1"
INSTANCE_SAFE="${2:-all}"
INSTANCES="${3:-10}"
REPEATS="${4:-100}"
WARMUP_REPEATS="${HARE_BENCH_WARMUP_REPEATS:-1}"

if [[ "$BUILD_DIR" != /* ]]; then
  BUILD_DIR="$(cd "$PACKAGE_ROOT" && cd "$BUILD_DIR" && pwd)"
fi

if [[ ! -d "$BUILD_DIR" ]]; then
  echo "error: build directory not found: $BUILD_DIR" >&2
  exit 3
fi

case "$INSTANCES" in
  ''|*[!0-9]*) echo "error: instances must be a positive integer" >&2; exit 4 ;;
esac
case "$REPEATS" in
  ''|*[!0-9]*) echo "error: repeats must be a positive integer" >&2; exit 4 ;;
esac
case "$WARMUP_REPEATS" in
  ''|*[!0-9]*) echo "error: HARE_BENCH_WARMUP_REPEATS must be a non-negative integer" >&2; exit 4 ;;
esac
if [[ "$INSTANCES" -le 0 || "$REPEATS" -le 0 ]]; then
  echo "error: instances and repeats must be positive" >&2
  exit 4
fi

preflight_tools() {
  if [[ ! -x /usr/bin/time ]]; then
    echo "error: /usr/bin/time is required for peak RSS/resource reporting" >&2
    exit 7
  fi
  if ! /usr/bin/time -v true >/dev/null 2>&1; then
    echo "error: /usr/bin/time -v is not usable on this host" >&2
    exit 7
  fi
  if ! command -v size >/dev/null 2>&1; then
    echo "warning: size tool unavailable; static_bytes will be reported as NA" >&2
  fi
  if ! command -v cmake >/dev/null 2>&1; then
    echo "error: cmake is required to build benchmark targets" >&2
    exit 7
  fi
}

preflight_tools

RESULT_ROOT="${HARE_SELF_EVALUATION_RESULTS_DIR:-$(dirname "$PACKAGE_ROOT")/hare-self-evaluation-results}"
STAMP="$(date -u +%Y%m%d_%H%M%S)"
OUTDIR="$RESULT_ROOT/bench_${STAMP}"
mkdir -p "$OUTDIR"
CSV="$OUTDIR/benchmark_${INSTANCES}x${REPEATS}_summary.csv"

RUNNER=()
PINNING_STATUS="not_requested"
if command -v taskset >/dev/null 2>&1; then
  CORE="${HARE_CPU_CORE:-0}"
  if taskset -c "$CORE" true >/dev/null 2>&1; then
    RUNNER=(taskset -c "$CORE")
    PINNING_STATUS="taskset_core_${CORE}"
  else
    PINNING_STATUS="taskset_unavailable_for_core_${CORE}"
  fi
fi

read_cpu_governor() {
  local gov_file="/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor"
  if [[ -r "$gov_file" ]]; then
    cat "$gov_file"
  else
    echo "NA"
  fi
}

read_turbo_state() {
  if [[ -r /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
    local v
    v="$(cat /sys/devices/system/cpu/intel_pstate/no_turbo)"
    if [[ "$v" == "1" ]]; then
      echo "intel_pstate_no_turbo=1(disabled)"
    else
      echo "intel_pstate_no_turbo=0(enabled_or_default)"
    fi
  elif [[ -r /sys/devices/system/cpu/cpufreq/boost ]]; then
    echo "cpufreq_boost=$(cat /sys/devices/system/cpu/cpufreq/boost)"
  else
    echo "NA"
  fi
}

collect_environment() {
  {
    echo "timestamp_utc_start=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "package_root=$PACKAGE_ROOT"
    echo "build_dir=$BUILD_DIR"
    echo "selector=$INSTANCE_SAFE"
    echo "benchmark_model=instance_repeat_two_level"
    echo "instances=$INSTANCES"
    echo "repeats=$REPEATS"
    echo "warmup_repeats_per_instance=$WARMUP_REPEATS"
    echo "single_core_pinning=$PINNING_STATUS"
    echo "cpu_governor=$(read_cpu_governor)"
    echo "turbo_state=$(read_turbo_state)"
    echo "time_tool=/usr/bin/time -v"
    echo "size_tool=$(command -v size 2>/dev/null || echo NA)"
    echo "official_x86_guide_environment=no"
    echo "official_x86_guide_note=current run is container validation unless executed on CentOS8.2/GCC8.3.1/CMake3.11.4 single-core x86 environment"
    echo "uname=$(uname -a)"
    if command -v gcc >/dev/null 2>&1; then
      echo "gcc=$(gcc --version | head -n 1)"
    else
      echo "gcc=NA"
    fi
    if command -v cc >/dev/null 2>&1; then
      echo "cc=$(cc --version | head -n 1)"
    else
      echo "cc=NA"
    fi
    if command -v cmake >/dev/null 2>&1; then
      echo "cmake=$(cmake --version | head -n 1)"
    else
      echo "cmake=NA"
    fi
    echo "reference_compile_flags=-std=c99 -Wpedantic -Wall -Wextra -O2"
    echo "optimized_x86_compile_flags=-O3 -march=x86-64 -mavx2 -mpclmul -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra; optional -DHARE_X86_ENABLE_LTO=ON adds -flto"
    if command -v lscpu >/dev/null 2>&1; then
      lscpu | sed 's/^/lscpu: /'
    elif [[ -r /proc/cpuinfo ]]; then
      grep -m1 'model name' /proc/cpuinfo | sed 's/^/cpuinfo: /' || true
    else
      echo "cpuinfo=NA"
    fi
  } > "$OUTDIR/environment.txt"
}

collect_build_info() {
  {
    echo "timestamp_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "package_root=$PACKAGE_ROOT"
    echo "build_dir=$BUILD_DIR"
    echo "selector=$INSTANCE_SAFE"
    echo "instances=$INSTANCES"
    echo "repeats=$REPEATS"
    echo "warmup_repeats_per_instance=$WARMUP_REPEATS"
    echo "reference_compile_flags=-std=c99 -Wpedantic -Wall -Wextra -O2"
    echo "optimized_x86_compile_flags=-O3 -march=x86-64 -mavx2 -mpclmul -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra; optional -DHARE_X86_ENABLE_LTO=ON adds -flto"
    if [[ -f "$BUILD_DIR/CMakeCache.txt" ]]; then
      echo "-- CMake cache summary --"
      grep -E '^(CMAKE_C_COMPILER:|CMAKE_C_FLAGS:|CMAKE_BUILD_TYPE:|CMAKE_GENERATOR:|HARE_)' "$BUILD_DIR/CMakeCache.txt" || true
    else
      echo "cmake_cache=NA"
    fi
  } > "$OUTDIR/build_info.txt"
}

build_target() {
  local target="$1"
  cmake --build "$BUILD_DIR" --target "$target" > "$OUTDIR/${target}.build.log" 2>&1
}

kv() {
  local file="$1"
  local key="$2"
  awk -F= -v key="$key" '$1 == key { print $2; found=1; exit } END { if (!found) print "NA" }' "$file"
}

static_size_bytes() {
  local file="$1"
  awk 'NR == 2 { print $4; found=1; exit } END { if (!found) print "NA" }' "$file"
}

append_csv_header() {
  cat > "$CSV" <<'HEADER'
target,algorithm_instance,pk_bytes,sk_bytes,ct_bytes,ss_bytes,keygen_avg_cycles,keygen_min_cycles,keygen_max_cycles,keygen_median_cycles,keygen_p05_cycles,keygen_p95_cycles,keygen_mad_cycles,keygen_trimmed_mean_cycles,keygen_stddev_cycles,keygen_ops_per_sec,encaps_avg_cycles,encaps_min_cycles,encaps_max_cycles,encaps_median_cycles,encaps_p05_cycles,encaps_p95_cycles,encaps_mad_cycles,encaps_trimmed_mean_cycles,encaps_stddev_cycles,encaps_ops_per_sec,decaps_avg_cycles,decaps_min_cycles,decaps_max_cycles,decaps_median_cycles,decaps_p05_cycles,decaps_p95_cycles,decaps_mad_cycles,decaps_trimmed_mean_cycles,decaps_stddev_cycles,decaps_ops_per_sec,peak_rss_bytes,static_bytes,decaps_match,raw_samples_csv
HEADER
}

append_csv_row() {
  local name="$1"
  local out="$OUTDIR/${name}.out"
  local sizef="$OUTDIR/${name}.size"
  local target="${name#bench_}"
  local alg static_bytes raw_csv_base
  alg="$(kv "$out" algorithm_instance)"
  static_bytes="$(static_size_bytes "$sizef")"
  raw_csv_base="$(basename "$OUTDIR/${name}.raw_samples.csv")"

  printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$target" \
    "$alg" \
    "$(kv "$out" pk_bytes)" \
    "$(kv "$out" sk_bytes)" \
    "$(kv "$out" ct_bytes)" \
    "$(kv "$out" ss_bytes)" \
    "$(kv "$out" keygen_avg_cycles)" \
    "$(kv "$out" keygen_min_cycles)" \
    "$(kv "$out" keygen_max_cycles)" \
    "$(kv "$out" keygen_median_cycles)" \
    "$(kv "$out" keygen_p05_cycles)" \
    "$(kv "$out" keygen_p95_cycles)" \
    "$(kv "$out" keygen_mad_cycles)" \
    "$(kv "$out" keygen_trimmed_mean_cycles)" \
    "$(kv "$out" keygen_stddev_cycles)" \
    "$(kv "$out" keygen_ops_per_sec)" \
    "$(kv "$out" encaps_avg_cycles)" \
    "$(kv "$out" encaps_min_cycles)" \
    "$(kv "$out" encaps_max_cycles)" \
    "$(kv "$out" encaps_median_cycles)" \
    "$(kv "$out" encaps_p05_cycles)" \
    "$(kv "$out" encaps_p95_cycles)" \
    "$(kv "$out" encaps_mad_cycles)" \
    "$(kv "$out" encaps_trimmed_mean_cycles)" \
    "$(kv "$out" encaps_stddev_cycles)" \
    "$(kv "$out" encaps_ops_per_sec)" \
    "$(kv "$out" decaps_avg_cycles)" \
    "$(kv "$out" decaps_min_cycles)" \
    "$(kv "$out" decaps_max_cycles)" \
    "$(kv "$out" decaps_median_cycles)" \
    "$(kv "$out" decaps_p05_cycles)" \
    "$(kv "$out" decaps_p95_cycles)" \
    "$(kv "$out" decaps_mad_cycles)" \
    "$(kv "$out" decaps_trimmed_mean_cycles)" \
    "$(kv "$out" decaps_stddev_cycles)" \
    "$(kv "$out" decaps_ops_per_sec)" \
    "$(kv "$out" peak_rss_bytes)" \
    "$static_bytes" \
    "$(kv "$out" decaps_shared_secret_match_count)" \
    "$raw_csv_base" \
    >> "$CSV"
}

run_one() {
  local exe="$1"
  local name
  name="$(basename "$exe")"

  echo "running $name" | tee -a "$OUTDIR/run.log"
  build_target "$name"

  if command -v size >/dev/null 2>&1; then
    size "$exe" > "$OUTDIR/${name}.size"
  else
    echo "size_tool_unavailable" > "$OUTDIR/${name}.size"
  fi

  /usr/bin/time -v \
    env HARE_BENCH_INSTANCES="$INSTANCES" \
        HARE_BENCH_REPEATS="$REPEATS" \
        HARE_BENCH_WARMUP_REPEATS="$WARMUP_REPEATS" \
        HARE_BENCH_RAW_CSV="$OUTDIR/${name}.raw_samples.csv" \
    "${RUNNER[@]}" "$exe" "$INSTANCES" "$REPEATS" \
    > "$OUTDIR/${name}.out" \
    2> "$OUTDIR/${name}.time"

  append_csv_row "$name"

  {
    echo "target=$name"
    echo "output=$OUTDIR/${name}.out"
    echo "raw_samples=$OUTDIR/${name}.raw_samples.csv"
    echo "time=$OUTDIR/${name}.time"
    echo "size=$OUTDIR/${name}.size"
    awk -F: '/Maximum resident set size/{gsub(/^[ \t]+/,"",$2); print "time_peak_rss_kb=" $2}' "$OUTDIR/${name}.time" || true
  } >> "$OUTDIR/summary.txt"
}

collect_environment
collect_build_info
: > "$OUTDIR/run.log"
: > "$OUTDIR/summary.txt"
append_csv_header

collect_benchmarks() {
  local selector="$1"
  case "$selector" in
    all)
      find "$BUILD_DIR" -maxdepth 1 -type f -executable -name 'bench_*' | sort
      ;;
    reference|reference-kr)
      printf '%s\n' \
        "$BUILD_DIR/bench_HARE_128_kr" \
        "$BUILD_DIR/bench_HARE_256_kr" \
        "$BUILD_DIR/bench_HARE_384_kr" \
        "$BUILD_DIR/bench_HARE_512_kr"
      ;;
    optimized|x86|optimized-kr)
      printf '%s\n' \
        "$BUILD_DIR/bench_HARE_128_kr_x86" \
        "$BUILD_DIR/bench_HARE_256_kr_x86" \
        "$BUILD_DIR/bench_HARE_384_kr_x86" \
        "$BUILD_DIR/bench_HARE_512_kr_x86"
      ;;
    *)
      return 1
      ;;
  esac
}

if collect_benchmarks "$INSTANCE_SAFE" >/dev/null 2>&1; then
  mapfile -t EXES < <(collect_benchmarks "$INSTANCE_SAFE")
  if [[ ${#EXES[@]} -eq 0 ]]; then
    echo "error: no benchmark executables found for selector: $INSTANCE_SAFE" >&2
    exit 5
  fi
  for exe in "${EXES[@]}"; do
    target="$(basename "$exe")"
    if [[ ! -x "$exe" ]]; then
      build_target "$target"
    fi
    if [[ ! -x "$exe" ]]; then
      echo "error: benchmark executable not found: $exe" >&2
      exit 6
    fi
    run_one "$exe"
  done
else
  EXE="$BUILD_DIR/bench_${INSTANCE_SAFE}"
  if [[ ! -x "$EXE" ]]; then
    build_target "bench_${INSTANCE_SAFE}"
  fi
  if [[ ! -x "$EXE" ]]; then
    echo "error: benchmark executable not found: $EXE" >&2
    exit 6
  fi
  run_one "$EXE"
fi

echo "timestamp_utc_end=$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$OUTDIR/environment.txt"
echo "results_dir=$OUTDIR"

# `latest_*` files are convenience pointers only. They are regenerated by this script
# and are not required for build, KAT replay, or submission correctness.
base_outdir="$(basename "$OUTDIR")"
echo "$base_outdir" > "$RESULT_ROOT/latest_benchmark_dir.txt"
case "$INSTANCE_SAFE" in
  reference)
    echo "$base_outdir" > "$RESULT_ROOT/latest_reference_benchmark_dir.txt"
    ;;
  optimized|x86)
    echo "$base_outdir" > "$RESULT_ROOT/latest_optimized_benchmark_dir.txt"
    ;;
  *_x86)
    echo "$base_outdir" > "$RESULT_ROOT/latest_optimized_benchmark_dir.txt"
    ;;
  HARE_128_*|HARE_256_*|HARE_384_*|HARE_512_*)
    echo "$base_outdir" > "$RESULT_ROOT/latest_reference_benchmark_dir.txt"
    ;;
esac
