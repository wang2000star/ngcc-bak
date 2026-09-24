#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="${1:-/tmp/afs_tredm_s6/ci_correctness}"
mkdir -p "$LOG_DIR"

have_cpu_flag() {
  local flag="$1"
  grep -m1 '^flags' /proc/cpuinfo 2>/dev/null | grep -qw "$flag"
}

log_run() {
  local log_file="$1"
  shift
  mkdir -p "$(dirname "$log_file")"
  {
    printf 'COMMAND:'
    printf ' %q' "$@"
    printf '\n'
    "$@"
  } >"$log_file" 2>&1
}

INSTANCES=(512 768 1024)
AVX2_OK=0
AVX512F_OK=0
if have_cpu_flag avx2; then
  AVX2_OK=1
fi
if have_cpu_flag avx512f; then
  AVX512F_OK=1
fi

{
  printf 'S6 correctness CI\n'
  printf 'root=%s\n' "$ROOT"
  printf 'avx2_runtime=%s\n' "$AVX2_OK"
  printf 'avx512f_runtime=%s\n' "$AVX512F_OK"
  printf 'instances=%s\n' "${INSTANCES[*]}"
} >"$LOG_DIR/summary.txt"

for inst in "${INSTANCES[@]}"; do
  ref_dir="$ROOT/Implementations/Reference_Implementation/AFS-TrEDM-$inst"
  opt_dir="$ROOT/Implementations/Optimized_Implementation/AFS-TrEDM-$inst"
  batch_dir="$ROOT/Implementations/Additional_Implementation/Batch_Multibuffer/AFS-TrEDM-$inst"
  inst_log="$LOG_DIR/AFS-TrEDM-$inst"
  mkdir -p "$inst_log"

  log_run "$inst_log/reference_clean_before.log" make -C "$ref_dir" clean
  log_run "$inst_log/reference_build.log" make -C "$ref_dir" quick_test hash_cli
  log_run "$inst_log/reference_quick.log" "$ref_dir/quick_test"

  log_run "$inst_log/optimized_clean_before.log" make -C "$opt_dir" clean
  log_run "$inst_log/optimized_build.log" make -C "$opt_dir" quick_test hash_cli quick_test_dispatch hash_cli_dispatch
  log_run "$inst_log/optimized_quick.log" "$opt_dir/quick_test"
  log_run "$inst_log/optimized_dispatch_portable_quick.log" env AFS_TREDM_DISPATCH_FORCE=portable "$opt_dir/quick_test_dispatch"

  if [ "$AVX2_OK" = "1" ]; then
    log_run "$inst_log/optimized_avx2_build.log" make -C "$opt_dir" quick_test_avx2 hash_cli_avx2
    log_run "$inst_log/optimized_avx2_quick.log" "$opt_dir/quick_test_avx2"
    log_run "$inst_log/optimized_dispatch_avx2_quick.log" env AFS_TREDM_DISPATCH_FORCE=avx2 "$opt_dir/quick_test_dispatch"
  else
    printf 'SKIPPED: AVX2 runtime support unavailable\n' >"$inst_log/optimized_avx2_quick.log"
    printf 'SKIPPED: AVX2 runtime support unavailable\n' >"$inst_log/optimized_dispatch_avx2_quick.log"
  fi

  log_run "$inst_log/compare_opt64.log" python3 "$ROOT/tools/compare_ref_opt_s6.py" \
    --root "$ROOT" --instance "$inst" --mode opt64 \
    --lengths 0,1,7,8,9,24,512,1024,8192,65536 --random 4 \
    --out "$inst_log/compare_opt64.json"
  log_run "$inst_log/compare_dispatch.log" python3 "$ROOT/tools/compare_ref_opt_s6.py" \
    --root "$ROOT" --instance "$inst" --mode dispatch \
    --lengths 0,1,7,8,9,24,512,1024,8192,65536 --random 4 \
    --out "$inst_log/compare_dispatch.json"

  if [ "$AVX2_OK" = "1" ]; then
    log_run "$inst_log/compare_avx2.log" python3 "$ROOT/tools/compare_ref_opt_s6.py" \
      --root "$ROOT" --instance "$inst" --mode avx2 \
      --lengths 0,1,7,8,9,24,512,1024,8192,65536 --random 4 \
      --out "$inst_log/compare_avx2.json"
  else
    printf 'SKIPPED: AVX2 runtime support unavailable\n' >"$inst_log/compare_avx2.log"
  fi

  log_run "$inst_log/batch_clean_before.log" make -C "$batch_dir" clean
  log_run "$inst_log/batch_build_fallback.log" make -C "$batch_dir" batch_quick_test_fallback
  log_run "$inst_log/batch_fallback_quick.log" "$batch_dir/batch_quick_test_fallback"

  if [ "$AVX2_OK" = "1" ]; then
    log_run "$inst_log/batch_build_avx2.log" make -C "$batch_dir" batch_quick_test
    log_run "$inst_log/batch_avx2_quick.log" "$batch_dir/batch_quick_test"
  else
    printf 'SKIPPED: AVX2 runtime support unavailable\n' >"$inst_log/batch_avx2_quick.log"
  fi

  if [ "$AVX2_OK" = "1" ] && [ "$AVX512F_OK" = "1" ]; then
    log_run "$inst_log/batch16_avx512_build.log" make -C "$batch_dir" quick_test_batch16_avx512 batch16_avx512_selftest
    log_run "$inst_log/batch16_avx512_quick.log" "$batch_dir/quick_test_batch16_avx512"
    log_run "$inst_log/batch16_avx512_selftest.log" "$batch_dir/batch16_avx512_selftest"
  else
    printf 'SKIPPED: AVX512F runtime support unavailable\n' >"$inst_log/batch16_avx512_quick.log"
    printf 'SKIPPED: AVX512F runtime support unavailable\n' >"$inst_log/batch16_avx512_selftest.log"
  fi

  log_run "$inst_log/reference_clean_after.log" make -C "$ref_dir" clean
  log_run "$inst_log/optimized_clean_after.log" make -C "$opt_dir" clean
  log_run "$inst_log/batch_clean_after.log" make -C "$batch_dir" clean
done

printf 'PASS\n' >>"$LOG_DIR/summary.txt"
cat "$LOG_DIR/summary.txt"
