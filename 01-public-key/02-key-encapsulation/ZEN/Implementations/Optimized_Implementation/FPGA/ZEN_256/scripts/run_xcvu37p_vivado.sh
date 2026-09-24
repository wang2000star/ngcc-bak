#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_ROOT="${ROOT_DIR}/build_vivado_xcvu37p"
TCL_SCRIPT="${SCRIPT_DIR}/vivado_xcvu37p_impl.tcl"

VIVADO_BIN="${VIVADO_BIN:-vivado}"
PART_NAME="${XCVU37P_PART:-xcvu37p-fsvh2892-2-e}"
STAGE="synth"
IFACE="raw"
THREADS="${LOWMEM_THREADS:-1}"

SAFE_PERIOD_NS="${SAFE_PERIOD_NS:-5.0}"
BALANCED_PERIOD_NS="${BALANCED_PERIOD_NS:-5.0}"
TIMING_PERIOD_NS="${TIMING_PERIOD_NS:-5.0}"
AGGR_PERIOD_NS="${AGGR_PERIOD_NS:-5.0}"

usage() {
  cat <<'EOF'
usage: run_xcvu37p_vivado.sh [--stage synth|impl|ooc] [--iface raw|axil] [--part <part>] [--threads <n>] [profiles...]

profiles:
  safe
  balanced
  timing
  aggr
  all

examples:
  run_xcvu37p_vivado.sh balanced
  run_xcvu37p_vivado.sh --stage impl --iface axil balanced
  run_xcvu37p_vivado.sh --stage ooc --threads 2 balanced
  BALANCED_PERIOD_NS=4.5 run_xcvu37p_vivado.sh balanced timing
EOF
}

profiles=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --stage)
      STAGE="$2"
      shift 2
      ;;
    --iface)
      IFACE="$2"
      shift 2
      ;;
    --part)
      PART_NAME="$2"
      shift 2
      ;;
    --threads)
      THREADS="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    all)
      profiles=(safe balanced timing aggr)
      shift
      ;;
    safe|balanced|timing|aggr)
      profiles+=("$1")
      shift
      ;;
    *)
      echo "ERROR: unknown argument '$1'" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ "${STAGE}" != "synth" && "${STAGE}" != "impl" && "${STAGE}" != "ooc" ]]; then
  echo "ERROR: --stage must be 'synth', 'impl', or 'ooc'" >&2
  exit 1
fi

if [[ "${IFACE}" != "raw" && "${IFACE}" != "axil" ]]; then
  echo "ERROR: --iface must be 'raw' or 'axil'" >&2
  exit 1
fi

if [[ ${#profiles[@]} -eq 0 ]]; then
  profiles=(balanced)
fi

if [[ -n "${VIVADO_SETTINGS:-}" ]]; then
  # shellcheck disable=SC1090
  source "${VIVADO_SETTINGS}"
fi

if ! command -v "${VIVADO_BIN}" >/dev/null 2>&1; then
  echo "ERROR: '${VIVADO_BIN}' not found in PATH. Please source Vivado settings first." >&2
  exit 127
fi

mkdir -p "${BUILD_ROOT}"

run_profile() {
  local profile="$1"
  local top_name=""
  local clock_port=""
  local period_ns=""

  case "${profile}:${IFACE}" in
    safe:raw)
      top_name="zen_accel_xcvu37p_safe_top"
      clock_port="clk"
      period_ns="${SAFE_PERIOD_NS}"
      ;;
    balanced:raw)
      top_name="zen_accel_xcvu37p_top"
      clock_port="clk"
      period_ns="${BALANCED_PERIOD_NS}"
      ;;
    timing:raw)
      top_name="zen_accel_xcvu37p_timing_top"
      clock_port="clk"
      period_ns="${TIMING_PERIOD_NS}"
      ;;
    aggr:raw)
      top_name="zen_accel_xcvu37p_aggr_top"
      clock_port="clk"
      period_ns="${AGGR_PERIOD_NS}"
      ;;
    safe:axil)
      top_name="zen_accel_xcvu37p_safe_axil_top"
      clock_port="s_axil_aclk"
      period_ns="${SAFE_PERIOD_NS}"
      ;;
    balanced:axil)
      top_name="zen_accel_xcvu37p_axil_top"
      clock_port="s_axil_aclk"
      period_ns="${BALANCED_PERIOD_NS}"
      ;;
    timing:axil)
      top_name="zen_accel_xcvu37p_timing_axil_top"
      clock_port="s_axil_aclk"
      period_ns="${TIMING_PERIOD_NS}"
      ;;
    aggr:axil)
      top_name="zen_accel_xcvu37p_aggr_axil_top"
      clock_port="s_axil_aclk"
      period_ns="${AGGR_PERIOD_NS}"
      ;;
    *)
      echo "ERROR: unsupported combination '${profile}:${IFACE}'" >&2
      exit 1
      ;;
  esac

  local run_name="zen_accel_xcvu37p_${profile}_${IFACE}_${STAGE}"
  local out_dir="${BUILD_ROOT}/${run_name}"
  mkdir -p "${out_dir}"

  echo "[XCVU37P] running ${profile}/${IFACE} (${top_name}, ${PART_NAME}, ${period_ns}ns, stage=${STAGE}, threads=${THREADS})"
  "${VIVADO_BIN}" -mode batch -source "${TCL_SCRIPT}" \
    -tclargs "${top_name}" "${clock_port}" "${PART_NAME}" "${period_ns}" "${out_dir}" "${run_name}" "${STAGE}" "${THREADS}" \
    | tee "${out_dir}/${run_name}.vivado.log"
}

for profile in "${profiles[@]}"; do
  run_profile "${profile}"
done
