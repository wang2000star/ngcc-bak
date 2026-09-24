#!/usr/bin/env bash

set -euo pipefail

original_args=("$@")
iterations=100
if [[ "$#" -gt 0 && "$1" =~ ^[1-9][0-9]*$ ]]; then
  iterations="$1"
  shift
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
results_file="${script_dir}/memory_results.csv"
log_file="${script_dir}/memory_run.log.txt"

if [[ "${MEMORY_SIG_LOG_ACTIVE:-0}" != "1" ]]; then
  MEMORY_SIG_LOG_ACTIVE=1 exec "$0" "${original_args[@]}" > >(tee "${log_file}") 2>&1
fi

if [[ "$#" -gt 0 ]]; then
  instances=("$@")
else
  mapfile -t instances < <(find "${script_dir}" -maxdepth 1 -type d -name 'GreatWall*' -printf '%f\n' | sort)
fi

if [[ "${#instances[@]}" -eq 0 ]]; then
  echo "ERROR: no instances specified or found under ${script_dir}" >&2
  exit 1
fi

if ! command -v size >/dev/null 2>&1; then
  echo "ERROR: size command not found." >&2
  exit 1
fi

if ! command -v /usr/bin/time >/dev/null 2>&1; then
  echo "ERROR: /usr/bin/time command not found." >&2
  exit 1
fi

cat > "${results_file}" <<'CSV'
algorithm,iterations,text_bytes,data_bytes,bss_bytes,static_total_bytes,max_rss_bytes
CSV

for instance in "${instances[@]}"; do
  instance_dir="${script_dir}/${instance}"
  bench_bin="${instance_dir}/bench_sig"

  if [[ ! -d "${instance_dir}" ]]; then
    echo "ERROR: missing instance directory: ${instance_dir}" >&2
    exit 1
  fi

  if [[ ! -f "${bench_bin}" ]]; then
    echo "ERROR: missing executable: ${bench_bin}" >&2
    echo "Run run_all_bench_sig.sh ${iterations} ${instance} first." >&2
    exit 1
  fi

  echo "==> ${instance}: size bench_sig"
  read -r text_bytes data_bytes bss_bytes static_total_bytes < <(
    size "${bench_bin}" | awk 'NR == 2 { print $1, $2, $3, $4 }'
  )

  if [[ -z "${text_bytes:-}" || -z "${data_bytes:-}" || -z "${bss_bytes:-}" || -z "${static_total_bytes:-}" ]]; then
    echo "ERROR: failed to parse size output for ${bench_bin}" >&2
    exit 1
  fi

  echo "==> ${instance}: /usr/bin/time -v ./bench_sig ${iterations}"
  time_log="$(mktemp)"
  (
    cd "${instance_dir}"
    /usr/bin/time -v ./bench_sig "${iterations}"
  ) 2> "${time_log}"
  cat "${time_log}"

  max_rss_kbytes="$(
    awk -F: '/Maximum resident set size/ {
      gsub(/^[ \t]+/, "", $2);
      print $2;
    }' "${time_log}"
  )"
  rm -f "${time_log}"

  if [[ -z "${max_rss_kbytes}" ]]; then
    echo "ERROR: failed to parse max RSS for ${instance}" >&2
    exit 1
  fi

  max_rss_bytes=$((max_rss_kbytes * 1024))
  echo "${instance},${iterations},${text_bytes},${data_bytes},${bss_bytes},${static_total_bytes},${max_rss_bytes}" | tee -a "${results_file}"
done

echo "Memory results written to ${results_file}"
echo "Full memory log written to ${log_file}"
