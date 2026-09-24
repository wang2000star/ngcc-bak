#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TCL_SCRIPT="${SCRIPT_DIR}/create_xcvu37p_vivado_project.tcl"
VIVADO_BIN="${VIVADO_BIN:-vivado}"
PART_NAME="${XCVU37P_PART:-xcvu37p-fsvh2892-2-e}"

PROFILE="${1:-balanced}"
IFACE="${2:-raw}"
CLOCK_PERIOD_NS="${3:-5.000}"
PROJECT_NAME="${4:-zen_accel_xcvu37p_${PROFILE}_${IFACE}_200m_swift256}"
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

if ! command -v "${VIVADO_BIN}" >/dev/null 2>&1; then
  echo "ERROR: '${VIVADO_BIN}' not found in PATH. Please source Vivado settings first." >&2
  exit 127
fi

mkdir -p "$(dirname "${PROJECT_DIR}")"

"${VIVADO_BIN}" -mode batch -source "${TCL_SCRIPT}" \
  -tclargs "${PROJECT_DIR}" "${PROJECT_NAME}" "${PART_NAME}" "${PROFILE}" "${IFACE}" "${CLOCK_PERIOD_NS}"

echo "Vivado project created at:"
echo "  ${PROJECT_DIR}/${PROJECT_NAME}.xpr"
