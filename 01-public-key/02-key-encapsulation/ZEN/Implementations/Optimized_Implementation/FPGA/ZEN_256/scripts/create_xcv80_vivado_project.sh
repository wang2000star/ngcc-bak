#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TCL_SCRIPT="${SCRIPT_DIR}/create_xcv80_vivado_project.tcl"
VIVADO_BIN="${VIVADO_BIN:-}"
PART_NAME="${XCV80_PART:-xcv80-lsva4737-2MHP-e-S}"
REQUIRED_VIVADO_VERSION="${REQUIRED_VIVADO_VERSION:-2025.1}"

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

PROFILE="${1:-balanced}"
IFACE="${2:-raw}"
CLOCK_PERIOD_NS="${3:-10.000}"
SYNTH_STAGE="${6:-ooc}"

if [[ "${SYNTH_STAGE}" == "oo" ]]; then
  SYNTH_STAGE="ooc"
fi

case "${SYNTH_STAGE}" in
  synth|ooc) ;;
  *)
    echo "ERROR: synth_stage must be synth, ooc, or oo" >&2
    exit 1
    ;;
esac

DEFAULT_PROJECT_NAME="zen_accel_xcv80_${PROFILE}_${IFACE}_200m_swift256"
if [[ "${SYNTH_STAGE}" == "ooc" ]]; then
  DEFAULT_PROJECT_NAME+="_ooc"
fi

PROJECT_NAME="${4:-${DEFAULT_PROJECT_NAME}}"
PROJECT_DIR="${5:-${ROOT_DIR}/vivado_projects/${PROJECT_NAME}}"

case "${PROFILE}" in
  safe|balanced|timing|aggr) ;;
  *)
    echo "ERROR: profile must be one of safe|balanced|timing|aggr" >&2
    exit 1
    ;;
esac

case "${IFACE}" in
  raw|axil) ;;
  *)
    echo "ERROR: iface must be raw or axil" >&2
    exit 1
    ;;
esac

if [[ -n "${VIVADO_SETTINGS:-}" ]]; then
  # shellcheck disable=SC1090
  source "${VIVADO_SETTINGS}"
fi

VIVADO_BIN="$(pick_vivado_bin "${REQUIRED_VIVADO_VERSION}")" || {
  echo "ERROR: unable to locate Vivado ${REQUIRED_VIVADO_VERSION} for xcv80 project generation." >&2
  echo "ERROR: set VIVADO_BIN or source the correct Vivado 2025.1 environment first." >&2
  exit 127
}

mkdir -p "$(dirname "${PROJECT_DIR}")"

"${VIVADO_BIN}" -mode batch -source "${TCL_SCRIPT}" \
  -tclargs "${PROJECT_DIR}" "${PROJECT_NAME}" "${PART_NAME}" "${PROFILE}" "${IFACE}" "${CLOCK_PERIOD_NS}" "${SYNTH_STAGE}"

echo "Vivado project created at:"
echo "  ${PROJECT_DIR}/${PROJECT_NAME}.xpr"
