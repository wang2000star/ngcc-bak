#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
BUILD_DIR="${ROOT_DIR}/build"
RESULTS_DIR="${ROOT_DIR}/self_assessment/results"
CPU_ID="${EIJEN_CPU_ID:-0}"

mkdir -p "${RESULTS_DIR}"

cmake -S "${ROOT_DIR}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=Release
cmake --build "${BUILD_DIR}" -j "${EIJEN_BUILD_JOBS:-1}"

ctest --test-dir "${BUILD_DIR}" --output-on-failure | tee "${RESULTS_DIR}/kat.log"

run_single_core() {
    if command -v taskset >/dev/null 2>&1; then
        taskset -c "${CPU_ID}" "$@"
    else
        "$@"
    fi
}

run_single_core "${BUILD_DIR}/bench" > "${RESULTS_DIR}/bench.csv"

{
    date -u +"generated_utc=%Y-%m-%dT%H:%M:%SZ"
    uname -a
    command -v gcc >/dev/null 2>&1 && gcc --version | head -n 1
    command -v cmake >/dev/null 2>&1 && cmake --version | head -n 1
    command -v lscpu >/dev/null 2>&1 && lscpu
} > "${RESULTS_DIR}/environment.txt"

{
    if command -v size >/dev/null 2>&1; then
        echo "## kat"
        size "${BUILD_DIR}/kat"
        echo "## bench"
        size "${BUILD_DIR}/bench"
    fi
} > "${RESULTS_DIR}/static_size.txt"

if [ -x /usr/bin/time ]; then
    if command -v taskset >/dev/null 2>&1; then
        /usr/bin/time -v taskset -c "${CPU_ID}" "${BUILD_DIR}/bench" \
            > /dev/null 2> "${RESULTS_DIR}/time.txt" || true
    else
        /usr/bin/time -v "${BUILD_DIR}/bench" \
            > /dev/null 2> "${RESULTS_DIR}/time.txt" || true
    fi
fi

printf 'self-assessment outputs written to %s\n' "${RESULTS_DIR}"
