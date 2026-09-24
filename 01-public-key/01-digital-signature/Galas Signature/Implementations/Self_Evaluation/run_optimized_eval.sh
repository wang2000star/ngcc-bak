#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SELF="$ROOT/Self_Evaluation"
LOGDIR="$SELF/logs"
REPS="${REPS:-100}"
OPT_DIR="$ROOT/Implementations/Optimized_Implementation/Galas-256S"
BUILD="$OPT_DIR/build_eval"
LOG="$LOGDIR/optimized_bench.log"
CSV="$SELF/results_optimized.csv"
SIZECSV="$SELF/static_size_optimized.csv"

mkdir -p "$LOGDIR"

{
  echo "date=$(date -Is)"
  echo "reps=$REPS"
  echo "implementation=optimized"
  echo "source_dir=$OPT_DIR"
  echo
  if [ -d "$BUILD" ]; then
    meson setup "$BUILD" "$OPT_DIR" --buildtype=release -Doptimization=3 --wipe
  else
    meson setup "$BUILD" "$OPT_DIR" --buildtype=release -Doptimization=3
  fi
  ninja -C "$BUILD" galas_bench
  "$BUILD/galas_bench" all "$REPS"
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
  print "optimized," inst "," $1 "," $2 "," $3 "," $4 "," pk "," sk "," sig "," rss "," reps "," msg;
}
' "$LOG" > "$CSV"

{
  echo "implementation,instance,text_bytes,data_bytes,bss_bytes,total_dec,total_hex,file"
  size "$BUILD/galas_bench" | awk 'NR==2 {print "optimized,all," $1 "," $2 "," $3 "," $4 "," $5 "," $6}'
} > "$SIZECSV"

echo "Wrote $CSV"
echo "Wrote $SIZECSV"
