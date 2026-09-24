#!/usr/bin/env sh
set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
JOBS=${EIJEN_BUILD_JOBS:-1}

for impl in Reference_Implementation Optimized_Implementation; do
    for dir in "${ROOT_DIR}/Implementations/${impl}"/Eijen-*; do
        [ -d "${dir}" ] || continue
        cmake -S "${dir}" -B "${dir}/build" -DCMAKE_BUILD_TYPE=Release
        cmake --build "${dir}/build" -j "${JOBS}"
    done
done

printf 'all Eijen CryptHash API packages built\n'
