#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: run_lore_measurements.sh {shake|sm3} {size|cycles|all}

Examples:
  ./bench/run_lore_measurements.sh shake all
  ./bench/run_lore_measurements.sh sm3 cycles

Environment overrides are forwarded to the backend-specific script:
  LEVELS, TRIALS, ITERS, WARMUP, CORE
USAGE
}

if [ "$#" -lt 2 ]; then
    usage
    exit 1
fi

BACKEND="$1"
MODE="$2"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

case "$BACKEND" in
    shake|SHAKE)
        exec "$ROOT/bench/run_lore_shake_measurements.sh" "$MODE"
        ;;
    sm3|SM3)
        exec "$ROOT/bench/run_lore_sm3_measurements.sh" "$MODE"
        ;;
    *)
        usage
        exit 1
        ;;
esac
