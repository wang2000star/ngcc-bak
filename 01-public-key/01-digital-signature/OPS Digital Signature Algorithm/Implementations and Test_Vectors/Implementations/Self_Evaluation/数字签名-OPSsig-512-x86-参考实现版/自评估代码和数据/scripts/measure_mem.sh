#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <binary>" >&2
  exit 1
fi

binary="$1"
if [[ ! -f "$binary" ]]; then
  echo "binary not found: $binary" >&2
  exit 1
fi

if size -A "$binary" >/dev/null 2>&1; then
  size_out="$(size -A "$binary")"
else
  size_out="$(size "$binary")"
fi

text_bytes="$(printf '%s\n' "$size_out" | awk '$1 == ".text" {sum += $2} END {print sum + 0}')"
rodata_bytes="$(printf '%s\n' "$size_out" | awk '$1 == ".rodata" {sum += $2} END {print sum + 0}')"
data_bytes="$(printf '%s\n' "$size_out" | awk '$1 == ".data" {sum += $2} END {print sum + 0}')"
bss_bytes="$(printf '%s\n' "$size_out" | awk '$1 == ".bss" {sum += $2} END {print sum + 0}')"
static_total_bytes=$((text_bytes + rodata_bytes + data_bytes + bss_bytes))

printf '%s,%s\n' "metric" "value"
printf '%s,%s\n' "binary" "$binary"
printf '%s,%s\n' "text_bytes" "$text_bytes"
printf '%s,%s\n' "rodata_bytes" "$rodata_bytes"
printf '%s,%s\n' "data_bytes" "$data_bytes"
printf '%s,%s\n' "bss_bytes" "$bss_bytes"
printf '%s,%s\n' "static_total_bytes" "$static_total_bytes"
