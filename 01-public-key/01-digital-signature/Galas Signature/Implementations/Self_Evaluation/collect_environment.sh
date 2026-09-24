#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/Self_Evaluation/environment.txt"

{
  echo "date=$(date -Is)"
  echo
  echo "[uname]"
  uname -a
  echo
  echo "[lscpu]"
  lscpu
  echo
  echo "[memory]"
  free -h || true
  echo
  echo "[gcc]"
  gcc --version | head -n 1
  echo
  echo "[g++]"
  g++ --version | head -n 1
  echo
  echo "[make]"
  make --version | head -n 1
  echo
  echo "[meson]"
  meson --version
  echo
  echo "[ninja]"
  ninja --version
} > "$OUT"

echo "Wrote $OUT"
