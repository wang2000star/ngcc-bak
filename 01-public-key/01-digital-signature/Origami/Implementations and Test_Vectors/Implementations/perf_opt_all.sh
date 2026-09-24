#!/bin/bash
# Optimized implementation performance only.
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$BASE_DIR/perf_stats_all.sh"
if [ ! -f "$SCRIPT" ]; then
    echo "ERROR: $SCRIPT not found" >&2
    exit 1
fi
IMPL_MODE=opt exec bash "$SCRIPT"
