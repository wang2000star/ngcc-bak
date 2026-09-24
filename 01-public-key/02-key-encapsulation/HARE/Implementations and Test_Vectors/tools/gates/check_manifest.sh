#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
cd "$ROOT"

sha256sum -c MANIFEST.sha256
python3 tools/generators/create_manifest.py --check
awk -F '\t' 'NR > 1 {print $1 "  " $2}' MANIFEST.tsv | sha256sum -c -
echo "source manifest check: PASS (hashes and exact file set)"
