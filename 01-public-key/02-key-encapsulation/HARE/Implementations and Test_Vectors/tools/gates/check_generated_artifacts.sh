#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
python3 "$ROOT/tools/generators/generate_kr_syndrome_table.py" --check
python3 "$ROOT/tools/generators/generate_rs_generator_constants.py" --check
python3 "$ROOT/tools/gates/check_parameter_manifest.py"
python3 "$ROOT/tools/generators/generate_instance_readmes.py" --check
echo "generated artifact and parameter contract checks: PASS"
