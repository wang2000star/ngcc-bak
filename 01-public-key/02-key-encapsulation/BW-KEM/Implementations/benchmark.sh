#!/usr/bin/env bash
# NICCS 自评估一键测速：BW-KEM 三参数集 × 三实现版本（参考/性能优化/资源优化）。
# 产出：
#   benchmark_output/<instance>.<version>.selfeval.log  原始 KEY=VALUE 指标
#   benchmark_output/<instance>.<version>.size.txt       静态内存 (size 工具)
#   benchmark_output/<instance>.<version>.speed.log      函数级微基准 (保留)
#   benchmark_output/selfeval_report.md / selfeval.csv   官方口径自评估报告
#   benchmark_output/speed_report.md                     微基准加速比报告 (保留)
set -uo pipefail

# 本脚本位于 Implementations/ 内：SCRIPT_DIR 即 Implementations，REPO_ROOT 为其上一级仓库根。
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="$REPO_ROOT/benchmark_output"
IMPL="$SCRIPT_DIR"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

# instance | version | dir
CASES=(
  "BW_KEM_C128|reference|$IMPL/Reference_Implementation/BW_KEM_C128"
  "BW_KEM_C256|reference|$IMPL/Reference_Implementation/BW_KEM_C256"
  "BW_KEM_C512|reference|$IMPL/Reference_Implementation/BW_KEM_C512"
  "BW_KEM_C128|performance-optimized|$IMPL/Optimized_Implementation/performance-optimized/BW_KEM_C128_AVX2"
  "BW_KEM_C256|performance-optimized|$IMPL/Optimized_Implementation/performance-optimized/BW_KEM_C256_AVX2"
  "BW_KEM_C512|performance-optimized|$IMPL/Optimized_Implementation/performance-optimized/BW_KEM_C512_AVX2"
  "BW_KEM_C128|resource-optimized|$IMPL/Optimized_Implementation/resource-optimized/BW_KEM_C128_AVX2"
  "BW_KEM_C256|resource-optimized|$IMPL/Optimized_Implementation/resource-optimized/BW_KEM_C256_AVX2"
  "BW_KEM_C512|resource-optimized|$IMPL/Optimized_Implementation/resource-optimized/BW_KEM_C512_AVX2"
)

for entry in "${CASES[@]}"; do
  IFS='|' read -r instance version dir <<< "$entry"
  printf '==> %s (%s)\n' "$instance" "$version"
  make -s -C "$dir" clean >/dev/null 2>&1

  # self-evaluation metrics (functional + perf + resource + sizes)
  make -s -C "$dir" selfeval > "$OUT_DIR/${instance}.${version}.selfeval.log" 2>/dev/null
  # static memory footprint of the selfeval binary
  if [ -f "$dir/build/selfeval" ]; then
    size "$dir/build/selfeval" > "$OUT_DIR/${instance}.${version}.size.txt" 2>/dev/null
  fi
  # function-level micro-benchmark (kept for cross-checking)
  make -s -C "$dir" speed > "$OUT_DIR/${instance}.${version}.speed.log" 2>/dev/null

  make -s -C "$dir" clean >/dev/null 2>&1
done

# Build the micro-benchmark speedup report (reference vs performance-optimized)
# using legacy naming expected by report_speed.py: <instance>.<impl>.log
for entry in "${CASES[@]}"; do
  IFS='|' read -r instance version dir <<< "$entry"
  case "$version" in
    reference)             cp "$OUT_DIR/${instance}.${version}.speed.log" "$OUT_DIR/${instance}.reference.log" 2>/dev/null ;;
    performance-optimized) cp "$OUT_DIR/${instance}.${version}.speed.log" "$OUT_DIR/${instance}.optimized.log" 2>/dev/null ;;
  esac
done
python3 "$SCRIPT_DIR/test/report_speed.py" "$OUT_DIR" "$OUT_DIR/speed_report.md" || true

# Build the NICCS self-evaluation report (all three versions)
python3 "$SCRIPT_DIR/test/report_selfeval.py" "$OUT_DIR" "$OUT_DIR/selfeval_report.md" "$OUT_DIR/selfeval.csv" KEM

printf '==> self-eval report: %s\n' "$OUT_DIR/selfeval_report.md"
printf '==> speed report:     %s\n' "$OUT_DIR/speed_report.md"
