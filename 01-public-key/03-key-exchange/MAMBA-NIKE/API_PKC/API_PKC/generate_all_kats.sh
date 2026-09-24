#!/usr/bin/env bash
# Generate canonical MAMBA-NIKE KEX KATs from the Reference implementations.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KAT_BASE="$SCRIPT_DIR/KAT"
TEST_VECTOR_DIR="$SCRIPT_DIR/Test_Vectors"
PARSE_PY="$SCRIPT_DIR/parse_kat.py"
MANIFEST="$SCRIPT_DIR/KAT_MANIFEST.sha256"
CC="${CC:-/usr/bin/gcc}"
export PYTHONDONTWRITEBYTECODE=1
PARAMETERS_SHA256="$(shasum -a 256 "$ROOT/parameters.json" | awk '{print $1}')"

check_parameters_unchanged() {
  local current
  current="$(shasum -a 256 "$ROOT/parameters.json" | awk '{print $1}')"
  if [ "$current" != "$PARAMETERS_SHA256" ]; then
    echo "parameters.json changed during KAT generation" >&2
    echo "before: $PARAMETERS_SHA256" >&2
    echo "after:  $current" >&2
    return 1
  fi
}

cd "$ROOT"
python3 tools/profile_manifest.py
check_parameters_unchanged

mkdir -p "$KAT_BASE" "$TEST_VECTOR_DIR"
rm -f "$MANIFEST"

profile_rows() {
  PYTHONPATH="$ROOT" python3 - <<'PY'
from tools.profile_manifest import load_profiles
for p in load_profiles():
    print(f"{p.name} {p.kat_suffix} {p.pk_bytes} {p.sk_api_bytes} {p.m1_bytes} {p.ss_bytes}")
PY
}

profile_rows | while read -r NAME SUFFIX PK_BYTES SK_BYTES M1_BYTES SS_BYTES; do
  IMPL_DIR="$SCRIPT_DIR/Implementations/Reference_Implementation/$NAME"
  RAW_LOG="$IMPL_DIR/output/KAT_KEX_${NAME}.txt"
  TV_LOG="$TEST_VECTOR_DIR/KAT_KEX_${NAME}.txt"

  echo "===== $NAME ====="
  echo "  pk=$PK_BYTES sk=$SK_BYTES m1=$M1_BYTES ss=$SS_BYTES suffix=$SUFFIX"
  echo "  building Reference instance"
  make -C "$IMPL_DIR" clean >/dev/null
  make -C "$IMPL_DIR" CC="$CC"

  echo "  running KAT_KEX"
  rm -rf "$IMPL_DIR/output"
  (cd "$IMPL_DIR" && ./KAT_KEX >/dev/null)
  cp "$RAW_LOG" "$TV_LOG"

  echo "  parsing .req/.rsp"
  rm -rf "$KAT_BASE/$NAME"
  (cd "$SCRIPT_DIR" && python3 "$PARSE_PY" "$NAME" "$SUFFIX" "$TV_LOG")

  make -C "$IMPL_DIR" clean >/dev/null
done

{
  echo "# MAMBA-NIKE KEX KAT manifest"
  echo "# command: (cd API_PKC && bash generate_all_kats.sh)"
  echo "# compiler: $("$CC" --version | head -n 1)"
  find "$KAT_BASE" "$TEST_VECTOR_DIR" -type f | sort | while IFS= read -r file; do
    rel="${file#$SCRIPT_DIR/}"
    bytes="$(wc -c < "$file" | tr -d ' ')"
    sha="$(shasum -a 256 "$file" | awk '{print $1}')"
    printf "%s  %s  %s\n" "$sha" "$bytes" "$rel"
  done
} > "$MANIFEST"

check_parameters_unchanged
echo "===== KAT generation complete ====="
cat "$MANIFEST"
