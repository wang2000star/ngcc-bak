#!/usr/bin/env sh
set -eu

cd "$(dirname "$0")/.."
CC=${CC:-gcc}
REF_CFLAGS="-std=c99 -Wpedantic -Wall -Wextra -O2"
PERF_CFLAGS="-O3 -march=x86-64 -mavx2 -mtune=native -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra"
RES_CFLAGS="-Os -march=x86-64 -mavx2 -flto -fomit-frame-pointer -std=c99 -Wpedantic -Wall -Wextra"
BUILD="build/fast"

mkdir -p "$BUILD"

test_group() {
    group_path=$1
    label=$2
    cflags=$3
    for inst in Iphe-512 Iphe-768 Iphe-1024; do
        dir="Implementations/$group_path/$inst"
        echo "Building $label $inst"
        # shellcheck disable=SC2086
        "$CC" $cflags "$dir/iphe_selftest.c" "$dir/CryptHash_AlgorithmInstance.c" -o "$BUILD/${label}_${inst}_selftest.exe"
        "$BUILD/${label}_${inst}_selftest.exe"
        # shellcheck disable=SC2086
        "$CC" $cflags -I"$dir" -include CryptHash_AlgorithmInstance.h scripts/digest_probe.c "$dir/CryptHash_AlgorithmInstance.c" -o "$BUILD/${label}_${inst}_probe.exe"
        "$BUILD/${label}_${inst}_probe.exe" > "$BUILD/${label}_${inst}.digest"
    done
}

test_group Reference_Implementation REF "$REF_CFLAGS"
test_group Optimized_Implementation/Performance_Implementation PERF "$PERF_CFLAGS"
test_group Optimized_Implementation/Resource_Implementation RESOURCE "$RES_CFLAGS"

for inst in Iphe-512 Iphe-768 Iphe-1024; do
    cmp "$BUILD/REF_${inst}.digest" "$BUILD/PERF_${inst}.digest"
    cmp "$BUILD/REF_${inst}.digest" "$BUILD/RESOURCE_${inst}.digest"
done

echo "PASS fast selftests and multi-implementation consistency check"
