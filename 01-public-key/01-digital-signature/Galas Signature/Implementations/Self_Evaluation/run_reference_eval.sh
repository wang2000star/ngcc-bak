#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SELF="$ROOT/Self_Evaluation"
LOGDIR="$SELF/logs"
REPS="${REPS:-100}"
REF_DIR="$ROOT/Implementations/Reference_Implementation/Galas-256S"
LOG="$LOGDIR/reference_bench.log"
CSV="$SELF/results_reference.csv"
SIZECSV="$SELF/static_size_reference.csv"

mkdir -p "$LOGDIR"

{
  echo "date=$(date -Is)"
  echo "reps=$REPS"
  echo "implementation=reference"
  echo "source_dir=$REF_DIR"
  echo
  make -C "$REF_DIR" bench_all REPS="$REPS"
} | tee "$LOG"

awk '
BEGIN {
  FS=",";
  print "implementation,instance,operation,avg_ms,avg_cycles,ops_per_second,pk_bytes,sk_bytes,sig_bytes,peak_rss_kb,reps,msg_len";
}
/^instance=/ {
  inst=substr($0, 10);
}
/^reps=/ {
  reps=msg=pk=sk=sig=rss="";
  n=split($0, fields, /[ ,]+/);
  for (i=1; i<=n; i++) {
    split(fields[i], kv, "=");
    if (kv[1]=="reps") reps=kv[2];
    if (kv[1]=="msg_len") msg=kv[2];
    if (kv[1]=="pk") pk=kv[2];
    if (kv[1]=="sk") sk=kv[2];
    if (kv[1]=="sig") sig=kv[2];
    if (kv[1]=="peak_rss_kb") rss=kv[2];
  }
}
/^(keygen|sign|verify),/ {
  print "reference," inst "," $1 "," $2 "," $3 "," $4 "," pk "," sk "," sig "," rss "," reps "," msg;
}
' "$LOG" > "$CSV"

{
  echo "implementation,instance,text_bytes,data_bytes,bss_bytes,total_dec,total_hex,file"
  for f in /tmp/bench_galas-*; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"
    suffix="${base#bench_galas-}"
    case "$suffix" in
      160s) inst="Galas-160S" ;;
      160f) inst="Galas-160F" ;;
      256s) inst="Galas-256S" ;;
      256f) inst="Galas-256F" ;;
      384s) inst="Galas-384S" ;;
      384f) inst="Galas-384F" ;;
      512s) inst="Galas-512S" ;;
      512f) inst="Galas-512F" ;;
      *) inst="$suffix" ;;
    esac
    size "$f" | awk -v inst="$inst" 'NR==2 {print "reference," inst "," $1 "," $2 "," $3 "," $4 "," $5 "," $6}'
  done
} > "$SIZECSV"

echo "Wrote $CSV"
echo "Wrote $SIZECSV"
