#!/usr/bin/env sh
# Build, run, sanitize, or clean every Polar-KEM implementation directory.

set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
mode=build
run_kat=0

for arg in "$@"; do
    case "$arg" in
        --clean) mode=clean ;;
        --sanitize) mode=sanitize ;;
        --run) run_kat=1 ;;
        -h|--help)
            echo "usage: $0 [--clean | --sanitize] [--run]"
            exit 0
            ;;
        *)
            echo "unknown option: $arg" >&2
            exit 2
            ;;
    esac
done

for family in Reference_Implementation Optimized_Implementation; do
    for instance in PolarKEM-128 PolarKEM-256 PolarKEM-512; do
        instance_dir="$script_dir/$family/$instance"
        echo "==> $family/$instance"
        if [ "$mode" = clean ]; then
            make -C "$instance_dir" clean
        elif [ "$mode" = sanitize ]; then
            make -C "$instance_dir" sanitizer
        else
            make -C "$instance_dir" clean all
        fi

        if [ "$run_kat" -eq 1 ] && [ "$mode" != clean ]; then
            (cd "$instance_dir" && ./KAT_KEM)
        fi
    done
done
