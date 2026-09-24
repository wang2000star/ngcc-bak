#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
cd "$ROOT"

step() {
  printf '[afs-tredm-submission-test] %s\n' "$1"
}

run_timeout() {
  local seconds="$1"
  shift
  timeout "$seconds" "$@"
}

step "shell syntax"
bash -n \
  scripts/ci_correctness_s6.sh \
  scripts/generate_s6_kat.sh \
  scripts/verify_s6_kat.sh \
  scripts/run_full_kat_s6.sh \
  scripts/run_live_perf_tables_s6.sh \
  tools/perf/baselines/run_sha3_kat.sh \
  scripts/final_validation_s6.sh

step "forbidden generated artifacts"
forbidden="$(
  find . \( \
    -path './logs' -o -path './dist' -o -path './tmp' -o \
    -path './validation_logs' -o -path './third_party' -o -name '__pycache__' -o \
    -name '.pytest_cache' -o -name '*.o' -o -name '*.su' -o -name '*.pyc' -o \
    -name 'kat' -o -name 'benchmark' -o -name 'quick_test' -o -name 'hash_cli' -o \
    -name 'sha3_512_reference_c' -o -name 'xkcp_compactfips202_sha3_512' -o -name 'openssl_evp_sha3_512' \
  \) -print
)"
if [ -n "$forbidden" ]; then
  printf '%s\n' "$forbidden"
  exit 1
fi

step "flat KAT package"
PYTHONDONTWRITEBYTECODE=1 python3 tools/verify_s6_kat_package.py \
  --root "$ROOT" --mode full
PYTHONDONTWRITEBYTECODE=1 python3 tools/verify_kat_structure.py

step "S6 specification utility scripts"
PYTHONDONTWRITEBYTECODE=1 python3 tools/gen_s6_iv.py >/dev/null
PYTHONDONTWRITEBYTECODE=1 python3 tools/check_round_constants.py
PYTHONDONTWRITEBYTECODE=1 python3 tools/check_s6_algebra.py

step "live performance metadata"
PYTHONDONTWRITEBYTECODE=1 python3 tools/perf/check_live_metadata.py \
  --root "$ROOT" --live-dir docs/perf/live/latest
PYTHONDONTWRITEBYTECODE=1 python3 tools/verify_s6_perf_report.py \
  --root "$ROOT" \
  --markdown docs/perf/AFS-TrEDM-S6_Performance_Report.md \
  --terminal docs/perf/live/latest/terminal_output.txt \
  --live-raw docs/perf/live/latest/live_perf_raw.csv
(cd docs/perf/live/latest && sha256sum -c sha256sums.txt)

step "SHA3 baseline source manifest"
sha256sum -c docs/sha3_baselines/source_manifest.sha256

step "quick correctness"
run_timeout 900s bash scripts/ci_correctness_s6.sh /tmp/afs_tredm_s6/submission_ci_correctness

step "quick KAT verification"
run_timeout 900s env \
  MODE=quick \
  STAGE_DIR=/tmp/afs_tredm_s6/submission_verify_s6_kat/stage \
  LOG_DIR=/tmp/afs_tredm_s6/submission_verify_s6_kat/logs \
  bash scripts/verify_s6_kat.sh

step "PASS"
