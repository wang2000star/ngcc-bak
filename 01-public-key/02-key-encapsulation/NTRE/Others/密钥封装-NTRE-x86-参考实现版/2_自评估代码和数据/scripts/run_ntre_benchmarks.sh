#!/usr/bin/env bash
set -euo pipefail

phase="${1:-before}"
root_dir="$(cd "$(dirname "$0")/.." && pwd)"
out_dir="${OUT_DIR:-$root_dir/Benchmark_Results}"
loops="${TEST_LOOP_COUNT:-${LOOPS:-10000}}"
rounds="${ROUNDS:-3}"
cc="${CC:-gcc}"
tmp_dir="${TMPDIR:-/tmp}/ntre_bench_${phase}_$$"

csv="$out_dir/ntre_optimized_${phase}.csv"
log="$out_dir/ntre_optimized_${phase}.log"
bench_src="$root_dir/Baseline/bench/bench_kem.c"

common_flags="-std=c99 -Wpedantic -Wall -Wextra -Wno-unused-parameter -Wno-unused-result"
reference_doc_flags="-O2 $common_flags"
optimized_doc_flags="-O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer $common_flags"
same_flags="-O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer $common_flags"

mkdir -p "$out_dir" "$tmp_dir"
trap 'rm -rf "$tmp_dir"' EXIT

printf 'phase,mode,implementation,instance,round,pk,sk,ct,ss,loops,countergap,keygen_cycles,encaps_cycles,decaps_cycles,cc,cflags\n' > "$csv"
{
    printf 'phase=%s\n' "$phase"
    printf 'root=%s\n' "$root_dir"
    printf 'loops=%s\n' "$loops"
    printf 'rounds=%s\n' "$rounds"
    printf 'cc=%s\n' "$cc"
    "$cc" --version | sed -n '1p'
} > "$log"

quote_csv()
{
    printf '"%s"' "${1//\"/\"\"}"
}

build_and_run()
{
    local mode="$1"
    local implementation="$2"
    local instance="$3"
    local flags="$4"
    local dir="$5"
    local exe="$tmp_dir/${mode}_${implementation}_${instance}"
    local sources

    sources=(
        "$bench_src"
        "$dir/KEM_AlgorithmInstance.c"
        "$dir/src/poly.c"
        "$dir/src/ntt.c"
        "$dir/src/symmetric.c"
        "$dir/auxfunc.c"
        "$dir/drng.c"
    )

    if [[ "$implementation" == "Optimized" ]]; then
        shopt -s nullglob
        local asm_sources=("$dir"/asm/*.s "$dir"/asm/*.S)
        shopt -u nullglob
        sources+=("${asm_sources[@]}")
    fi

    {
        printf '\n[%s/%s/NTRE-%s]\n' "$mode" "$implementation" "$instance"
        printf 'dir=%s\n' "$dir"
        printf 'flags=%s\n' "$flags"
    } >> "$log"

    # Deliberate word splitting for the flags string.
    # shellcheck disable=SC2086
    "$cc" $flags -DTEST_LOOP_COUNT="$loops" \
        -I "$dir" -I "$dir/src" \
        "${sources[@]}" -o "$exe" >> "$log" 2>&1

    for round in $(seq 1 "$rounds"); do
        local raw alg pk sk ct ss run_loops countergap keygen encaps decaps
        raw="$(TEST_LOOP_COUNT="$loops" "$exe" --csv)"
        printf 'round=%s raw=%s\n' "$round" "$raw" >> "$log"
        IFS=, read -r alg pk sk ct ss run_loops countergap keygen encaps decaps <<< "$raw"
        printf '%s,%s,%s,NTRE-%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,' \
            "$phase" "$mode" "$implementation" "$instance" "$round" \
            "$pk" "$sk" "$ct" "$ss" "$run_loops" "$countergap" \
            "$keygen" "$encaps" "$decaps" >> "$csv"
        quote_csv "$cc" >> "$csv"
        printf ',' >> "$csv"
        quote_csv "$flags" >> "$csv"
        printf '\n' >> "$csv"
    done
}

for instance in 128 256 512; do
    ref_dir="$root_dir/Implementations/Reference_Implementation/NTRE-$instance"
    opt_dir="$root_dir/Implementations/Optimized_Implementation/NTRE-$instance"

    build_and_run "doc" "Reference" "$instance" "$reference_doc_flags" "$ref_dir"
    build_and_run "doc" "Optimized" "$instance" "$optimized_doc_flags" "$opt_dir"
    build_and_run "same_flags" "Reference" "$instance" "$same_flags" "$ref_dir"
    build_and_run "same_flags" "Optimized" "$instance" "$same_flags" "$opt_dir"
done

printf 'wrote %s\n' "$csv"
printf 'wrote %s\n' "$log"
