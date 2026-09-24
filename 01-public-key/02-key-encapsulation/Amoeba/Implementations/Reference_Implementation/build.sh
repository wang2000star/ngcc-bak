#!/bin/bash

set -e

dim_list=(576 864 1152 1728 2304)

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
if [[ -z "${SCRIPT_DIR}" ]]; then
    exit 1
fi
if [[ "${SCRIPT_DIR}" == "/" ]]; then
    exit 1
fi

build_all() {
    for dim in "${dim_list[@]}"; do
        dir="${SCRIPT_DIR}/Amoeba-${dim}"

        if [ -d "$dir" ]; then
            echo "Enter $dir directory"
            cd "$dir"

            bash ./build.sh

            cd ..
            echo "Exit $dir directory"
        fi
    done
}

clean_all() {
    for dim in "${dim_list[@]}"; do
        dir="${SCRIPT_DIR}/Amoeba-${dim}"

        if [ -d "$dir" ]; then
            echo "Enter $dir directory"
            cd "$dir"

            rm -rf ./bin/ ./libs/ ./build/ ./output/ ./prof/

            cd ..
            echo "Exit $dir directory"
        fi
    done
}

case "$1" in
    clean)
        clean_all
        ;;
    "")
        build_all
        ;;
    *)
        echo "Usage:"
        echo "  $0        :  build all"
        echo "  $0 clean  :  cleanup product"
        exit 1
        ;;
esac
