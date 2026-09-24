#!/usr/bin/env bash

set -euo pipefail

original_args=("$@")
iterations=100
if [[ "$#" -gt 0 && "$1" =~ ^[1-9][0-9]*$ ]]; then
  iterations="$1"
  shift
fi
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
results_file="${script_dir}/benchmark_results.csv"
log_file="${script_dir}/benchmark_run.log.txt"

if [[ "${BENCH_SIG_LOG_ACTIVE:-0}" != "1" ]]; then
  BENCH_SIG_LOG_ACTIVE=1 exec "$0" "${original_args[@]}" > >(tee "${log_file}") 2>&1
fi

bench_cflags=(
  -O3
  -march=x86-64
  -mavx2
  -maes
  -mpclmul
  -mtune=native
  -flto
  -fomit-frame-pointer
  -std=c11
  -Wpedantic
  -Wall
  -Wextra
)

bench_ldflags=(
  -O3
  -march=x86-64
  -mavx2
  -maes
  -mpclmul
  -mtune=native
  -flto
  -fomit-frame-pointer
  -lcrypto
)

if [[ "$#" -gt 0 ]]; then
  instances=("$@")
else
  mapfile -t instances < <(find "${script_dir}" -maxdepth 1 -type d -name 'GreatWall*' -printf '%f\n' | sort)
fi

if [[ "${#instances[@]}" -eq 0 ]]; then
  echo "ERROR: no instances specified or found under ${script_dir}" >&2
  exit 1
fi

cat > "${results_file}" <<'CSV'
algorithm,iterations,message_bytes,pk_bytes,sk_bytes,sig_bytes,keygen_avg_ms,sign_avg_ms,verify_avg_ms,keygen_avg_cycles,sign_avg_cycles,verify_avg_cycles,keygen_ops_s,sign_ops_s,verify_ops_s
CSV

for instance in "${instances[@]}"; do
  instance_dir="${script_dir}/${instance}"
  if [[ ! -d "${instance_dir}" ]]; then
    echo "ERROR: missing instance directory: ${instance_dir}" >&2
    exit 1
  fi

  mapfile -t objects < <(find "${instance_dir}" -maxdepth 1 -type f -name '*.o' \
    ! -name 'KAT_SIG.o' \
    ! -name 'bench_sig.o' \
    ! -name 'api_test.o' \
    ! -name 'PQCgenKAT_sign.o' \
    ! -name 'rng.o' \
    ! -name 'randomness_os.o' \
    | sort)

  if [[ "${#objects[@]}" -eq 0 ]]; then
    echo "ERROR: no object files found for ${instance}." >&2
    echo "Run make_all_instances.sh ${instance} first." >&2
    exit 1
  fi

  rm -f "${instance_dir}/bench_sig" "${instance_dir}/bench_sig.o"

  echo "==> ${instance}: build bench_sig"
  cc "${bench_cflags[@]}" -I"${instance_dir}" -c -o "${instance_dir}/bench_sig.o" "${script_dir}/bench_sig.c"

  cc -o "${instance_dir}/bench_sig" "${instance_dir}/bench_sig.o" "${objects[@]}" "${bench_ldflags[@]}"

  echo "==> ${instance}: ./bench_sig ${iterations}"
  (cd "${instance_dir}" && ./bench_sig "${iterations}") | tee -a "${results_file}"
done

echo "Benchmark results written to ${results_file}"
echo "Full benchmark log written to ${log_file}"
