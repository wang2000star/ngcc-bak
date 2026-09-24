#!/usr/bin/env bash
# Fresh-server validation runner for the HARE final-parameter submission package.
set -u -o pipefail

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
OUT=${1:-"$(dirname "$ROOT")/hare-results/server_$(date -u +%Y%m%d_%H%M%S)"}
MODE=${HARE_SERVER_MODE:-auto}
JOBS=${JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 1)}
CORE=${HARE_CPU_CORE:-0}
BENCH_INSTANCES=${HARE_BENCH_INSTANCES:-10}
BENCH_REPEATS=${HARE_BENCH_REPEATS:-100}
BENCH_WARMUP=${HARE_BENCH_WARMUP_REPEATS:-10}
RUN_SANITIZERS=${RUN_SANITIZERS:-1}
RUN_COMPONENT_PROFILE=${RUN_COMPONENT_PROFILE:-0}
REQUIRE_COMPONENT_PROFILE=${REQUIRE_COMPONENT_PROFILE:-0}
export ROOT OUT CORE BENCH_INSTANCES BENCH_REPEATS BENCH_WARMUP RUN_COMPONENT_PROFILE REQUIRE_COMPONENT_PROFILE

ROOT_CANON=$(readlink -m "$ROOT")
OUT_CANON=$(readlink -m "$OUT")
case "$OUT_CANON/" in
  "$ROOT_CANON/"*) echo "error: result/build directory must be outside source tree: $OUT_CANON" >&2; exit 2 ;;
esac

mkdir -p "$OUT/logs" "$OUT/audit" "$OUT/bench" "$OUT/resource" "$OUT/builds"
STATUS_FILE="$OUT/run_status.tsv"
printf 'step\texit_code\n' > "$STATUS_FILE"
OVERALL=0
LAST_RC=0

run_shell() {
  local name=$1
  local command=$2
  local log="$OUT/logs/${name}.log"
  echo "===== $name =====" | tee "$log"
  bash -lc "$command" 2>&1 | tee -a "$log"
  LAST_RC=${PIPESTATUS[0]}
  printf '%s\t%s\n' "$name" "$LAST_RC" >> "$STATUS_FILE"
  if [ "$LAST_RC" -ne 0 ] && [ "$OVERALL" -lt 1 ]; then OVERALL=1; fi
  return 0
}

ARCH=$(uname -m)
if [ "$MODE" = auto ]; then
  case "$ARCH" in
    x86_64|amd64) MODE=x86 ;;
    aarch64|arm64) MODE=arm ;;
    *) MODE=unsupported ;;
  esac
fi

{
  echo "run_start_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo "root=$ROOT"
  echo "out=$OUT"
  echo "mode=$MODE"
  echo "arch=$ARCH"
  echo "core=$CORE"
  echo "benchmark_instances=$BENCH_INSTANCES"
  echo "benchmark_repeats=$BENCH_REPEATS"
  echo "benchmark_warmup=$BENCH_WARMUP"
  echo "run_component_profile=$RUN_COMPONENT_PROFILE"
  echo "require_component_profile=$REQUIRE_COMPONENT_PROFILE"
  echo "component_profile_instances=${HARE_COMPONENT_PROFILE_INSTANCES:-1}"
  echo "component_profile_repeats=${HARE_COMPONENT_PROFILE_REPEATS:-20}"
  echo "component_profile_warmup=${HARE_COMPONENT_PROFILE_WARMUP_REPEATS:-2}"
  uname -a || true
  cat /etc/os-release 2>/dev/null || true
  lscpu 2>/dev/null || true
  grep -m1 '^Features\|^flags' /proc/cpuinfo 2>/dev/null || true
  test -r /proc/sys/abi/sve_default_vector_length && cat /proc/sys/abi/sve_default_vector_length || true
  gcc --version 2>/dev/null | head -3 || true
  clang --version 2>/dev/null | head -3 || true
  cmake --version 2>/dev/null | head -3 || true
  ctest --version 2>/dev/null | head -2 || true
  objdump --version 2>/dev/null | head -2 || true
  /usr/bin/time --version 2>/dev/null | head -2 || true
  free -h 2>/dev/null || true
  df -h "$ROOT" 2>/dev/null || true
} > "$OUT/environment.txt" 2>&1

run_shell tool_preflight "set -e; command -v bash python3 gcc cmake ctest sha256sum objdump size tar >/dev/null; test -x /usr/bin/time; python3 -c 'import sys; raise SystemExit(0 if sys.version_info >= (3, 6) else 1)'; cmake --version >/dev/null; ctest --version >/dev/null; gcc --version >/dev/null; objdump --version >/dev/null"
PRECHECK_FAILED=0
if [ "$LAST_RC" -ne 0 ]; then PRECHECK_FAILED=1; OVERALL=2; fi

GATE_FAILED=0
if [ "$PRECHECK_FAILED" -eq 0 ]; then
  run_shell manifest "cd '$ROOT' && bash tools/gates/check_manifest.sh"
  [ "$LAST_RC" -eq 0 ] || GATE_FAILED=1
  run_shell generated_contract "cd '$ROOT' && bash tools/gates/check_generated_artifacts.sh"
  [ "$LAST_RC" -eq 0 ] || GATE_FAILED=1
fi

run_benchmarks() {
  local label=$1
  local build=$2
  shift 2
  local log="$OUT/bench/${label}.log"
  : > "$log"
  local count=0
  local expected=$((BENCH_INSTANCES * BENCH_REPEATS))
  for bench in "$@"; do
    if [ ! -x "$bench" ]; then
      echo "missing benchmark executable: $bench" | tee -a "$log"
      return 1
    fi
    count=$((count + 1))
    local base raw timef
    base=$(basename "$bench")
    raw="$OUT/bench/${label}_${base}.raw.csv"
    timef="$OUT/resource/${label}_${base}.time.txt"
    echo "===== RUN $bench =====" | tee -a "$log"
    /usr/bin/time -v -o "$timef" \
      env HARE_BENCH_INSTANCES="$BENCH_INSTANCES" \
          HARE_BENCH_REPEATS="$BENCH_REPEATS" \
          HARE_BENCH_WARMUP_REPEATS="$BENCH_WARMUP" \
          HARE_BENCH_RAW_CSV="$raw" \
      taskset -c "$CORE" "$bench" 2>&1 | tee -a "$log"
  done
  test "$count" -eq 4 || return 1
  python3 "$ROOT/tools/gates/check_benchmark_matches.py" "$log" --expected-lines 4 --expected-total "$expected"
}

collect_stack_and_sizes() {
  local label=$1
  local build=$2
  find "$build" -type f -name '*.su' -print | sort | while read -r f; do sed 's#^#'"$f"'\t#' "$f"; done > "$OUT/resource/${label}_stack_usage.tsv" || true
  for bench in "$build"/bench_HARE_*; do
    [ -x "$bench" ] || continue
    size "$bench"
  done > "$OUT/resource/${label}_static_sizes.txt" || true
}

run_component_profile_if_enabled() {
  local label=$1
  local build=$2
  shift 2
  if [ "$RUN_COMPONENT_PROFILE" != 1 ]; then
    mkdir -p "$OUT/hotspots/$label"
    echo "status=SKIPPED_RUN_COMPONENT_PROFILE_0" > "$OUT/hotspots/$label/component_profile_status.txt"
    return 0
  fi
  bash "$ROOT/tools/profiling/run_component_hotspots.sh" "$build" "$OUT/hotspots/$label" "$label" "$@"
}

if [ "$PRECHECK_FAILED" -ne 0 ]; then
  echo "toolchain preflight failed; package gates and platform build skipped" | tee "$OUT/failure_summary.txt"
elif [ "$GATE_FAILED" -ne 0 ]; then
  echo "package gate failed; platform build skipped" | tee "$OUT/failure_summary.txt"
elif [ "$MODE" = x86 ]; then
  if ! grep -qm1 -E '(^| )avx2( |$)' /proc/cpuinfo || ! grep -qm1 -E '(^| )pclmulqdq( |$)' /proc/cpuinfo; then
    echo "x86 AVX2/PCLMUL preflight failed" | tee "$OUT/failure_summary.txt"; OVERALL=2
  elif ! command -v taskset >/dev/null 2>&1 || ! taskset -c "$CORE" true >/dev/null 2>&1; then
    echo "x86 taskset/core preflight failed" | tee "$OUT/failure_summary.txt"; OVERALL=2
  else
    BUILD="$OUT/builds/build-x86"
    run_shell x86_configure "cmake -S '$ROOT' -B '$BUILD' -DCMAKE_BUILD_TYPE=Release -DHARE_ENABLE_ARM_SVE=OFF -DCMAKE_C_FLAGS='-fstack-usage'"
    run_shell x86_build "cmake --build '$BUILD' -j'$JOBS'"
    run_shell x86_ctest "ctest --test-dir '$BUILD' --output-on-failure -j'$JOBS'"
    run_shell x86_run_kat "cmake --build '$BUILD' --target run_kat_all -j'$JOBS'"
    run_shell x86_post_kat_manifest "cd '$ROOT' && bash tools/gates/check_manifest.sh"
    run_shell x86_verify_ref_kat "cmake --build '$BUILD' --target verify_kat_all -j'$JOBS'"
    run_shell x86_verify_opt_kat "cmake --build '$BUILD' --target verify_kat_optimized_all -j'$JOBS'"
    run_shell x86_pclmul_audit "python3 '$ROOT/tools/gates/audit_gf2x_instructions.py' --build-dir '$BUILD' --mode x86-pclmul --expected-count 4 --log '$OUT/audit/pclmul.log'"
    run_shell x86_bench_reference_kr "$(declare -f run_benchmarks); run_benchmarks x86_reference_kr '$BUILD' '$BUILD'/bench_HARE_128_kr '$BUILD'/bench_HARE_256_kr '$BUILD'/bench_HARE_384_kr '$BUILD'/bench_HARE_512_kr"
    run_shell x86_bench_optimized_kr "$(declare -f run_benchmarks); run_benchmarks x86_optimized_kr '$BUILD' '$BUILD'/bench_HARE_128_kr_x86 '$BUILD'/bench_HARE_256_kr_x86 '$BUILD'/bench_HARE_384_kr_x86 '$BUILD'/bench_HARE_512_kr_x86"
    run_shell x86_component_profile "$(declare -f run_component_profile_if_enabled); run_component_profile_if_enabled x86_optimized_kr '$BUILD' '$BUILD'/bench_HARE_128_kr_x86 '$BUILD'/bench_HARE_256_kr_x86 '$BUILD'/bench_HARE_384_kr_x86 '$BUILD'/bench_HARE_512_kr_x86"
    run_shell x86_resource_report "$(declare -f collect_stack_and_sizes); collect_stack_and_sizes x86 '$BUILD'; test -s '$OUT/resource/x86_static_sizes.txt'"
    if [ "$RUN_SANITIZERS" = 1 ]; then
      SAN="$OUT/builds/build-x86-sanitize"
      run_shell x86_sanitize_configure "cmake -S '$ROOT' -B '$SAN' -DCMAKE_BUILD_TYPE=Debug -DHARE_ENABLE_ARM_SVE=OFF -DCMAKE_C_FLAGS='-O1 -g -fsanitize=address,undefined -fno-omit-frame-pointer' -DCMAKE_EXE_LINKER_FLAGS='-fsanitize=address,undefined'"
      run_shell x86_sanitize_build "cmake --build '$SAN' -j'$JOBS' --target api_contract_HARE_256_kr api_contract_HARE_256_kr_x86 gf2x_property_HARE_256_kr gf2x_property_HARE_256_kr_x86 code_roundtrip_HARE_256_kr code_roundtrip_HARE_256_kr_x86 rs_boundary_HARE_256_kr rs_boundary_HARE_256_kr_x86 kr_table_HARE_256_kr kr_table_HARE_256_kr_x86 kr_projection_HARE_256_kr kr_projection_HARE_256_kr_x86 kr_systematic_HARE_256_kr kr_systematic_HARE_256_kr_x86 check_HARE_256_kr check_HARE_256_kr_x86 tamper_HARE_256_kr tamper_HARE_256_kr_x86"
      run_shell x86_sanitize_ctest "ASAN_OPTIONS=detect_leaks=0 UBSAN_OPTIONS=halt_on_error=1 ctest --test-dir '$SAN' --output-on-failure -R 'HARE_256_kr'"
    fi
  fi
elif [ "$MODE" = arm ]; then
  if [ "$ARCH" != aarch64 ] && [ "$ARCH" != arm64 ]; then
    echo "AArch64 preflight failed" | tee "$OUT/failure_summary.txt"; OVERALL=2
  elif ! grep -qm1 -w sve /proc/cpuinfo || ! grep -qm1 -w pmull /proc/cpuinfo; then
    echo "ARM SVE/PMULL preflight failed" | tee "$OUT/failure_summary.txt"; OVERALL=2
  elif ! command -v taskset >/dev/null 2>&1 || ! taskset -c "$CORE" true >/dev/null 2>&1; then
    echo "ARM taskset/core preflight failed" | tee "$OUT/failure_summary.txt"; OVERALL=2
  else
    run_shell arm_feature_probe "cd '$ROOT' && bash tools/arm_sve/probe_arm_features.sh"
    ON="$OUT/builds/build-arm-pmull-on"
    OFF="$OUT/builds/build-arm-pmull-off"
    run_shell arm_pmull_on_configure "cmake -S '$ROOT' -B '$ON' -DCMAKE_BUILD_TYPE=Release -DHARE_ENABLE_X86=OFF -DHARE_ENABLE_ARM_SVE=ON -DHARE_ARM_SVE_ENABLE_PMULL=ON -DCMAKE_C_FLAGS='-fstack-usage'"
    run_shell arm_pmull_on_build "cmake --build '$ON' -j'$JOBS'"
    run_shell arm_pmull_on_ctest "ctest --test-dir '$ON' --output-on-failure -j'$JOBS'"
    run_shell arm_pmull_on_run_kat "cmake --build '$ON' --target run_kat_all -j'$JOBS'"
    run_shell arm_pmull_on_manifest "cd '$ROOT' && bash tools/gates/check_manifest.sh"
    run_shell arm_pmull_on_verify_ref_kat "cmake --build '$ON' --target verify_kat_all -j'$JOBS'"
    run_shell arm_pmull_on_verify_opt_kat "cmake --build '$ON' --target verify_kat_optimized_all -j'$JOBS'"
    run_shell arm_pmull_on_audit "python3 '$ROOT/tools/gates/audit_gf2x_instructions.py' --build-dir '$ON' --mode arm-pmull-on --expected-count 4 --log '$OUT/audit/pmull_on.log'"
    run_shell arm_pmull_on_bench_reference_kr "$(declare -f run_benchmarks); run_benchmarks arm_reference_kr_pmull_on '$ON' '$ON'/bench_HARE_128_kr '$ON'/bench_HARE_256_kr '$ON'/bench_HARE_384_kr '$ON'/bench_HARE_512_kr"
    run_shell arm_pmull_on_bench_additional_kr "$(declare -f run_benchmarks); run_benchmarks arm_additional_kr_pmull_on '$ON' '$ON'/bench_HARE_128_kr_arm_sve '$ON'/bench_HARE_256_kr_arm_sve '$ON'/bench_HARE_384_kr_arm_sve '$ON'/bench_HARE_512_kr_arm_sve"
    run_shell arm_pmull_on_component_profile "$(declare -f run_component_profile_if_enabled); run_component_profile_if_enabled arm_additional_kr_pmull_on '$ON' '$ON'/bench_HARE_128_kr_arm_sve '$ON'/bench_HARE_256_kr_arm_sve '$ON'/bench_HARE_384_kr_arm_sve '$ON'/bench_HARE_512_kr_arm_sve"
    run_shell arm_pmull_on_resource_report "$(declare -f collect_stack_and_sizes); collect_stack_and_sizes arm_pmull_on '$ON'; test -s '$OUT/resource/arm_pmull_on_static_sizes.txt'"

    run_shell arm_pmull_off_configure "cmake -S '$ROOT' -B '$OFF' -DCMAKE_BUILD_TYPE=Release -DHARE_ENABLE_X86=OFF -DHARE_ENABLE_ARM_SVE=ON -DHARE_ARM_SVE_ENABLE_PMULL=OFF -DCMAKE_C_FLAGS='-fstack-usage'"
    run_shell arm_pmull_off_build "cmake --build '$OFF' -j'$JOBS'"
    run_shell arm_pmull_off_ctest "ctest --test-dir '$OFF' --output-on-failure -j'$JOBS'"
    run_shell arm_pmull_off_run_kat "cmake --build '$OFF' --target run_kat_all -j'$JOBS'"
    run_shell arm_pmull_off_verify_ref_kat "cmake --build '$OFF' --target verify_kat_all -j'$JOBS'"
    run_shell arm_pmull_off_verify_opt_kat "cmake --build '$OFF' --target verify_kat_optimized_all -j'$JOBS'"
    run_shell arm_pmull_off_audit "python3 '$ROOT/tools/gates/audit_gf2x_instructions.py' --build-dir '$OFF' --mode arm-pmull-off --expected-count 4 --log '$OUT/audit/pmull_off.log'"
    run_shell arm_pmull_off_bench_additional_kr "$(declare -f run_benchmarks); run_benchmarks arm_additional_kr_pmull_off '$OFF' '$OFF'/bench_HARE_128_kr_arm_sve '$OFF'/bench_HARE_256_kr_arm_sve '$OFF'/bench_HARE_384_kr_arm_sve '$OFF'/bench_HARE_512_kr_arm_sve"
    run_shell arm_pmull_off_resource_report "$(declare -f collect_stack_and_sizes); collect_stack_and_sizes arm_pmull_off '$OFF'; test -s '$OUT/resource/arm_pmull_off_static_sizes.txt'"
  fi
else
  echo "unsupported mode/architecture: mode=$MODE arch=$ARCH" | tee "$OUT/failure_summary.txt"
  OVERALL=2
fi

{
  echo "RUNNER_MODE=$MODE"
  echo "RUNNER_EXIT_STATUS=$OVERALL"
  echo "RESULT_DIR=$OUT"
  echo "run_end_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo
  cat "$STATUS_FILE"
} | tee "$OUT/summary.log"

find "$OUT" -type f ! -name 'MANIFEST.sha256' -print0 | sort -z | xargs -0 sha256sum > "$OUT/MANIFEST.sha256" 2>/dev/null || true
exit "$OVERALL"
