#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
make -C Reference_Implementation_KEM clean >/dev/null || true
make -C AVX_Implementation_KEM clean >/dev/null || true
rm -rf build build-* ./*.o ./*.a ./*.so
find Reference_Implementation_KEM AVX_Implementation_KEM -type f \( -name '*.o' -o -name '*.a' -o -name '*.so' -o -name 'PQCkemKAT*' -o -name 'KAT_KEM*' -o -name 'bench*.txt' \) -delete
