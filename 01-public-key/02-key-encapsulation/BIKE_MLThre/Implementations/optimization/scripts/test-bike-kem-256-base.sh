#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SECURITY_BITS=256

exec "$SCRIPT_DIR/test-bike-kem-security-base.sh" "$@"
