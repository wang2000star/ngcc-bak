#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-/home/lyb/BIKE/bikekem_v2}"
KEM_DIR="${KEM_DIR:-$ROOT_DIR/bike_kem_ml}"
SECURITY_BITS="${SECURITY_BITS:-512}"
RESULTS_DIR="${RESULTS_DIR:-$KEM_DIR/security${SECURITY_BITS}_base_results}"

TESTS="${TESTS:-10}"
MAX_IT="${MAX_IT:-5}"
JOBS="${JOBS:-2}"
DELTA_OVERRIDE="${DELTA_OVERRIDE:-3}"

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

case "$SECURITY_BITS" in
  128) PARAM_R=12323; PARAM_D=71; PARAM_T=134 ;;
  192) PARAM_R=24659; PARAM_D=103; PARAM_T=199; echo "SECURITY_BITS=192 is compatibility-only; use 128, 256, or 512 for main tests." >&2 ;;
  256) PARAM_R=40973; PARAM_D=137; PARAM_T=264 ;;
  512) PARAM_R=150001; PARAM_D=273; PARAM_T=524 ;;
  *) echo "unsupported SECURITY_BITS=$SECURITY_BITS; use 128, 256, or 512" >&2; exit 1 ;;
esac

mkdir -p "$RESULTS_DIR"

echo "[1/4] Using built-in ${SECURITY_BITS}-bit parameters: R=$PARAM_R D=$PARAM_D T=$PARAM_T"

build_dir="$RESULTS_DIR/build_base"
output_file="$RESULTS_DIR/base.out"
rm -rf "$build_dir"

echo "[2/4] Configure ${SECURITY_BITS}-bit base build"
configure_args=(
  -S "$KEM_DIR"
  -B "$build_dir"
  -DCMAKE_BUILD_TYPE=Release
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5
  -DSECURITY_BITS="$SECURITY_BITS"
  -DNUM_OF_TESTS="$TESTS"
  -DBIKE_MAX_IT_OVERRIDE="$MAX_IT"
  -DBIKE_MLTHRE_ENABLED=0
  -DBIKE_MLTHRE_DELTA_ENABLED=0
  -DBIKE_MLTHRE_SAMPLING=0
)

if [[ "$SECURITY_BITS" == "512" ]]; then
  configure_args+=(
    -DBIKE_L7_REFERENCE_DECODER=1
    -DBIKE_L7_DYNAMIC_THRESHOLD=1
    -DBIKE_L7_EMPIRICAL_THRESHOLD=0
    -DDELTA="$DELTA_OVERRIDE"
  )
fi

"${CMAKE_ENV[@]}" "$CMAKE_BIN" "${configure_args[@]}"

echo "[3/4] Build"
"${CMAKE_ENV[@]}" "$CMAKE_BIN" --build "$build_dir" -j "$JOBS"

echo "[4/4] Run $TESTS base KEM tests"
"$build_dir/bike-test" | tee "$output_file"

successes="$(grep -c "Success!" "$output_file" || true)"
failures="$(grep -c "Failure!\\|Decoding failed" "$output_file" || true)"
{
  echo "variant,security_bits,r,d,t,max_it,tests,successes,failures"
  printf 'base,%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$SECURITY_BITS" "$PARAM_R" "$PARAM_D" "$PARAM_T" "$MAX_IT" "$TESTS" "$successes" "$failures"
} > "$RESULTS_DIR/summary.csv"

cat "$RESULTS_DIR/summary.csv"
echo "outputs: $RESULTS_DIR"
echo "build directory keeps the compiled test binary"
