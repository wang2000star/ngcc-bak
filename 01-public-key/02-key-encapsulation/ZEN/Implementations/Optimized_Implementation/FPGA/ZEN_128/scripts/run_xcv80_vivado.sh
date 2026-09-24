#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_ROOT="${ROOT_DIR}/build_vivado_xcv80"
TCL_SCRIPT="${SCRIPT_DIR}/vivado_xcv80_impl.tcl"

VIVADO_BIN="${VIVADO_BIN:-}"
PART_NAME="${XCV80_PART:-xcv80-lsva4737-2MHP-e-S}"
REQUIRED_VIVADO_VERSION="${REQUIRED_VIVADO_VERSION:-2025.1}"
STAGE="synth"
IFACE="raw"
THREADS="${LOWMEM_THREADS:-1}"

SAFE_PERIOD_NS="${SAFE_PERIOD_NS:-5.0}"
BALANCED_PERIOD_NS="${BALANCED_PERIOD_NS:-5.0}"
TIMING_PERIOD_NS="${TIMING_PERIOD_NS:-5.0}"
AGGR_PERIOD_NS="${AGGR_PERIOD_NS:-5.0}"

pick_vivado_bin() {
  local expected_version="$1"
  local candidate=""
  local version_string=""
  local -a candidates=()

  if [[ -n "${VIVADO_BIN}" ]]; then
    candidates+=("${VIVADO_BIN}")
  fi

  candidates+=(
    "/tools/Xilinx/Vivado/${expected_version}/bin/vivado"
    "/opt/Xilinx/Vivado/${expected_version}/bin/vivado"
    "/home/opt/Xilinx/Vivado/${expected_version}/bin/vivado"
    "/home/opt/Xilinx/Vivado_25.1/Vivado/bin/vivado"
  )

  if [[ -n "${XILINX_VIVADO:-}" ]]; then
    candidates+=("${XILINX_VIVADO}/bin/vivado")
  fi

  if command -v vivado >/dev/null 2>&1; then
    candidates+=("$(command -v vivado)")
  fi

  for candidate in "${candidates[@]}"; do
    [[ -n "${candidate}" ]] || continue
    [[ -x "${candidate}" ]] || continue
    version_string="$("${candidate}" -version 2>/dev/null | head -n 1 || true)"
    if [[ "${version_string}" == *"${expected_version}"* ]]; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  done

  return 1
}

usage() {
  cat <<'EOF'
usage: run_xcv80_vivado.sh [--stage synth|impl|ooc] [--iface raw|axil] [--part <part>] [--threads <n>] [profiles...]

profiles:
  safe
  balanced
  timing
  aggr
  all

examples:
  run_xcv80_vivado.sh balanced
  run_xcv80_vivado.sh --stage impl --iface axil balanced
  run_xcv80_vivado.sh --stage ooc --threads 2 balanced
  BALANCED_PERIOD_NS=4.5 run_xcv80_vivado.sh balanced timing
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

if [[ "${STAGE}" == "oo" ]]; then
  STAGE="ooc"
fi

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

VIVADO_BIN="$(pick_vivado_bin "${REQUIRED_VIVADO_VERSION}")" || {
  echo "ERROR: unable to locate Vivado ${REQUIRED_VIVADO_VERSION} for xcv80 synthesis/implementation." >&2
  echo "ERROR: set VIVADO_BIN or source the correct Vivado 2025.1 environment first." >&2
  exit 127
}

mkdir -p "${BUILD_ROOT}"

run_profile() {
  local profile="$1"
  local top_name=""
  local clock_port=""
  local period_ns=""

  case "${profile}:${IFACE}" in
    safe:raw)
      top_name="zen_accel_xcv80_safe_top"
      clock_port="clk"
      period_ns="${SAFE_PERIOD_NS}"
      ;;
    balanced:raw)
      top_name="zen_accel_xcv80_top"
      clock_port="clk"
      period_ns="${BALANCED_PERIOD_NS}"
      ;;
    timing:raw)
      top_name="zen_accel_xcv80_timing_top"
      clock_port="clk"
      period_ns="${TIMING_PERIOD_NS}"
      ;;
    aggr:raw)
      top_name="zen_accel_xcv80_aggr_top"
      clock_port="clk"
      period_ns="${AGGR_PERIOD_NS}"
      ;;
    safe:axil)
      top_name="zen_accel_xcv80_safe_axil_top"
      clock_port="s_axil_aclk"
      period_ns="${SAFE_PERIOD_NS}"
      ;;
    balanced:axil)
      top_name="zen_accel_xcv80_axil_top"
      clock_port="s_axil_aclk"
      period_ns="${BALANCED_PERIOD_NS}"
      ;;
    timing:axil)
      top_name="zen_accel_xcv80_timing_axil_top"
      clock_port="s_axil_aclk"
      period_ns="${TIMING_PERIOD_NS}"
      ;;
    aggr:axil)
      top_name="zen_accel_xcv80_aggr_axil_top"
      clock_port="s_axil_aclk"
      period_ns="${AGGR_PERIOD_NS}"
      ;;
    *)
      echo "ERROR: unsupported combination '${profile}:${IFACE}'" >&2
      exit 1
      ;;
  esac

  local run_name="zen_accel_xcv80_${profile}_${IFACE}_${STAGE}"
  local out_dir="${BUILD_ROOT}/${run_name}"
  mkdir -p "${out_dir}"

  echo "[XCV80] running ${profile}/${IFACE} (${top_name}, ${PART_NAME}, ${period_ns}ns, stage=${STAGE}, threads=${THREADS})"
  "${VIVADO_BIN}" -mode batch -source "${TCL_SCRIPT}" \
    -tclargs "${top_name}" "${clock_port}" "${PART_NAME}" "${period_ns}" "${out_dir}" "${run_name}" "${STAGE}" "${THREADS}" "${profile}" \
    | tee "${out_dir}/${run_name}.vivado.log"
}

for profile in "${profiles[@]}"; do
  run_profile "${profile}"
done
