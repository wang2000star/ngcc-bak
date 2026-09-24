#!/usr/bin/env bash
# 一键验证 BW-KEM 三套参数 reference 与 optimized 实现的 KAT 正确性。
#
# 目录结构（优化实现分为两套 AVX2 变体）：
#   Reference_Implementation/BW_KEM_C{128,256,512}
#   Optimized_Implementation/performance-optimized/BW_KEM_C{128,256,512}_AVX2
#   Optimized_Implementation/resource-optimized/BW_KEM_C{128,256,512}_AVX2
#
# KAT 输出落点：
#   Test_Vector/KAT_KEM_BW_KEM_C<inst>.txt                         (reference)
#   Test_Vector/performance-optimized/KAT_KEM_BW_KEM_C<inst>_AVX2.txt
#   Test_Vector/resource-optimized/KAT_KEM_BW_KEM_C<inst>_AVX2.txt
#
# 步骤：
#   1. 对 C128 / C256 / C512 的 reference、performance-optimized、resource-optimized
#      实现分别 make clean 后 make kat（共 9 次构建）。
#   2. 对每套参数比对 reference 与两套 optimized 生成的 KAT 输出是否逐字节一致
#      （KAT 文件内容不含算法实例名，故正确实现应当 byte-exact）。
#
# 任意一步失败立即退出并打印错误日志。

set -euo pipefail

# 本脚本位于 Implementations/ 内：SCRIPT_DIR 即 Implementations，REPO_ROOT 为其上一级仓库根。
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KAT_DIR="$REPO_ROOT/Test_Vector"
LOG_DIR="$REPO_ROOT/verify_output"

REF_DIR="$SCRIPT_DIR/Reference_Implementation"
PERF_DIR="$SCRIPT_DIR/Optimized_Implementation/performance-optimized"
RES_DIR="$SCRIPT_DIR/Optimized_Implementation/resource-optimized"

rm -rf "$LOG_DIR"
mkdir -p "$LOG_DIR"

color_red()   { printf '\033[31m%s\033[0m\n' "$*"; }
color_green() { printf '\033[32m%s\033[0m\n' "$*"; }
color_blue()  { printf '\033[34m%s\033[0m\n' "$*"; }

run_make() {
  local label="$1"
  local dir="$2"
  local target="$3"
  local log_path="$LOG_DIR/${label}.${target}.log"

  color_blue "==> [$label] make $target ($dir)"
  if [[ ! -d "$dir" ]]; then
    color_red "[$label] directory not found: $dir"
    exit 1
  fi
  if ! make -s -C "$dir" clean >"$log_path" 2>&1; then
    color_red "[$label] make clean failed (see $log_path)"
    tail -n 20 "$log_path"
    exit 1
  fi
  if ! make -s -C "$dir" "$target" >>"$log_path" 2>&1; then
    color_red "[$label] make $target failed (see $log_path)"
    tail -n 20 "$log_path"
    exit 1
  fi
  color_green "[$label] make $target OK"
}

# 比对参考实现 KAT 与某套优化实现 KAT 是否逐字节一致。
compare_kat() {
  local instance="$1"   # 128 / 256 / 512
  local variant="$2"    # performance-optimized / resource-optimized
  local ref_kat="$KAT_DIR/KAT_KEM_BW_KEM_C${instance}.txt"
  local opt_kat="$KAT_DIR/${variant}/KAT_KEM_BW_KEM_C${instance}_AVX2.txt"

  color_blue "==> [C$instance vs $variant] compare KAT"
  if [[ ! -f "$ref_kat" ]]; then
    color_red "[C$instance] missing reference KAT: $ref_kat"
    exit 1
  fi
  if [[ ! -f "$opt_kat" ]]; then
    color_red "[C$instance/$variant] missing optimized KAT: $opt_kat"
    exit 1
  fi
  if cmp -s "$ref_kat" "$opt_kat"; then
    color_green "[C$instance vs $variant] KAT byte-exact match"
  else
    color_red "[C$instance vs $variant] KAT MISMATCH between $ref_kat and $opt_kat"
    diff <(head -n 20 "$ref_kat") <(head -n 20 "$opt_kat") || true
    exit 1
  fi
}

# --- Step 1: build & run KAT for reference + two optimized variants of each parameter set.
for inst in 128 256 512; do
  run_make "C${inst}.ref"  "$REF_DIR/BW_KEM_C${inst}"            kat
  run_make "C${inst}.perf" "$PERF_DIR/BW_KEM_C${inst}_AVX2"      kat
  run_make "C${inst}.res"  "$RES_DIR/BW_KEM_C${inst}_AVX2"       kat
done

# --- Step 2: compare KAT files between reference and each optimized variant.
for inst in 128 256 512; do
  compare_kat "$inst" performance-optimized
  compare_kat "$inst" resource-optimized
done

color_green "==> All KAT correctness checks passed (byte-exact: reference vs performance-optimized and resource-optimized)."
color_blue  "Logs are stored under: $LOG_DIR"
