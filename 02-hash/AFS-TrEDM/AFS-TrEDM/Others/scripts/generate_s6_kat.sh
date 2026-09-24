#!/usr/bin/env bash
set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
MODE="${MODE:-full}"
STAGE_DIR="${STAGE_DIR:-/tmp/afs_tredm_s6/generate_s6_kat/stage}"
LOG_DIR="${LOG_DIR:-/tmp/afs_tredm_s6/generate_s6_kat/logs}"
TV_ROOT="$ROOT/Test_Vectors"

if [ "$MODE" != "full" ]; then
  echo "INFO: exact ICCS KAT_CryptHash.c is retained; MODE=$MODE is treated as full." >&2
fi

mkdir -p "$STAGE_DIR" "$LOG_DIR" "$TV_ROOT"

copy_generated_files() {
  local ref_dir="$1"
  local instance_name="$2"
  cp "$ref_dir/output/KAT_2_12_${instance_name}.txt" "$TV_ROOT/KAT_2_12_${instance_name}.txt"
  cp "$ref_dir/output/KAT_2_23_${instance_name}.txt" "$TV_ROOT/KAT_2_23_${instance_name}.txt"
  cp "$ref_dir/output/KAT_2_33_${instance_name}.txt" "$TV_ROOT/KAT_2_33_${instance_name}.txt"
  cp "$ref_dir/output/KAT_Loop_${instance_name}.txt" "$TV_ROOT/KAT_Loop_${instance_name}.txt"
}

for inst in 512 768 1024; do
  instance_name="AFS-TrEDM-$inst"
  ref_dir="$ROOT/Implementations/Reference_Implementation/$instance_name"
  inst_log="$LOG_DIR/generate_${inst}_full.log"

  {
    echo "instance=$inst"
    echo "mode=full"
    echo "layout=flat-submission"
    echo "generator=exact-ICCS-KAT_CryptHash.c"
    make -C "$ref_dir" clean
    make -C "$ref_dir" CFLAGS="-std=c99 -O3 -Wall -Wextra -pedantic" kat
    (cd "$ref_dir" && ./kat)
    copy_generated_files "$ref_dir" "$instance_name"
    make -C "$ref_dir" clean
  } >"$inst_log" 2>&1
done

cat >"$STAGE_DIR/KAT_SHA256SUMS.txt" <<EOF
# SHA-256 for submitted flat Test_Vectors files generated or present after this run.
EOF
(
  cd "$ROOT"
  find Test_Vectors -maxdepth 1 -type f -name 'KAT_*.txt' -print | sort | xargs sha256sum
) >>"$STAGE_DIR/KAT_SHA256SUMS.txt"

cat >"$TV_ROOT/README.txt" <<'EOF'
AFS-TrEDM Test_Vectors
======================

This directory contains the known-answer test vectors required for all submitted
AFS-TrEDM algorithm instances.

File naming follows the ICCS submission layout:
  KAT_2_12_[AlgorithmInstance].txt
      Digests for messages with lengths from 0 to 2^12 bits.
  KAT_2_23_[AlgorithmInstance].txt
      Digests for 2^23-bit messages.
  KAT_2_33_[AlgorithmInstance].txt
      Digests for 2^33-bit messages.
  KAT_Loop_[AlgorithmInstance].txt
      Loop-test result for 2^13-bit messages.

Submitted algorithm instances:
  AFS-TrEDM-512
  AFS-TrEDM-768
  AFS-TrEDM-1024

Regeneration:
  MODE=full bash scripts/generate_s6_kat.sh

Notes:
  The per-instance KAT_CryptHash.c files are kept byte-identical to the ICCS
  API_CryptHash.zip helper. Therefore each run of ./kat generates all four
  required KAT files into the instance-local output/ directory; the script then
  copies them into this flat Test_Vectors directory.

Verification:
  MODE=full bash scripts/verify_s6_kat.sh
EOF

echo "S6 KAT generation finished: MODE=full layout=flat-submission"
echo "Checksums written to $STAGE_DIR/KAT_SHA256SUMS.txt"
