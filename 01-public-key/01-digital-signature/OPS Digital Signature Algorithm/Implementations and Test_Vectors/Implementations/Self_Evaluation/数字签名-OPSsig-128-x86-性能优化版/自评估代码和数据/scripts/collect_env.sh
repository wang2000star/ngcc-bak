#!/usr/bin/env bash
set -euo pipefail

emit_kv() {
  printf '%s,%s\n' "$1" "$2"
}

trim() {
  sed 's/^[[:space:]]*//; s/[[:space:]]*$//'
}

timestamp_utc="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cpu_model="$(awk -F: '/model name/ {print $2; exit}' /proc/cpuinfo | trim || true)"
cpu_mhz="$(awk -F: '/cpu MHz/ {print $2; exit}' /proc/cpuinfo | trim || true)"
cpu_cores="$(nproc --all 2>/dev/null || echo unknown)"
mem_total_kb="$(awk '/MemTotal/ {print $2; exit}' /proc/meminfo || echo unknown)"
kernel_version="$(uname -r)"
arch_name="$(uname -m)"
gcc_version="$(gcc --version 2>/dev/null | head -n 1 || echo unavailable)"
cmake_version="$(cmake --version 2>/dev/null | head -n 1 || echo unavailable)"
make_version="$(make --version 2>/dev/null | head -n 1 || echo unavailable)"
time_version="$(/usr/bin/time --version 2>/dev/null | head -n 1 || echo unavailable)"

if [[ -f /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  os_pretty="${PRETTY_NAME:-unknown}"
else
  os_pretty="unknown"
fi

if grep -m1 -q ' avx2 ' /proc/cpuinfo; then
  avx2_support="yes"
else
  avx2_support="no"
fi

emit_kv "key" "value"
emit_kv "timestamp_utc" "$timestamp_utc"
emit_kv "architecture" "$arch_name"
emit_kv "cpu_model" "$cpu_model"
emit_kv "cpu_mhz" "$cpu_mhz"
emit_kv "logical_cores" "$cpu_cores"
emit_kv "memory_total_kb" "$mem_total_kb"
emit_kv "avx2_support" "$avx2_support"
emit_kv "os" "$os_pretty"
emit_kv "kernel" "$kernel_version"
emit_kv "gcc" "$gcc_version"
emit_kv "cmake" "$cmake_version"
emit_kv "make" "$make_version"
emit_kv "time" "$time_version"
