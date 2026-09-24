#!/usr/bin/env bash
# 一键验证 AFS-KEX 三套参数 reference 与 optimized(AVX2) 实现的 KAT 正确性。
#
# 步骤：
#   1. 对 C128 / C256 / C512 的 Reference 与 AVX2 Optimized 实现分别 make clean 后 make kat。
#   2. 对每套参数比对 reference 与 optimized 生成的 KAT 输出是否逐字节一致。
#
# 任意一步失败立即退出并打印错误日志。

set -euo pipefail

# 本脚本位于 Implementations/ 内：SCRIPT_DIR 即 Implementations，REPO_ROOT 为其上一级仓库根。
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KAT_DIR="$REPO_ROOT/Test_Vector"
OPT_KAT_DIR="$SCRIPT_DIR/Test_Vector/performance-optimized"
LOG_DIR="$REPO_ROOT/verify_output"

REF_C128="$SCRIPT_DIR/Reference_Implementation/AFS_KEX_C128"
REF_C256="$SCRIPT_DIR/Reference_Implementation/AFS_KEX_C256"
REF_C512="$SCRIPT_DIR/Reference_Implementation/AFS_KEX_C512"
OPT_C128="$SCRIPT_DIR/Optimized_Implementation/performance-optimized/AFS_KEX_C128_AVX2"
OPT_C256="$SCRIPT_DIR/Optimized_Implementation/performance-optimized/AFS_KEX_C256_AVX2"
OPT_C512="$SCRIPT_DIR/Optimized_Implementation/performance-optimized/AFS_KEX_C512_AVX2"

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

compare_kat() {
  local instance="$1"
  local ref_kat="$KAT_DIR/KAT_KEX_AFS_KEX_${instance}.txt"
  local opt_kat="$OPT_KAT_DIR/KAT_KEX_AFS_KEX_${instance}_AVX2.txt"

  color_blue "==> [$instance] compare KAT"
  if [[ ! -f "$ref_kat" ]]; then
    color_red "[$instance] missing reference KAT: $ref_kat"
    exit 1
  fi
  if [[ ! -f "$opt_kat" ]]; then
    color_red "[$instance] missing optimized KAT: $opt_kat"
    exit 1
  fi
  if cmp -s "$ref_kat" "$opt_kat"; then
    color_green "[$instance] KAT byte-exact match"
  else
    color_red "[$instance] KAT MISMATCH between $ref_kat and $opt_kat"
    diff <(head -n 20 "$ref_kat") <(head -n 20 "$opt_kat") || true
    exit 1
  fi
}

# --- Step 1: build & run KAT for reference and optimized of each parameter set.
run_make C128.ref       "$REF_C128" kat
run_make C128.optimized "$OPT_C128" kat
run_make C256.ref       "$REF_C256" kat
run_make C256.optimized "$OPT_C256" kat
run_make C512.ref       "$REF_C512" kat
run_make C512.optimized "$OPT_C512" kat

# --- Step 2: compare KAT files between reference and optimized.
compare_kat C128
compare_kat C256
compare_kat C512

color_green "==> All KAT correctness checks passed (byte-exact between reference and optimized)."
color_blue  "Logs are stored under: $LOG_DIR"
