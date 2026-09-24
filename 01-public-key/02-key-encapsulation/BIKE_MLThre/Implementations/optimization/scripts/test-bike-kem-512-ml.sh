#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-/home/lyb/BIKE/bikekem_v2}"
KEM_DIR="${KEM_DIR:-$ROOT_DIR/bike_kem_ml}"
MODEL="${MODEL:-$ROOT_DIR/model/bike512_l7_ref_dynamic_mlp_1000.json}"
RESULTS_DIR="${RESULTS_DIR:-$KEM_DIR/security512_ml_results}"

TESTS="${TESTS:-100}"
MAX_IT="${MAX_IT:-5}"
JOBS="${JOBS:-2}"
DELTA_OVERRIDE="${DELTA_OVERRIDE:-3}"
RUN_BASE="${RUN_BASE:-1}"
RUN_ML="${RUN_ML:-1}"

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

if [[ ! -f "$MODEL" ]]; then
  echo "missing model: $MODEL" >&2
  exit 1
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

echo "[1/4] Exporting 512-bit fixed-point MLP model"
python3 "$ROOT_DIR/model/export_mlp_to_fixed_c.py" \
  --model "$MODEL" \
  --out-dir "$KEM_DIR/src/decode"

run_build() {
  local name="$1"
  local ml_enabled="$2"
  local delta_enabled="$3"
  local build_dir="$RESULTS_DIR/build_${name}"
  local output_file="$RESULTS_DIR/${name}.out"

  echo "[build:$name] 512-bit ml_enabled=$ml_enabled delta_enabled=$delta_enabled"
  rm -rf "$build_dir"
  "${CMAKE_ENV[@]}" "$CMAKE_BIN" \
    -S "$KEM_DIR" \
    -B "$build_dir" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DSECURITY_BITS=512 \
    -DNUM_OF_TESTS="$TESTS" \
    -DBIKE_MAX_IT_OVERRIDE="$MAX_IT" \
    -DBIKE_L7_REFERENCE_DECODER=1 \
    -DBIKE_L7_DYNAMIC_THRESHOLD=1 \
    -DBIKE_MLTHRE_ENABLED="$ml_enabled" \
    -DBIKE_MLTHRE_DELTA_ENABLED="$delta_enabled" \
    -DBIKE_MLTHRE_SAMPLING=0 \
    -DDELTA="$DELTA_OVERRIDE"

  "${CMAKE_ENV[@]}" "$CMAKE_BIN" --build "$build_dir" -j "$JOBS"

  echo "[run:$name] $TESTS KEM tests"
  "$build_dir/bike-test" | tee "$output_file"

  local successes failures
  successes="$(grep -c "Success!" "$output_file" || true)"
  failures="$(grep -c "Failure!\\|Decoding failed" "$output_file" || true)"
  printf '%s,512,150001,273,524,%s,%s,%s,%s,%s\n' \
    "$name" "$DELTA_OVERRIDE" "$MAX_IT" "$TESTS" "$successes" "$failures" \
    >> "$RESULTS_DIR/summary.csv"
}

echo "variant,security_bits,r,d,t,delta,max_it,tests,successes,failures" > "$RESULTS_DIR/summary.csv"

if [[ "$RUN_BASE" != "0" ]]; then
  echo "[2/4] Running 512-bit base dynamic decoder"
  run_build "base_dynamic" 0 0
else
  echo "[2/4] Skipping base dynamic decoder"
fi

if [[ "$RUN_ML" != "0" ]]; then
  echo "[3/4] Running 512-bit MLP delta decoder"
  run_build "ml_delta" 1 1
else
  echo "[3/4] Skipping MLP delta decoder"
fi

echo "[4/4] Summary"
cat "$RESULTS_DIR/summary.csv"
echo "outputs: $RESULTS_DIR"
echo "model backup: $backup_dir"
