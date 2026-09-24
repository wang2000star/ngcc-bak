#!/usr/bin/env bash
set -euo pipefail

ROOT=""
ARGS=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --root)
      ROOT="$2"
      ARGS+=("$1" "$2")
      shift 2
      ;;
    --root=*)
      ROOT="${1#--root=}"
      ARGS+=("$1")
      shift
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done

if [ -z "$ROOT" ]; then
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  ARGS=(--root "$ROOT" "${ARGS[@]}")
fi

python3 "$ROOT/tools/perf/live_perf_table.py" "${ARGS[@]}"
