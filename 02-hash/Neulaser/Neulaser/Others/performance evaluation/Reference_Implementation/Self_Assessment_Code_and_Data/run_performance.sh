#!/usr/bin/env bash
set -eu

cd "$(dirname "$0")"

if command -v mingw32-make >/dev/null 2>&1; then
    MAKE_CMD=mingw32-make
else
    MAKE_CMD=make
fi

"$MAKE_CMD" clean
"$MAKE_CMD" bench | tee performance_results_raw.txt
