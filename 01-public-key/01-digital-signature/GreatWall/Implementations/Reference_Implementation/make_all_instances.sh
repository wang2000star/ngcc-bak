#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ "$#" -gt 0 ]]; then
  instances=("$@")
else
  mapfile -t instances < <(find "${script_dir}" -maxdepth 1 -type d -name 'GreatWall*' -printf '%f\n' | sort)
fi

if [[ "${#instances[@]}" -eq 0 ]]; then
  echo "ERROR: no instances specified or found." >&2
  exit 1
fi

for instance in "${instances[@]}"; do
  instance_dir="${script_dir}/${instance}"
  if [[ ! -d "${instance_dir}" ]]; then
    echo "ERROR: missing instance directory: ${instance_dir}" >&2
    exit 1
  fi

  echo "==> ${instance}: make"
  make -C "${instance_dir}"
done

echo "All instances built."
