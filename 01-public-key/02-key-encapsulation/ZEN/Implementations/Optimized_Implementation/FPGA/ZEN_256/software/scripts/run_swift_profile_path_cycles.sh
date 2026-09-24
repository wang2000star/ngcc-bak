#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage:
  software/scripts/run_swift_profile_path_cycles.sh [options] [profile ...]

Options:
  --board <xcvu37p|xcv80>
                           select board family, default xcvu37p
  --swift <256>          only swift256 is supported in this workspace
  --summary-md <path>    write markdown summary table
  --summary-csv <path>   write csv summary table
  --verbose              stream compile/sim logs to stdout

Profiles:
  safe balanced timing aggr all

Examples:
  run_swift_profile_path_cycles.sh --swift 256 balanced
  run_swift_profile_path_cycles.sh balanced
EOF
}

args=()
while [ "$#" -gt 0 ]; do
  case "$1" in
    --swift)
      if [ "$#" -lt 2 ]; then
        printf 'Missing argument for %s\n' "$1" >&2
        usage >&2
        exit 1
      fi
      if [ "$2" != "256" ]; then
        printf 'This workspace only supports --swift 256 (got %s)\n' "$2" >&2
        exit 1
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done

exec "${SCRIPT_DIR}/run_profile_path_cycles.sh" "${args[@]}"
