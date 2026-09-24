#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DENABLE_STRICT=OFF
cmake --build build --target KAT_SIG_SQIsignTriangle_lvl1 -j
