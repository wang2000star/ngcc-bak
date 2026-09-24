#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
REF_ROOT="$ROOT/Implementations/Reference_Implementation"
OUT_ROOT="$ROOT/Test_Vectors"

mkdir -p "$OUT_ROOT"

for instance in AFS-TrEDM-512 AFS-TrEDM-768 AFS-TrEDM-1024; do
  (
    cd "$REF_ROOT/$instance"
    make clean
    make CFLAGS="-std=c99 -O3 -Wall -Wextra -pedantic" kat
    ./kat
    cp "output/KAT_2_12_${instance}.txt" "$OUT_ROOT/KAT_2_12_${instance}.txt"
    cp "output/KAT_2_23_${instance}.txt" "$OUT_ROOT/KAT_2_23_${instance}.txt"
    cp "output/KAT_2_33_${instance}.txt" "$OUT_ROOT/KAT_2_33_${instance}.txt"
    cp "output/KAT_Loop_${instance}.txt" "$OUT_ROOT/KAT_Loop_${instance}.txt"
    make clean
  )
done

(
  cd "$ROOT"
  find Test_Vectors -maxdepth 1 -type f -name 'KAT_*.txt' -print | sort | xargs sha256sum
)
