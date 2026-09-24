#!/bin/bash

BIN_DIR="./bin"
PROF_DIR="./prof"

if ! command -v pprof &> /dev/null; then
    echo "ERROR: pprof is not installed, exit script."
    exit 1
fi
if ! command -v dot &> /dev/null; then
    echo "ERROR: graphviz (dot) is missing, cannot generate PDF files, exit script."
    exit 1
fi

for exe_path in "${BIN_DIR}"/*; do
    if [ ! -f "${exe_path}" ] || [ ! -x "${exe_path}" ]; then
        continue
    fi

    exe_name=$(basename "${exe_path}")
    echo "========================================"
    echo "Scanning executable: ${exe_name}"

    prof_files=("${PROF_DIR}/${exe_name}_"*.prof)

    if [ ! -f "${prof_files[0]}" ]; then
        echo "No matched ${exe_name}_*.prof found, skip this executable."
        continue
    fi

    for prof_file in "${prof_files[@]}"; do
        pdf_output="${prof_file%.prof}.pdf"
        txt_output="${prof_file%.prof}.txt"
        echo "Converting: ${prof_file} -> ${pdf_output} and ${txt_output}"

        pprof --pdf "${exe_path}" "${prof_file}" > "${pdf_output}"
        pprof -text "${exe_path}" "${prof_file}" > "${txt_output}"

        if [ $? -eq 0 ]; then
            echo "SUCCESS: Generated ${pdf_output} and ${txt_output}"
        else
            echo "FAILED: Cannot generate PDF for ${prof_file}"
        fi
    done
done

echo -e "\nBatch conversion task finished."