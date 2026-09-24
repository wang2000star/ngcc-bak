#!/usr/bin/env bash
set -u -o pipefail

RUNS=100
WARMUP=100
FULL_CHECK=1
QUICK=0

usage() {
  cat <<USAGE
Usage: $0 [--runs N] [--warmup N] [--quick] [--full-check]
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --runs) RUNS=${2:?--runs requires a value}; shift 2;;
    --warmup) WARMUP=${2:?--warmup requires a value}; shift 2;;
    --quick) QUICK=1; shift;;
    --full-check) FULL_CHECK=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "unknown argument: $1" >&2; usage >&2; exit 2;;
  esac
done

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
SELF_DIR="$REPO_ROOT/x86_Self_Evaluation"
TS=$(date -u +%Y%m%d-%H%M%S)
RESULT_DIR="$SELF_DIR/results/$TS"
BUILD_DIR="$RESULT_DIR/build"
mkdir -p "$RESULT_DIR" "$BUILD_DIR"
STATUS_FILE="$RESULT_DIR/status.env"
: > "$STATUS_FILE"

INSTANCES="MAMBA-Frost-128 MAMBA-Frost-192 MAMBA-Frost-256 MAMBA-Frost-384 MAMBA-Frost-512 MAMBA-Frost-CC-128 MAMBA-Frost-CC-192 MAMBA-Frost-CC-256 MAMBA-Frost-CC-384 MAMBA-Frost-CC-512"
EXPECTED_CSV="$RESULT_DIR/expected_sizes.csv"
cat > "$EXPECTED_CSV" <<'CSV'
instance,pk_bytes,sk_bytes,ct_bytes,ss_bytes
MAMBA-Frost-128,5152,6736,5192,16
MAMBA-Frost-192,9712,11528,9760,24
MAMBA-Frost-256,16776,19416,15552,32
MAMBA-Frost-384,25096,29032,37736,48
MAMBA-Frost-512,36432,41728,72944,64
MAMBA-Frost-CC-128,5152,6736,5192,16
MAMBA-Frost-CC-192,9712,11528,9760,24
MAMBA-Frost-CC-256,16776,19416,15552,32
MAMBA-Frost-CC-384,37628,43492,25204,48
MAMBA-Frost-CC-512,72832,83328,36544,64
CSV

record_status() {
  key=$1
  value=$2
  printf '%s=%s\n' "$key" "$value" >> "$STATUS_FILE"
}

run_logged() {
  key=$1
  log=$2
  shift 2
  echo "==> $*" > "$log"
  (cd "$REPO_ROOT" && "$@") >> "$log" 2>&1
  rc=$?
  if [ "$rc" -eq 0 ]; then record_status "$key" PASS; else record_status "$key" FAIL; fi
  return "$rc"
}

run_make_logged() {
  key=$1
  log=$2
  shift 2
  echo "==> cd API_PKC && $*" > "$log"
  (cd "$REPO_ROOT/API_PKC" && "$@") >> "$log" 2>&1
  rc=$?
  if [ "$rc" -eq 0 ]; then record_status "$key" PASS; else record_status "$key" FAIL; fi
  return "$rc"
}

artifact_scan() {
  {
    find "$REPO_ROOT/API_PKC" -type f \( \
      -name "*.o" -o -name "*.a" -o -name "*.so" -o -name "*.dll" -o -name "*.exe" -o \
      -name "*.pdb" -o -name "KAT_KEM" -o -name "test_kem_api" -o -name "perf_kem_api" -o \
      -name "check_avx2" -o -name "core" -o -name ".DS_Store" -o -name "*.pyc" -o -name "perf_*.csv" \
    \) -print
    find "$REPO_ROOT/API_PKC" -type d \( -name "output" -o -name "output.first" -o -name "__pycache__" -o -name "build" -o -name "CMakeFiles" \) -print
  }
}

cpu_flags=$(grep -m1 '^flags' /proc/cpuinfo 2>/dev/null || true)
case " $cpu_flags " in *" avx2 "*) HAS_AVX2=1;; *) HAS_AVX2=0;; esac
case " $cpu_flags " in *" aes "*) HAS_AES=1;; *) HAS_AES=0;; esac
record_status RUNS "$RUNS"
record_status WARMUP "$WARMUP"
record_status QUICK "$QUICK"
record_status FULL_CHECK "$FULL_CHECK"
record_status RESULT_DIR "$RESULT_DIR"
record_status HAS_AVX2 "$HAS_AVX2"
record_status HAS_AES "$HAS_AES"

"$SELF_DIR/collect_environment.sh" "$RESULT_DIR"

run_make_logged reference_clean "$RESULT_DIR/clean_reference.log" make clean || true
run_make_logged reference_build "$RESULT_DIR/build_reference.log" make || true
run_make_logged reference_smoke "$RESULT_DIR/smoke_reference.log" make smoke || true
run_make_logged reference_kat "$RESULT_DIR/kat_reference.log" make kats || true
run_make_logged reference_kat_repro "$RESULT_DIR/kat_repro_reference.log" make kat-repro || true
if [ "$FULL_CHECK" -eq 1 ]; then
  run_make_logged reference_check "$RESULT_DIR/check_reference.log" make check || true
else
  record_status reference_check NOT_RUN
fi

if [ "$HAS_AVX2" -eq 1 ] && [ "$HAS_AES" -eq 1 ]; then
  run_make_logged optimized_clean "$RESULT_DIR/clean_optimized.log" make optimized-clean || true
  run_make_logged optimized_build "$RESULT_DIR/build_optimized.log" make optimized-all || true
  run_make_logged optimized_smoke "$RESULT_DIR/smoke_optimized.log" make optimized-smoke || true
  run_make_logged optimized_kat "$RESULT_DIR/kat_optimized.log" make optimized-kats || true
  run_make_logged optimized_kat_repro "$RESULT_DIR/kat_repro_optimized.log" make optimized-kat-repro || true
  if [ "$FULL_CHECK" -eq 1 ]; then
    run_make_logged optimized_check "$RESULT_DIR/check_optimized.log" make optimized-check || true
  else
    record_status optimized_check NOT_RUN
  fi
else
  echo "Optimized tests skipped because CPU lacks AVX2/AES-NI" > "$RESULT_DIR/build_optimized.log"
  record_status optimized_build SKIPPED
  record_status optimized_smoke SKIPPED
  record_status optimized_kat SKIPPED
  record_status optimized_kat_repro SKIPPED
  record_status optimized_check SKIPPED
fi

# Dependency scans.
{
  grep -R "RAND_bytes\|OpenSSL\|/dev/urandom\|getrandom\|arc4random" -n \
    "$REPO_ROOT/API_PKC/Implementations/Reference_Implementation"/MAMBA-Frost-* \
    "$REPO_ROOT/API_PKC/Implementations/Optimized_Implementation"/MAMBA-Frost-* || true
} > "$RESULT_DIR/dependency_scan.log" 2>&1
grep -R "randombytes\|DRNG\|get_random_number" -n "$REPO_ROOT/API_PKC" > "$RESULT_DIR/drng_scan.log" 2>&1 || true
grep -R "shake128\|shake256\|pseudoXOF\|fips202\|KeccakP-1600" -n "$REPO_ROOT/API_PKC" > "$RESULT_DIR/auxfunc_scan.log" 2>&1 || true
if grep -E "RAND_bytes|/dev/urandom|getrandom|arc4random" "$RESULT_DIR/dependency_scan.log" >/dev/null 2>&1; then
  record_status dependency_scan FAIL
else
  record_status dependency_scan PASS
fi

printf 'timestamp,implementation,instance,level,operation,warmup_runs,measurement_runs,mean_cycles,median_cycles,min_cycles,max_cycles,stddev_cycles,mean_ns,median_ns,ops_per_sec,pk_bytes,sk_bytes,ct_bytes,ss_bytes,status,notes\n' > "$RESULT_DIR/benchmark.csv"
printf 'implementation,instance,operation,ops_per_sec\n' > "$RESULT_DIR/throughput.csv"
printf 'implementation,instance,pk_bytes,sk_bytes,ct_bytes,ss_bytes\n' > "$RESULT_DIR/sizes.csv"
printf 'implementation,instance,binary,text,data,bss,dec,peak_rss_kb,stack_usage_bytes,status,notes\n' > "$RESULT_DIR/resources.csv"
: > "$RESULT_DIR/benchmark_reference.log"
: > "$RESULT_DIR/benchmark_optimized.log"

compile_and_run_benchmark() {
  implementation=$1
  instance=$2
  base_dir="$REPO_ROOT/API_PKC/Implementations/${implementation}_Implementation/$instance"
  out_dir="$BUILD_DIR/$implementation/$instance"
  mkdir -p "$out_dir"
  bin="$out_dir/benchmark_kem_api"
  level=${instance##*-}
  if [[ "$instance" == MAMBA-Frost-CC-* ]]; then
    family_dir="Frost-CC"
    source_prefix="frostcc"
    common_mk="common_optimized_cc.mk"
  else
    family_dir="Frost"
    source_prefix="frost"
    common_mk="common_optimized.mk"
  fi
  if [ "$implementation" = "Reference" ]; then
    cflags="-std=c99 -Wpedantic -Wall -Wextra -O2"
    cppflags="-I$base_dir -DNIX -D_AMD64_ -D_REFERENCE_ -D_AES128_FOR_A_ -DFROST_USE_E8_CODE"
    aes_source="$base_dir/common/aes/aes_c.c"
  else
    cflags="-std=c99 -Wpedantic -Wall -Wextra -O3 -march=x86-64 -mavx2 -maes -mtune=native -flto -fomit-frame-pointer"
    cppflags="-I$base_dir -DNIX -D_AMD64_ -D_FAST_ -D_AES128_FOR_A_ -DFROST_USE_E8_CODE"
    aes_source="$base_dir/common/aes/aes_ni.c"
  fi
  sources=(
    "$SELF_DIR/benchmark_kem_api.c"
    "$base_dir/KEM_AlgorithmInstance.c"
    "$base_dir/randombytes_adapter.c"
    "$base_dir/drng.c"
    "$base_dir/auxfunc.c"
    "$base_dir/$family_dir/src/${source_prefix}${level}.c"
    "$base_dir/$family_dir/src/util.c"
    "$base_dir/common/sha3/fips202.c"
    "$aes_source"
  )
  log="$RESULT_DIR/benchmark_${implementation,,}.log"
  echo "==> compile $implementation $instance" >> "$log"
  cc $cppflags $cflags "${sources[@]}" -lm -o "$bin" >> "$log" 2>&1 || return 1
  echo "==> run $implementation $instance" >> "$log"
  (ulimit -s unlimited; "$bin" "$implementation" "$RUNS" "$WARMUP") >> "$RESULT_DIR/benchmark.csv" 2>> "$log" || return 1
  awk -F, 'NR>1 {print $2","$3","$5","$15}' "$RESULT_DIR/benchmark.csv" > "$RESULT_DIR/throughput.tmp"
  {
    printf '%s,%s,' "$implementation" "$instance"
    awk -F, -v inst="$instance" -v impl="$implementation" '$2==impl && $3==inst {print $16","$17","$18","$19; exit}' "$RESULT_DIR/benchmark.csv"
  } >> "$RESULT_DIR/sizes.csv"
  text=NA; data=NA; bss=NA; dec=NA
  if command -v size >/dev/null 2>&1; then
    size_line=$(size "$bin" 2>/dev/null | awk 'NR==2 {print $1","$2","$3","$4}')
    if [ -n "$size_line" ]; then IFS=, read -r text data bss dec <<< "$size_line"; fi
  fi
  peak=NA
  if [ -x /usr/bin/time ]; then
    time_log="$out_dir/time_${implementation}_${instance}.log"
    (ulimit -s unlimited; /usr/bin/time -v "$bin" "$implementation" 1 0 >/dev/null) > "$time_log" 2>&1 || true
    peak=$(awk -F: '/Maximum resident set size/ {gsub(/^[ \t]+/, "", $2); print $2}' "$time_log")
    [ -n "$peak" ] || peak=NA
  fi
  printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,PASS,stack_usage_not_measured\n' "$implementation" "$instance" "$bin" "$text" "$data" "$bss" "$dec" "$peak" "NA" >> "$RESULT_DIR/resources.csv"
  return 0
}

benchmark_status=PASS
for instance in $INSTANCES; do
  compile_and_run_benchmark Reference "$instance" || benchmark_status=FAIL
done
if [ "$HAS_AVX2" -eq 1 ] && [ "$HAS_AES" -eq 1 ]; then
  for instance in $INSTANCES; do
    compile_and_run_benchmark Optimized "$instance" || benchmark_status=FAIL
  done
else
  benchmark_status=SKIPPED
fi
awk 'BEGIN{print "implementation,instance,operation,ops_per_sec"} {print}' "$RESULT_DIR/throughput.tmp" > "$RESULT_DIR/throughput.csv" 2>/dev/null || true
rm -f "$RESULT_DIR/throughput.tmp"
record_status benchmark "$benchmark_status"

python3 - "$RESULT_DIR/sizes.csv" "$EXPECTED_CSV" <<'PY'
import csv, sys
sizes, expected = sys.argv[1], sys.argv[2]
exp = {}
with open(expected, newline='') as f:
    for r in csv.DictReader(f): exp[r['instance']] = r
ok = True
with open(sizes, newline='') as f:
    for r in csv.DictReader(f):
        e = exp.get(r['instance'])
        if not e: ok = False; print('unexpected instance', r['instance']); continue
        for k in ('pk_bytes','sk_bytes','ct_bytes','ss_bytes'):
            if r[k] != e[k]: ok = False; print('size mismatch', r['implementation'], r['instance'], k, r[k], e[k])
if not ok:
    sys.exit(1)
PY
if [ "$?" -eq 0 ]; then record_status sizes_check PASS; else record_status sizes_check FAIL; fi

artifact_scan > "$RESULT_DIR/artifact_scan_before_clean.log" 2>&1
(cd "$REPO_ROOT/API_PKC" && make clean >/dev/null 2>&1 || true && make optimized-clean >/dev/null 2>&1 || true)
(cd "$REPO_ROOT" && git checkout -- API_PKC/Test_Vectors >/dev/null 2>&1 || true)
artifact_scan > "$RESULT_DIR/artifact_scan_after_clean.log" 2>&1
if [ -s "$RESULT_DIR/artifact_scan_after_clean.log" ]; then record_status artifact_scan FAIL; else record_status artifact_scan PASS; fi

rm -rf "$BUILD_DIR"
python3 "$SELF_DIR/parse_results.py" "$RESULT_DIR"

echo "Result directory: $RESULT_DIR"
