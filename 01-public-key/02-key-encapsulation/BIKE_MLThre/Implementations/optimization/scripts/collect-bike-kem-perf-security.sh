#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-/home/lyb/BIKE/bikekem_v2}"
KEM_DIR="${KEM_DIR:-$ROOT_DIR/bike_kem_ml}"
RESULTS_DIR="${RESULTS_DIR:-$KEM_DIR/perf_security}"

SECURITY_LEVELS="${SECURITY_LEVELS:-128 256 512}"
VARIANTS="${VARIANTS:-baseline ml}"
TESTS="${TESTS:-1}"
REPEAT_COUNT="${REPEAT_COUNT:-100}"
OUTER_REPEAT_COUNT="${OUTER_REPEAT_COUNT:-10}"
MAX_IT="${MAX_IT:-5}"
DELTA_OVERRIDE="${DELTA_OVERRIDE:-3}"
JOBS="${JOBS:-2}"

MODEL_128="${MODEL_128:-$ROOT_DIR/model/aws_l1_mlthre_mlp_1000.json}"
MODEL_256="${MODEL_256:-$ROOT_DIR/model/aws_l5_mlthre_mlp_1000.json}"
MODEL_512="${MODEL_512:-$ROOT_DIR/model/bike512_l7_ref_dynamic_mlp_1000.json}"

CMAKE_BIN="${CMAKE_BIN:-$ROOT_DIR/.local/local/bin/cmake}"
CMAKE_PYTHONPATH="${CMAKE_PYTHONPATH:-$ROOT_DIR/.local/local/lib/python3.12/dist-packages}"
if [[ ! -x "$CMAKE_BIN" && -x /home/lyb/BIKE/.local/local/bin/cmake ]]; then
  CMAKE_BIN="/home/lyb/BIKE/.local/local/bin/cmake"
  CMAKE_PYTHONPATH="/home/lyb/BIKE/.local/local/lib/python3.12/dist-packages"
elif [[ ! -x "$CMAKE_BIN" ]]; then
  if ! command -v cmake >/dev/null 2>&1; then
    echo "missing cmake; set CMAKE_BIN=/path/to/cmake" >&2
    exit 1
  fi
  CMAKE_BIN="$(command -v cmake)"
  CMAKE_PYTHONPATH=""
fi

CMAKE_ENV=()
if [[ -n "$CMAKE_PYTHONPATH" && -d "$CMAKE_PYTHONPATH" ]]; then
  CMAKE_ENV=(env "PYTHONPATH=$CMAKE_PYTHONPATH")
fi

mkdir -p "$RESULTS_DIR/backups"

MODEL_C="$KEM_DIR/src/decode/mlthre_model.c"
MODEL_H="$KEM_DIR/src/decode/mlthre_model.h"
stamp="$(date +%Y%m%d-%H%M%S)"
backup_dir="$RESULTS_DIR/backups/$stamp"
mkdir -p "$backup_dir"
cp "$MODEL_C" "$backup_dir/mlthre_model.c"
cp "$MODEL_H" "$backup_dir/mlthre_model.h"

restore_model() {
  cp "$backup_dir/mlthre_model.c" "$MODEL_C"
  cp "$backup_dir/mlthre_model.h" "$MODEL_H"
}
trap restore_model EXIT

model_for_security() {
  case "$1" in
    128) printf '%s\n' "$MODEL_128" ;;
    256) printf '%s\n' "$MODEL_256" ;;
    512) printf '%s\n' "$MODEL_512" ;;
    *) echo "unsupported SECURITY_BITS=$1; use 128, 256, or 512" >&2; return 1 ;;
  esac
}

params_for_security() {
  case "$1" in
    128) printf '12323,71,134\n' ;;
    256) printf '40973,137,264\n' ;;
    512) printf '150001,273,524\n' ;;
  esac
}

parse_cycles() {
  local out_file="$1"
  python3 - "$out_file" <<'PY'
import re
import sys
from pathlib import Path

values = {"keypair": [], "encaps": [], "decaps": []}
successes = 0
failures = 0
for line in Path(sys.argv[1]).read_text(errors="replace").splitlines():
    m = re.search(r"\b(keypair|encaps|decaps) took ([0-9.]+) cycles", line)
    if m:
        values[m.group(1)].append(float(m.group(2)))
    if "Success!" in line:
        successes += 1
    if "Failure!" in line or "Decoding failed" in line:
        failures += 1

def avg(name):
    xs = values[name]
    return "" if not xs else f"{sum(xs) / len(xs):.2f}"

print(",".join([avg("keypair"), avg("encaps"), avg("decaps"), str(successes), str(failures)]))
PY
}

run_one() {
  local security="$1"
  local variant="$2"
  local ml_enabled=0
  local delta_enabled=0

  if [[ "$variant" == "ml" ]]; then
    ml_enabled=1
    delta_enabled=1
    local model
    model="$(model_for_security "$security")"
    if [[ ! -f "$model" ]]; then
      echo "missing model for SECURITY_BITS=$security: $model" >&2
      return 1
    fi
    python3 "$ROOT_DIR/model/export_mlp_to_fixed_c.py" \
      --model "$model" \
      --out-dir "$KEM_DIR/src/decode" >/dev/null
  fi

  local build_dir="$RESULTS_DIR/build_s${security}_${variant}"
  local out_file="$RESULTS_DIR/security${security}_${variant}.out"
  rm -rf "$build_dir"

  echo "[build] SECURITY_BITS=$security variant=$variant"
  configure_args=(
    -S "$KEM_DIR"
    -B "$build_dir"
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5
    -DSECURITY_BITS="$security"
    -DNUM_OF_TESTS="$TESTS"
    -DRDTSC=1
    "-DCMAKE_C_FLAGS=-DREPEAT=$REPEAT_COUNT -DOUTER_REPEAT=$OUTER_REPEAT_COUNT"
    -DBIKE_MAX_IT_OVERRIDE="$MAX_IT"
    -DBIKE_MLTHRE_ENABLED="$ml_enabled"
    -DBIKE_MLTHRE_DELTA_ENABLED="$delta_enabled"
    -DBIKE_MLTHRE_SAMPLING=0
  )
  if [[ "$security" == "512" ]]; then
    configure_args+=(
      -DBIKE_L7_REFERENCE_DECODER=1
      -DBIKE_L7_DYNAMIC_THRESHOLD=1
      -DDELTA="$DELTA_OVERRIDE"
    )
  fi

  "${CMAKE_ENV[@]}" "$CMAKE_BIN" "${configure_args[@]}" >/dev/null
  "${CMAKE_ENV[@]}" "$CMAKE_BIN" --build "$build_dir" -j "$JOBS" >/dev/null

  echo "[run] SECURITY_BITS=$security variant=$variant"
  "$build_dir/bike-test" | tee "$out_file"

  local keypair_cycles encaps_cycles decaps_cycles successes failures r d t
  IFS=',' read -r keypair_cycles encaps_cycles decaps_cycles successes failures < <(parse_cycles "$out_file")
  IFS=',' read -r r d t < <(params_for_security "$security")
  printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$security" "$variant" "$r" "$d" "$t" "$TESTS" "$REPEAT_COUNT" "$OUTER_REPEAT_COUNT" "$MAX_IT" \
    "$keypair_cycles" "$encaps_cycles" "$decaps_cycles" "$successes" "$failures" \
    >> "$RESULTS_DIR/perf_summary.csv"
}

echo "security_bits,variant,r,d,t,tests,repeat,outer_repeat,max_it,keypair_cycles,encaps_cycles,decaps_cycles,successes,failures" \
  > "$RESULTS_DIR/perf_summary.csv"

for security in $SECURITY_LEVELS; do
  for variant in $VARIANTS; do
    run_one "$security" "$variant"
  done
done

echo "summary: $RESULTS_DIR/perf_summary.csv"
cat "$RESULTS_DIR/perf_summary.csv"
echo "outputs: $RESULTS_DIR"
echo "model backup: $backup_dir"
