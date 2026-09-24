#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT_DIR="${ROOT_DIR}/Test_Vectors"
JOBS=${EIJEN_BUILD_JOBS:-1}

mkdir -p "${OUT_DIR}"

for dir in "${ROOT_DIR}/Implementations/Reference_Implementation"/Eijen-*; do
    [ -d "${dir}" ] || continue
    cmake -S "${dir}" -B "${dir}/build" -DCMAKE_BUILD_TYPE=Release
    cmake --build "${dir}/build" -j "${JOBS}"
    (cd "${dir}/build" && ./kat)
    cp "${dir}/build/output"/KAT_*_Eijen-*.txt "${OUT_DIR}/"
done

printf 'test vectors written to %s\n' "${OUT_DIR}"
