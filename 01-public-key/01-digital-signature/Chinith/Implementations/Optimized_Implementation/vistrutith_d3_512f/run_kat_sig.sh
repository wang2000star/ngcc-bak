#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

case "$(uname -m)" in
  x86_64|i386|i686) default_prg_acce=1 ;;
  *) default_prg_acce=0 ;;
esac

PRG_ACCE="${PRG_ACCE:-${default_prg_acce}}"
NDEBUG="${NDEBUG:-1}"

make clean
make NDEBUG="${NDEBUG}" PRG_ACCE="${PRG_ACCE}" KAT_SIG

kat_file="output/KAT_SIG_vistrutith_d3_512f.txt"
if ! ./KAT_SIG; then
  echo "ERROR: vistrutith KAT generation failed." >&2
  rm -f "${kat_file}"
  exit 1
fi

count="$(grep -c '^Count = ' "${kat_file}" || true)"
if [[ "${count}" -ne 10 ]]; then
  echo "ERROR: incomplete vistrutith KAT output (${count}/10 counts)." >&2
  rm -f "${kat_file}"
  exit 1
fi
