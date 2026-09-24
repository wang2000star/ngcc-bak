#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "$0")/.." && pwd)"
out_dir="${OUT_DIR:-$root_dir/Benchmark_Results}"
loops="${TEST_LOOP_COUNT:-${LOOPS:-10000}}"
cc="${CC:-gcc}"
tmp_dir="${TMPDIR:-/tmp}/ntre_poly_microbench_$$"

bench_src="$root_dir/Benchmark_Results/ntre_poly_microbench.c"
csv="$out_dir/ntre_poly_microbench.csv"
log="$out_dir/ntre_poly_microbench.log"
flags="-O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra -Wno-unused-parameter -Wno-unused-result"

mkdir -p "$out_dir" "$tmp_dir"
trap 'rm -rf "$tmp_dir"' EXIT

printf 'implementation,instance,function,loops,countergap,cycles,sink,cc,cflags\n' > "$csv"
{
    printf 'root=%s\n' "$root_dir"
    printf 'loops=%s\n' "$loops"
    printf 'cc=%s\n' "$cc"
    printf 'flags=%s\n' "$flags"
    "$cc" --version | sed -n '1p'
} > "$log"

quote_csv()
{
    printf '"%s"' "${1//\"/\"\"}"
}

run_one()
{
    local instance="$1"
    local dir="$root_dir/Implementations/Optimized_Implementation/NTRE-$instance"
    local exe="$tmp_dir/ntre_poly_microbench_$instance"
    local sources

    sources=(
        "$bench_src"
        "$dir/src/poly.c"
        "$dir/src/ntt.c"
        "$dir/src/symmetric.c"
    )

    shopt -s nullglob
    local asm_sources=("$dir"/asm/*.s "$dir"/asm/*.S)
    shopt -u nullglob
    sources+=("${asm_sources[@]}")

    {
        printf '\n[Optimized/NTRE-%s]\n' "$instance"
        printf 'dir=%s\n' "$dir"
    } >> "$log"

    # Deliberate word splitting for the flags string.
    # shellcheck disable=SC2086
    "$cc" $flags -DPOLY_BENCH_DEFAULT_LOOP_COUNT="$loops" \
        -I "$dir" -I "$dir/src" \
        "${sources[@]}" -o "$exe" >> "$log" 2>&1

    TEST_LOOP_COUNT="$loops" "$exe" >> "$tmp_dir/raw_$instance.csv"
    cat "$tmp_dir/raw_$instance.csv" >> "$log"
    tail -n +2 "$tmp_dir/raw_$instance.csv" | while IFS=, read -r alg function run_loops countergap cycles sink; do
        printf 'Optimized,%s,%s,%s,%s,%s,%s,' "$alg" "$function" "$run_loops" "$countergap" "$cycles" "$sink" >> "$csv"
        quote_csv "$cc" >> "$csv"
        printf ',' >> "$csv"
        quote_csv "$flags" >> "$csv"
        printf '\n' >> "$csv"
    done
}

run_one 128
run_one 256
run_one 512

printf 'wrote %s\n' "$csv"
printf 'wrote %s\n' "$log"
