#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 4 ]]; then
  echo "usage: $0 <impl_dir> <variant> <instance> <submission_name>" >&2
  exit 1
fi

impl_dir="$(cd "$1" && pwd)"
variant="$2"
instance="$3"
submission_name="$4"
script_dir="$(cd "$(dirname "$0")" && pwd)"
root_dir="$(cd "$script_dir/../.." && pwd)"
result_root="$root_dir/Self_Evaluation/results/$variant/$instance"
result_dir="$result_root/latest"
staging_dir="$result_root/.latest.tmp.$$"

cleanup() {
  rm -rf "$staging_dir"
}

trap cleanup EXIT

mkdir -p "$result_root"
rm -rf "$staging_dir"
mkdir -p "$staging_dir"

"$script_dir/collect_env.sh" > "$staging_dir/environment.csv"

{
  printf '%s,%s\n' "metric" "value"
  printf '%s,%s\n' "variant" "$variant"
  printf '%s,%s\n' "instance" "$instance"
  printf '%s,%s\n' "impl_dir" "$impl_dir"
  printf '%s,%s\n' "submission_name" "$submission_name"
  printf '%s,%s\n' "started_at_utc" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} > "$staging_dir/metadata.csv"

make -C "$impl_dir" clean
make -C "$impl_dir" test speed mem kat

(
  cd "$impl_dir"
  ./test_OPSsig > "$staging_dir/correctness.log"
  ./test_speed_OPSsig > "$staging_dir/speed.csv"
  ./test_mem_OPSsig > "$staging_dir/memory_runtime.csv"
  ./kat_sig > "$staging_dir/kat.log"
)

"$script_dir/measure_mem.sh" "$impl_dir/test_static_mem_OPSsig" > "$staging_dir/memory_static.csv"

cp "$root_dir/Self_Evaluation/templates/report-template.md" \
   "$staging_dir/report-template.md"
cp "$root_dir/Self_Evaluation/templates/dependencies-template.md" \
   "$staging_dir/dependencies-template.md"
cp "$root_dir/Self_Evaluation/package-exclude.txt" \
   "$staging_dir/package-exclude.txt"

{
  printf '%s,%s\n' "metric" "value"
  printf '%s,%s\n' "variant" "$variant"
  printf '%s,%s\n' "instance" "$instance"
  printf '%s,%s\n' "submission_name" "$submission_name"
  printf '%s,%s\n' "result_dir" "$result_dir"
  printf '%s,%s\n' "finished_at_utc" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
} >> "$staging_dir/metadata.csv"

rm -rf "$result_dir"
mv "$staging_dir" "$result_dir"
find "$result_root" -mindepth 1 -maxdepth 1 ! -name latest -exec rm -rf {} +
printf 'Self-evaluation artifacts written to %s\n' "$result_dir"
