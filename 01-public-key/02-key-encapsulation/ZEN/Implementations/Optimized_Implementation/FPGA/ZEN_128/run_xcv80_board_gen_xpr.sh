#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROFILE="${1:-balanced}"
IFACE="${2:-raw}"
CLOCK_PERIOD_NS="${3:-10.000}"
SYNTH_STAGE="${6:-ooc}"

if [[ "${SYNTH_STAGE}" == "oo" ]]; then
  SYNTH_STAGE="ooc"
fi

DEFAULT_PROJECT_NAME="zen_accel_xcv80_balanced_raw_200m_swift128_ooc"
PROJECT_NAME="${4:-${DEFAULT_PROJECT_NAME}}"
PROJECT_DIR="${5:-${SCRIPT_DIR}/vivado_projects/${PROJECT_NAME}}"

if [[ -e "${PROJECT_DIR}" ]]; then
  rm -rf "${PROJECT_DIR}"
fi

exec bash "${SCRIPT_DIR}/scripts/create_xcv80_vivado_project.sh" \
  "${PROFILE}" "${IFACE}" "${CLOCK_PERIOD_NS}" "${PROJECT_NAME}" "${PROJECT_DIR}" "${SYNTH_STAGE}"
