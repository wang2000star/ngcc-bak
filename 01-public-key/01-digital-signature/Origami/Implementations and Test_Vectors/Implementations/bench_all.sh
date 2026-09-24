#!/bin/sh
set -eu

BENCH_ITER=${BENCH_ITER:-3}
BENCH_MESSAGE_BYTES=${BENCH_MESSAGE_BYTES:-64}
RESULT_DIR=${RESULT_DIR:-Benchmark_Results}
OVERHEAD_DIR=${OVERHEAD_DIR:-Overhead_Results}

mkdir -p "$RESULT_DIR"
mkdir -p "$OVERHEAD_DIR"
printf "implementation,instance,operation,total_seconds,average_microseconds\n" > "$RESULT_DIR/summary.csv"
printf "implementation,instance,public_key_bytes,secret_key_bytes,signature_bytes,signature_transmission_bytes,public_key_signature_transmission_bytes,keypair_storage_bytes,public_secret_signature_storage_bytes\n" > "$OVERHEAD_DIR/summary.csv"

for impl in Reference_Implementation Optimized_Implementation; do
    for inst in Origami-128 Origami-256 Origami-384 Origami-512; do
        out="$RESULT_DIR/${impl}_${inst}.txt"
        echo "== $impl/$inst =="
        (cd "$impl/$inst" && make clean run-bench BENCH_ITER="$BENCH_ITER" BENCH_MESSAGE_BYTES="$BENCH_MESSAGE_BYTES") > "$out"
        cat "$out"
        awk -F, -v impl="$impl" -v inst="$inst" '/^(keygen|sign|verify),/ {printf "%s,%s,%s,%s,%s\n", impl, inst, $1, $2, $3}' "$out" >> "$RESULT_DIR/summary.csv"
        awk -v impl="$impl" -v inst="$inst" '
            /^Public key bytes:/ { pk = $4 }
            /^Secret key bytes:/ { sk = $4 }
            /^Signature bytes:/ { sig = $3 }
            END {
                if (pk != "" && sk != "" && sig != "") {
                    printf "%s,%s,%d,%d,%d,%d,%d,%d,%d\n",
                        impl, inst, pk, sk, sig, sig, pk + sig, pk + sk, pk + sk + sig
                }
            }
        ' "$out" >> "$OVERHEAD_DIR/summary.csv"
    done
done

echo "Benchmark summary saved to $RESULT_DIR/summary.csv"
echo "Overhead summary saved to $OVERHEAD_DIR/summary.csv"
