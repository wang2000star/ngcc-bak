#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MODE="${MODE:-full}"
STAGE_DIR="${STAGE_DIR:-/tmp/afs_tredm_s6/verify_s6_kat/stage}"
LOG_DIR="${LOG_DIR:-/tmp/afs_tredm_s6/verify_s6_kat/logs}"
mkdir -p "$STAGE_DIR" "$LOG_DIR"

have_cpu_flag() {
  local flag="$1"
  grep -m1 '^flags' /proc/cpuinfo 2>/dev/null | grep -qw "$flag"
}

lengths_for_instance() {
  case "$1" in
    512) echo "0,1,7,8,9,24,1023,1024,1025,512,1024,8192,65536,1048576" ;;
    768) echo "0,1,7,8,9,24,767,768,769,512,1024,8192,65536,1048576" ;;
    1024) echo "0,1,7,8,9,24,511,512,513,512,1024,8192,65536,1048576" ;;
  esac
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

PYTHONDONTWRITEBYTECODE=1 python3 "$ROOT/tools/verify_s6_kat_package.py" \
  --root "$ROOT" --mode "$MODE" --json-out "$STAGE_DIR/kat_package_verify.json" \
  > "$STAGE_DIR/kat_package_verify.txt"

AVX2_OK=0
AVX512F_OK=0
if have_cpu_flag avx2; then
  AVX2_OK=1
fi
if have_cpu_flag avx512f; then
  AVX512F_OK=1
fi

for inst in 512 768 1024; do
  ref_dir="$ROOT/Implementations/Reference_Implementation/AFS-TrEDM-$inst"
  opt_dir="$ROOT/Implementations/Optimized_Implementation/AFS-TrEDM-$inst"
  batch_dir="$ROOT/Implementations/Additional_Implementation/Batch_Multibuffer/AFS-TrEDM-$inst"
  inst_log="$LOG_DIR/verify_s6_kat/AFS-TrEDM-$inst"
  lengths="$(lengths_for_instance "$inst")"
  mkdir -p "$inst_log"

  log_run "$inst_log/reference_build_hash_cli.log" make -C "$ref_dir" clean hash_cli
  log_run "$inst_log/optimized_build_hash_cli.log" make -C "$opt_dir" clean hash_cli hash_cli_dispatch

  log_run "$inst_log/compare_opt64.log" python3 "$ROOT/tools/compare_ref_opt_s6.py" \
    --root "$ROOT" --instance "$inst" --mode opt64 \
    --lengths "$lengths" --include-rate-boundaries --random 4 \
    --out "$inst_log/compare_opt64.json"

  log_run "$inst_log/compare_dispatch.log" python3 "$ROOT/tools/compare_ref_opt_s6.py" \
    --root "$ROOT" --instance "$inst" --mode dispatch \
    --lengths "$lengths" --include-rate-boundaries --random 4 \
    --out "$inst_log/compare_dispatch.json"

  if [ "$AVX2_OK" = "1" ]; then
    log_run "$inst_log/optimized_build_avx2.log" make -C "$opt_dir" hash_cli_avx2
    log_run "$inst_log/compare_avx2.log" python3 "$ROOT/tools/compare_ref_opt_s6.py" \
      --root "$ROOT" --instance "$inst" --mode avx2 \
      --lengths "$lengths" --include-rate-boundaries --random 4 \
      --out "$inst_log/compare_avx2.json"
  else
    printf 'SKIPPED: AVX2 runtime support unavailable\n' >"$inst_log/compare_avx2.log"
  fi

  log_run "$inst_log/batch_build_fallback.log" make -C "$batch_dir" clean batch_quick_test_fallback
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

SCAN_STATUS=PASS
python3 "$ROOT/tools/scan_submission_artifacts.py" \
  --root "$ROOT" --json-out "$STAGE_DIR/scan_after_verify.json" \
  > "$STAGE_DIR/scan_after_verify.txt" || SCAN_STATUS=NON_BLOCKING_FINDINGS

{
  echo "S6 KAT verification PASS"
  echo "mode=$MODE"
  echo "avx2_runtime=$AVX2_OK"
  echo "avx512f_runtime=$AVX512F_OK"
  echo "artifact_scan_status=$SCAN_STATUS"
} >"$STAGE_DIR/verify_s6_kat_summary.txt"
cat "$STAGE_DIR/verify_s6_kat_summary.txt"
